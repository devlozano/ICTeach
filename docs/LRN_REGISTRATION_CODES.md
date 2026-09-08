# LRN registration validation

## Current status

Flutter integration and isolated enrollment rules tests are implemented.
**Not enabled safely in production yet.** Production firebase.json and live
rules have not been changed. Do not upload this web build as a completed rollout.

The enrollment-only prototype is at test/firestore/enrollment.rules. It denies
unrelated LMS operations and therefore must NOT replace your entire live ruleset.
Adding it underneath the old catch-all is also unsafe: matching allows are ORed.
The remaining LMS collection policies and staff profile queries need migration
before a combined ruleset can be deployed.

## School workflow

1. Administrator opens **Manage LRN Master List** and adds/imports the student.
2. Student enters the 12-digit LRN and taps **Verify LRN**.
3. Registration continues only when the LRN exists in the master list and is not
   already registered.

The controls are currently in the existing administrator LRN page. No new broad
teacher access to the master list has been granted.

## Implementation details and limits

The app performs an online check before creating the Firebase Auth account.
Final Firestore enrollment atomically creates both student profiles and claims
the LRN. The master record's `isRegistered` flag prevents reuse.

Auth and Firestore are separate services. If registration is interrupted after
Auth creation, repeat registration with the same email/password; the app signs
in to recover an account only if its profile does not exist.
An incomplete profile is routed to completion instead of the student dashboard.
If enrollment committed but the response was lost, sign in normally.

This validates the LRN and enrollment records, NOT an absolute ban on calling
Firebase Auth's public signup API from a modified client. Enforcing pre-checks
for Auth account creation itself needs a trusted backend.

## Automated tests (no production data)

From the project root:

```powershell
flutter test
npm.cmd --prefix test/firestore ci
$env:JAVA_HOME = 'C:/Program Files/Android/Android Studio/jbr'
$env:Path = $env:JAVA_HOME + '/bin;' + $env:Path
npx -y firebase-tools@latest emulators:exec --only firestore --project demo-icteach-enrollment --config test/firestore/firebase.json "npm.cmd --prefix test/firestore test"
```

Java 21+ is required; adjust its installation path if necessary.
The demo project cannot access live Firebase data. The rules tests cover valid
claims, concurrent/replayed/expired claims, partial writes, missing/wrong keys,
PII/list access, forged roles and UIDs, invalid types, oversized data, timestamps
and issuer permissions.

After the combined production rules are reviewed, test on Android and web:
invalid or already-registered LRN, double-submit, connection loss, completion
recovery, existing account login, and teacher/admin LMS workflows.
