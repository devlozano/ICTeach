import {after, before, beforeEach, test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {initializeTestEnvironment, assertFails, assertSucceeds} from '@firebase/rules-unit-testing';
import {doc, collection, getDoc, getDocs, setDoc, updateDoc, deleteDoc,
  writeBatch, serverTimestamp, Timestamp} from 'firebase/firestore';

let env;
const lrn = '123456789012', id = 'a'.repeat(64);
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-icteach-enrollment',
    firestore: {host: '127.0.0.1', port: 8188,
      rules: readFileSync(new URL('./enrollment.rules', import.meta.url), 'utf8')},
  });
});
after(async () => { await env?.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async ctx => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'registration_issuers/issuer'), {enabled: true});
    await setDoc(doc(db, 'lrn_master_list', lrn), {
      firstName: 'Test', lastName: 'Student', uploadedAt: Timestamp.now(),
      isRegistered: false, invitationId: id,
    });
    await setDoc(doc(db, 'registration_bindings', id), {lrn});
    await setDoc(doc(db, 'registration_checks', id), {
      expiresAt: Timestamp.fromMillis(Date.now() + 3600000),
    });
  });
});
const user = (uid = 'student') => env.authenticatedContext(uid, {email: uid + '@example.test'}).firestore();
function profile(uid = 'student', overrides = {}) {
  return {uid, lrn, firstName: 'Test', middleName: '', lastName: 'Student',
    extension: '', displayName: 'Test Student', name: 'Test Student',
    email: uid + '@example.test', role: 'student',
    createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    registrationInvitationId: id, ...overrides};
}
function claim(db, {uid = 'student', overrides = {}, omit = ''} = {}) {
  const batch = writeBatch(db), data = profile(uid, overrides);
  if (omit !== 'users') batch.set(doc(db, 'users', uid), data);
  if (omit !== 'students') batch.set(doc(db, 'students', uid), data);
  if (omit !== 'master') batch.update(doc(db, 'lrn_master_list', lrn), {
    isRegistered: true, registeredUid: uid, registeredAt: serverTimestamp(),
  });
  if (omit !== 'check') batch.delete(doc(db, 'registration_checks', id));
  return batch.commit();
}
test('pre-account exact check reveals expiry only; master, bindings and lists stay private', async () => {
  const db = env.unauthenticatedContext().firestore();
  const check = await assertSucceeds(getDoc(doc(db, 'registration_checks', id)));
  assert.deepEqual(Object.keys(check.data()), ['expiresAt']);
  await assertFails(getDocs(collection(db, 'registration_checks')));
  await assertFails(getDoc(doc(db, 'lrn_master_list', lrn)));
  await assertFails(getDoc(doc(db, 'registration_bindings', id)));
});
test('unknown capability returns missing, no account creation or names', async () => {
  assert.equal((await getDoc(doc(env.unauthenticatedContext().firestore(),
      'registration_checks', 'b'.repeat(64)))).exists(), false);
});
test('one valid atomic claim succeeds, replay fails and check disappears', async () => {
  await assertSucceeds(claim(user()));
  await assertFails(claim(user('other'), {uid: 'other'}));
  assert.equal((await getDoc(doc(env.unauthenticatedContext().firestore(),
    'registration_checks', id))).exists(), false);
});
test('concurrent claims have exactly one winner', async () => {
  const results = await Promise.allSettled([
    claim(user('one'), {uid: 'one'}), claim(user('two'), {uid: 'two'}),
  ]);
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
});
for (const omit of ['users', 'students', 'master', 'check']) {
  test('partial claim rejected: missing ' + omit, async () => {
    await assertFails(claim(user(), {omit}));
    assert.equal((await getDoc(doc(user(), 'users/student'))).exists(), false);
  });
}
for (const overrides of [
  {role: 'admin'}, {uid: 'victim'}, {lrn: '999999999999'},
  {email: 'victim@example.test'}, {registrationInvitationId: 'b'.repeat(64)},
  {firstName: ''}, {firstName: 'x'.repeat(151)}, {middleName: 2},
  {extra: true}, {createdAt: Timestamp.fromMillis(0)},
]) {
  test('reject malformed, forged or oversized profile: ' + Object.keys(overrides)[0], async () =>
    assertFails(claim(user(), {overrides})));
}
test('expired and revoked invitations cannot be claimed', async () => {
  await env.withSecurityRulesDisabled(ctx => updateDoc(
    doc(ctx.firestore(), 'registration_checks', id), {expiresAt: Timestamp.fromMillis(0)}));
  await assertFails(claim(user()));
  await env.withSecurityRulesDisabled(ctx => deleteDoc(doc(ctx.firestore(), 'registration_checks', id)));
  await assertFails(claim(user()));
});
test('users cannot issue invitations, self-approve or change master names', async () => {
  const db = user();
  await assertFails(setDoc(doc(db, 'registration_issuers/student'), {enabled: true}));
  await assertFails(setDoc(doc(db, 'registration_checks', 'b'.repeat(64)),
    {expiresAt: Timestamp.fromMillis(Date.now() + 3600000)}));
  await assertFails(updateDoc(doc(db, 'lrn_master_list', lrn), {firstName: 'Hijack'}));
});
test('profile update rejects role, identity, timestamp, oversized and schema changes', async () => {
  const db = user();
  await assertSucceeds(claim(db));
  for (const change of [{role: 'admin'}, {uid: 'other'}, {lrn: '999999999999'},
    {firstName: 'x'.repeat(151)}, {lastName: null}, {unknown: true},
    {createdAt: Timestamp.fromMillis(0)}]) {
    await assertFails(updateDoc(doc(db, 'users/student'), {...change, updatedAt: serverTimestamp()}));
  }
  await assertSucceeds(updateDoc(doc(db, 'users/student'), {
    firstName: 'Updated', updatedAt: serverTimestamp(),
  }));
  await assertFails(getDoc(doc(user('other'), 'users/student')));
  await assertFails(updateDoc(doc(user('other'), 'users/student'), {
    firstName: 'Hijack', updatedAt: serverTimestamp(),
  }));
});
test('approved issuer can replace a code without exposing private fields', async () => {
  const db = user('issuer'), next = 'c'.repeat(64), batch = writeBatch(db);
  batch.delete(doc(db, 'registration_checks', id));
  batch.delete(doc(db, 'registration_bindings', id));
  batch.update(doc(db, 'lrn_master_list', lrn), {invitationId: next});
  batch.set(doc(db, 'registration_bindings', next), {lrn});
  batch.set(doc(db, 'registration_checks', next),
    {expiresAt: Timestamp.fromMillis(Date.now() + 7 * 86400000)});
  await assertSucceeds(batch.commit());
  await assertFails(claim(user()));
  await assertFails(updateDoc(doc(db, 'registration_checks', next), {lrn}));
});
test('a self-assigned users.role does not grant issuer authority', async () => {
  await env.withSecurityRulesDisabled(ctx => setDoc(doc(ctx.firestore(), 'users/attacker'), {role: 'admin'}));
  await assertFails(getDoc(doc(user('attacker'), 'lrn_master_list', lrn)));
});
test('issuer can create valid master data but cannot overwrite a claimed LRN', async () => {
  const db = user('issuer'), master = doc(db, 'lrn_master_list', '000000000000');
  await assertSucceeds(setDoc(master, {
    firstName: 'A'.repeat(150), lastName: 'B'.repeat(150), middleName: '',
    uploadedAt: serverTimestamp(), isRegistered: false,
  }));
  await assertFails(setDoc(doc(db, 'lrn_master_list', '999999999999'), {
    firstName: 'A', lastName: 'B', uploadedAt: serverTimestamp(), isRegistered: 'false',
  }));
  await assertSucceeds(claim(user()));
  await assertFails(setDoc(doc(db, 'lrn_master_list', lrn), {
    firstName: 'Other', lastName: 'Person', uploadedAt: serverTimestamp(), isRegistered: false,
  }));
});
test('revocation removes public verification and blocks enrollment', async () => {
  const db = user('issuer');
  await assertSucceeds(deleteDoc(doc(db, 'registration_checks', id)));
  assert.equal((await getDoc(doc(env.unauthenticatedContext().firestore(),
    'registration_checks', id))).exists(), false);
  await assertFails(claim(user()));
});
test('even issuer cannot place PII in a public check', async () => {
  const db = user('issuer'), next = 'd'.repeat(64), batch = writeBatch(db);
  batch.update(doc(db, 'lrn_master_list', lrn), {invitationId: next});
  batch.set(doc(db, 'registration_bindings', next), {lrn});
  batch.set(doc(db, 'registration_checks', next), {
    expiresAt: Timestamp.fromMillis(Date.now() + 3600000), firstName: 'Private',
  });
  await assertFails(batch.commit());
});
test('unauthenticated claim fails and missing required profile field fails', async () => {
  await assertFails(claim(env.unauthenticatedContext().firestore()));
  const db = user(), data = profile();
  delete data.lastName;
  await assertFails(setDoc(doc(db, 'users/student'), data));
});
