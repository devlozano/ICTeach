# Release and deployment

Canonical production hostname: `icteach.ipeso.website` (not `iteach.ipeso.website`). The tracked `web/.htaccess` redirects www to non-www and revalidates Flutter entry files.

## Local build

```powershell
flutter pub get
flutter test
flutter analyze --no-fatal-infos
flutter build web --release --no-wasm-dry-run
flutter build apk --release
```

Web files: `build/web/`. Android APK: `build/app/outputs/flutter-apk/app-release.apk`. A successful build is not a live deployment.

## Hostinger

Upload the contents of `build/web/`, including `.htaccess`, directly into this domain's `public_html`. Do not upload an enclosing build/web folder. Verify the upload target in Hostinger first. After upload, clear hosting/CDN caches if enabled, reopen in a private browser, and verify the new login controls and `main.dart.js` response. Check the www redirect as well.

## GitHub Actions

The workflow pins Flutter 3.41.9, builds, runs tests/analysis, keeps a downloadable artifact including hidden files, and deploys with FTPS and strict certificate validation. It copies the tracked `.htaccess` instead of replacing it with a different routing file.

Configure these GitHub repository secrets:

| Secret | Value |
| --- | --- |
| FTP_HOST | Hostinger FTP hostname whose certificate matches, obtained from the hosting account; avoid the raw IP |
| FTP_USERNAME | Account restricted to the intended site |
| FTP_PASSWORD | Matching FTP password |

The current workflow uses port 21 and server directory `/public_html/`. Verify these against the account. Changing `protocol` back to plain FTP or disabling certificate validation is not a solution to a hostname mismatch. The workflow triggers on main pushes or manual dispatch. No push or deployment was performed as part of local implementation.

GitHub CLI was not authenticated during this run, so repository secrets and recent run success could not be inspected. Authenticate locally with `gh auth login` when ready to operate GitHub.

## Firebase release blocker

The existing `icteach-free` default Standard database was inspected on September 6, 2026. Its deployed rules contain a recursive allow-read/write for every authenticated account. More restrictive overlapping matches do not cancel that allow. This permits role changes and modification of other users' data and means app controls are not a security boundary.

The implementation did not replace live rules. Hardening needs an application-wide rules migration and tests for registration/LRN access, staff provisioning, class membership, forum notifications, reports, result ownership, and the new collections. Remove the broad allow and protect role/membership authority before any public rollout. Client-scored quizzes and diagnostics remain instructional records rather than tamper-resistant examinations.

New data paths to account for:

- `content_locks/{classId}_{type}_{contentId}`: staff-written class/category or individual activity locks; `*` represents a category; old auto-ID records are updated too.
- `pre_assessments/{studentId}_{classId}`: diagnostic answers, scores, version, completion and timestamp.
- `competency_validations/{classId}_{studentId}_{COC}` and its `history` subcollection: class staff reviews and evidence notes.
- `users/{uid}/module_progress/{classId}_{moduleId}`: started/completed module state.
- Existing quiz and simulation progress paths remain in use. Quiz copies are written in one transaction; previously passed simulations retain their best passing result.

Cloudinary uploads still require the existing `icteach_unsigned` preset to allow the configured folder and file types. No test post or upload was created in production.
