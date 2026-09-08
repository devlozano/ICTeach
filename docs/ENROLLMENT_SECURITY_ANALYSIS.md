# Enrollment security analysis

Status: local integration / enrollment-only rules prototype. Not production deployed.

Target: icteach-free, (default), STANDARD / FIRESTORE_NATIVE, Spark (verified September 8, 2026).

## Existing access inventory

Scanned Dart collection/query call sites across lib (436 matching lines).
Registration formerly read lrn_master_list/{lrn} before Auth, then created Auth
and wrote users/{uid}, students/{uid}, and the LRN claim sequentially.
CSV upload reads master records in transactions and creates missing records;
ManageLRNPage lists master records ordered by uploadedAt.
Staff creation writes users; class roster queries entire users and students.
These contain names/emails. Strict owner-only profile rules cannot replace
the deployed blanket rule without migrating these staff queries.

Other roots and paths found include classes/{id}, its modules, quizzes,
assignments, forum_posts/replies, students, learning_paths, questionnaires;
users/{uid}/classes, module_progress, simulation_progress, practice_progress,
quiz_results, completed_content; notifications, quiz_results, submissions,
pre_assessments, competency_validations/history, content_locks, activity_events,
activity_feedback, questionnaire_responses, system_settings.
Queries use teacherId, classCode/status, role, classId, studentId/userId,
assignmentId/isGraded, isPublished, timestamps, ordering and limits.
Their authorization/PII migration is NOT covered by the enrollment prototype.
No permissive fallback is included in the prototype.

## Enrollment data model

- registration_issuers/{uid}: enabled boolean, provisioned only by a trusted
  console operator; no client writes. Existing editable users.role is NOT trusted.
- registration_checks/{sha256}: expiresAt timestamp ONLY; unauthenticated exact
  get is explicitly required for pre-account verification; list denied.
- registration_bindings/{sha256}: lrn (12 ASCII digits), private to issuers.
- lrn_master_list/{lrn}: firstName/lastName strings 1..150, optional middleName
  0..150, uploadedAt timestamp, isRegistered boolean; optional invitationId
  64 hex; registeredUid and registeredAt only on claim.
- users/{uid}, students/{uid}: existing student profile fields plus immutable
  registrationInvitationId. Creation requires an unused unexpired invitation,
  matching LRN binding and master invitation, both profiles and LRN claim in
  the same atomic batch, and deletion of the public check marker.

The 128-bit random code is shown once to the issuer, never stored in plaintext.
Hash input includes a version prefix, the LRN and normalized code. Possession of
the code is authorization: distribute privately after checking student identity.
Checks expose no names, LRN, UID or email. Public lookup can still consume quota;
Spark quotas and abuse monitoring are necessary. This is not rate limiting.

Firebase Auth creation and Firestore commit are NOT globally atomic. The UI
rechecks eligibility before Auth and the rules recheck at claim time. Interrupted
Auth accounts can resume with the same credentials and a valid invitation;
missing profiles must not open the student dashboard. A custom client can call
the public Auth signup API directly; only enrollment/data access is enforceable
with these rules. Absolute gating of Auth account creation requires a backend.

## Production rollout gate

Do not paste test/firestore/enrollment.rules over the live LMS rules.
Do not append it alongside the authenticated catch-all either.
First migrate the remaining collections and staff profile reads to explicit
least-privilege policies, bootstrap trusted issuer UIDs, validate full-system
queries, then deploy a combined ruleset and app together.
Production firebase.json is deliberately unchanged.
