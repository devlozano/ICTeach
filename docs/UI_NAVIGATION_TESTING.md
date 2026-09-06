# UI and navigation update

## What changed

- Teacher and trainer desktop navigation now shares a dark, scrollable Material sidebar with explicitly painted selected backgrounds and readable text/icons. It remains usable in short windows and with larger text.
- Dashboard sections have a visible title and an Overview back action outside the main scrollable content.
- The global AppBar theme no longer overrides each page's title/back-icon foreground. Shared buttons have 48px minimum targets and light-surface tabs have explicit contrast.
- A persistent, labeled Back control appears above pushed pages on web and mobile, using the same Navigator as device back and honoring PopScope guards.
- Removed the splash screen's nested Navigator. There is one root page stack, and dashboard back no longer calls SystemNavigator.pop.
- Same-account dashboard tabs and supported page stacks are stored locally. Authentication and class access are checked before restored content is shown. Network failures show Retry without discarding the destination.
- Student lesson selection is saved by module ID, not list position; its back action returns to the module list. Clicked Class Insights tabs and the admin panel selection are also saved.

## Refresh/restart coverage

Supported destinations: class details/rosters, module/quiz/assignment/questionnaire management, forums, Class Insights, content locks, learning-path setup, activity timeline, assessment review, student modules/quizzes/assignments/questionnaires/videos, simulation preparation, and notifications.

Persistence is local to the browser/device and signed-in account. It is not cross-device synchronization or URL-based deep linking. Remember-me/session-expiration rules still apply. Clearing site/app data removes the saved workspace.

Unsaved editors, form drafts, modal dialogs, scroll positions, video playback positions, and in-progress quiz/simulation state are **not restored**. Those transient screens fall back to the last supported parent destination, rather than replaying an assessment or submitting a form. This is not a claim that every screen has full state restoration.

## Acceptance checks

1. Teacher and trainer: use Overview, Classes (teacher), Discussions, Analytics (teacher), and Profile. Confirm selected labels remain readable. Resize from desktop to tablet/phone width and shorten the window; sidebar items and Sign out must remain reachable.
2. Open a class → Modules/Quizzes/Assignments/Insights. Use the labeled Back action and the device Back button separately. Both should return through the page stack without signing out or closing the app.
3. In a non-overview dashboard tab, Back should return to Overview. Back at the dashboard should keep ICTeach open.
4. Refresh each supported web destination while signed in. It should return to the saved account's page and selected dashboard tab. Restart Android with Remember me enabled and repeat.
5. Open a student lesson, refresh, then use Back: it should return to the module list first.
6. Switch accounts: no other user's saved page stack or tab should appear. Revoke class access: restored content should remain blocked.
7. Test a failed access lookup: Retry must preserve the saved destination.
8. Check dark AppBar titles, back icons, and Class Insights tab labels for contrast. Check the existing staff/student login layouts at 360px width.

## Verification scope

Automated tests cover account-scoped persistence, corrupt/out-of-range stored values, route descriptor roundtrips and role filtering, short sidebars with enlarged text, selected-label contrast, dark AppBar title/back-icon colors, and framework device-back handling. Existing business-logic tests remain in the suite.

Signed-in browser visual inspection and physical Android navigation tests still need acceptance testing. No production deployment or Firebase configuration/rules changes were made for this UI update.
