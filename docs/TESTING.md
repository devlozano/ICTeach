# ICTeach testing guide

Updated September 6, 2026. Use a teacher or trainer account in the web portal and a student account in the Android app. Student web login remains disabled by the existing platform policy.

## Prepare

Use a test class with one published module, a module containing a video, a published quiz, and at least two student accounts. Keep real learner data out of screenshots. There is no migration or test-data seed to run. New records are created when you use the features.

## Functional checks

| Test | Action | Expected result |
| --- | --- | --- |
| Remember me enabled | Sign in, close the app/browser, reopen | Account remains signed in |
| Remember me disabled | Sign in, fully close the Android app or close the browser session, reopen | Login is required; passwords are never stored by the preference service |
| Diagnostic required | Student opens Modules or Instructional Videos | 12-question CSS diagnostic appears before learning content |
| Incomplete diagnostic | Leave one answer blank | Submit stays disabled |
| Save failure | Disconnect before submitting | No unlock; answers stay available for retry |
| Diagnostic completion | Answer all questions, submit, continue | Score is saved, correct answers are shown, modules open regardless of score |
| Persistent diagnostic | Reopen modules or restart app | Completed diagnostic is not repeated for that student/class |
| Legacy placeholder record | Account has only an old completedAt pre-assessment record | Real diagnostic is still required |
| Staff review | Class Insights toolbar: assessment icon | Scores by COC1/COC2 appear; practical reviews can be recorded |
| Practical validation | Select validated without confirming observation or entering notes | Save is disabled |
| Practical validation persistence | Add observation/evidence and save, reopen | Outcome and notes persist; each review is also added to history |
| Category lock | Teacher/trainer: Modules > lock icon; turn All modules off | Student Modules and Instructional Videos are blocked |
| Individual lock | Turn one module, practice quiz, or simulation off | Student cannot open that activity; other unlocked activities remain available |
| Live lock | Lock the activity while the student has it open | Protected content disappears; video playback stops; quiz session is disposed |
| Unlock | Enable category and individual activity | Student can reopen it; simulation prerequisite requirements still apply |
| Module progress | Open a module, then Mark as Done | Opening means In Progress; Mark as Done persists completion |
| Progress after restart | Restart student app and open Progress | Real completed modules, passed simulations and diagnostic are counted |
| Removed content | Unpublish a completed module | It is excluded from both the current module numerator and denominator |
| Quiz submission | Submit once, try opening/submitting again | Saved attempt cannot be overwritten; result is retained |
| Quiz save failure | Disconnect before submission | Error is shown and answers remain available to retry saving |
| Simulation pass | Complete a simulation | Completion is shown only after progress is saved |
| Simulation save failure | Disconnect before completing | Retry save action appears; no false saved-completion message |
| Simulation retry | Pass, then retry and fail | Earlier passed progress and the better score remain intact |
| Forum images | Post JPG/PNG/WebP images and reopen the thread | Images appear in feed and detail; up to five, max 10 MB each |
| Forum validation | Select too many images or an unsupported format | Clear validation message; no upload |
| Leaderboard | Open student Progress and staff Class Insights | Percentage bars use a fixed 0-100 scale; top ten entries are shown |
| Grade export | Class Insights toolbar: download icon | CSV can be shared/downloaded and opened in Excel; commas/quotes in names remain intact |
| Admin content | Admin navigation: Content Overview | Each class shows module/quiz/assignment totals and published counts, with management links |
| Regression | Register via LRN, join via code/QR, submit/grade assignment, forum replies, notifications, logout | Existing functions continue to work |

Locks implement app access control. The live database's permissive rules are a separate release blocker; do not treat these manual tests as proof of backend security. Locking an active quiz discards that in-memory session; a submitted result remains saved.

## Automated checks

Run from the repository root:

```powershell
flutter pub get
flutter test
flutter analyze --no-fatal-infos
flutter build web --release --no-wasm-dry-run
flutter build apk --release
```

Existing info-level analyzer findings remain. Automated tests cover diagnostic scoring and legacy record handling, lock matching/live changes/failure handling, login preferences, chart layout, CSV safety, progress arithmetic, and simulation assets. They do not substitute for real-account Firebase, Cloudinary, camera/QR, notifications, or device testing.

## Report a problem

Record account role, screen, exact actions, expected/actual result, connection state, platform, and screenshot. Use test account names rather than passwords or private learner details.
