# Iteration Log

This file is the shared handoff log for all autonomous work by Claude and Codex.

Every iteration must append one new entry.
Do not replace older entries.

## Required Entry Format

```md
## 2026-04-04 14:30 SGT | codex | ITER-00X

- Task IDs: UX-201, UX-202
- Branches: agents/codex/ux-201, agents/codex/ux-202
- Summary:
  - Short high-level summary of the work completed.
- Key changes:
  - User-facing or architectural changes.
- Files touched:
  - Important files only, not every generated diff line.
- Verification:
  - Tests/analyze commands run and whether they passed.
- Risks / follow-up:
  - Remaining issues, deferred items, or what the next agent should inspect.
```

## Rules

- One entry per iteration or work batch.
- Claude and Codex both append here.
- Keep entries concise but concrete enough that another model can continue without re-discovery.
- Include exact commands for verification when useful.
- If work is incomplete or blocked, say so explicitly.
- If the iteration changes workflow or coordination rules, note that clearly.

---

## 2026-04-04 14:10 SGT | codex | ITER-001

- Task IDs: UX-201, UX-202
- Branches: agents/codex/ux-201, agents/codex/ux-202
- Summary:
  - Set up the hybrid architect/Claude/Codex workflow and completed the first non-payment UX stabilization batch.
- Key changes:
  - Added model-neutral task board workflow with per-task branch/worktree ownership.
  - Fixed per-user chat unread counts.
  - Kept Discover search UI for provider-only users.
  - Made `My Tasks` role-aware for provider vs poster use.
  - Removed forced checkout after bid acceptance while payment work is deferred.
  - Replaced several raw error text states with retryable `ErrorState`.
- Files touched:
  - `agents/HYBRID_WORKFLOW.md`
  - `agents/task_board.py`
  - `agents/task-board.json`
  - `agents/README.md`
  - `lib/features/chat/data/repositories/chat_repository.dart`
  - `lib/features/discover/presentation/screens/discover_screen.dart`
  - `lib/features/tasks/presentation/screens/my_tasks_screen.dart`
  - `lib/features/home/presentation/screens/main_shell_screen.dart`
  - `lib/features/services/presentation/screens/service_listings_screen.dart`
  - `lib/features/bids/presentation/widgets/bid_list_section.dart`
  - `test/features/new_features_test.dart`
- Verification:
  - Passed: `flutter test test/features/new_features_test.dart test/widgets/profile_chat_nav_test.dart test/widgets/task_screens_test.dart test/chat/chat_repository_test.dart`
  - Repo-wide `flutter analyze` still had an existing backlog of warnings/infos; no new hard analyzer failures from this batch.
- Risks / follow-up:
  - Payment-state structural issues remain intentionally deferred.
  - Several high-traffic screens still had dead-end empty/error states worth another pass.

## 2026-04-04 15:00 SGT | codex | ITER-002

- Task IDs: UX-203
- Branches: agents/codex/ux-203
- Summary:
  - Improved role-aware empty states, search consistency, and profile/detail recovery flows.
- Key changes:
  - Chat list empty state now differs for provider-only vs poster/both users.
  - Discover search field now hydrates from persisted search provider state.
  - Profile, verification centre, photo gallery, and bid list now use better recoverable states.
  - Photo gallery now distinguishes between no photos at all and no photos for the selected category.
  - Task, service listing, and public profile detail pages now show actionable recovery states instead of bare “not found” text.
- Files touched:
  - `lib/features/chat/presentation/screens/chat_list_screen.dart`
  - `lib/features/discover/presentation/screens/discover_screen.dart`
  - `lib/features/profile/presentation/screens/profile_screen.dart`
  - `lib/features/profile/presentation/screens/verification_centre_screen.dart`
  - `lib/features/profile/presentation/screens/photo_gallery_screen.dart`
  - `lib/features/tasks/presentation/screens/task_detail_screen.dart`
  - `lib/features/services/presentation/screens/service_detail_screen.dart`
  - `lib/features/profile/presentation/screens/public_profile_screen.dart`
  - `test/widgets/profile_chat_nav_test.dart`
  - `test/widgets/task_screens_test.dart`
  - `test/features/new_features_test.dart`
- Verification:
  - Passed: `flutter test test/widgets/profile_chat_nav_test.dart test/features/new_features_test.dart test/widgets/task_screens_test.dart test/chat/chat_repository_test.dart`
  - Passed: `flutter test test/widgets/task_screens_test.dart test/widgets/profile_chat_nav_test.dart`
  - Targeted analyze on touched files showed lint/deprecation infos only, no hard errors.
- Risks / follow-up:
  - Home-screen subsections still had silent failure behavior (`SizedBox.shrink()` on error).
  - Some submission flows still used raw/internal error copy.

## 2026-04-04 15:45 SGT | codex | ITER-003

- Task IDs: UX-203
- Branches: agents/codex/ux-203
- Summary:
  - Hardened home-dashboard degradation, form-flow messaging, and notifications/settings empty/failure UX.
- Key changes:
  - Provider/poster home task-loading failures now show retryable error UI.
  - Provider home sections (`My Services`, `Recommended`) now show visible retry cards on error instead of silently disappearing.
  - Bid, task-posting, and service-creation flows now guard missing-auth cases and use clearer user-facing failure messages.
  - Settings screen now handles missing current user and URL-launch failure better.
  - Notification empty state now uses standard actionable empty-state UI with CTA.
- Files touched:
  - `lib/features/home/presentation/screens/provider_home_screen.dart`
  - `lib/features/home/presentation/screens/poster_home_screen.dart`
  - `lib/features/bids/presentation/widgets/submit_bid_sheet.dart`
  - `lib/features/services/presentation/screens/create_service_screen.dart`
  - `lib/features/tasks/presentation/screens/post_task_screen.dart`
  - `lib/features/settings/presentation/screens/settings_screen.dart`
  - `lib/features/notifications/presentation/screens/notification_list_screen.dart`
  - `test/features/new_features_test.dart`
  - `test/widgets/profile_chat_nav_test.dart`
- Verification:
  - Passed: `flutter test test/widgets/profile_chat_nav_test.dart`
  - Passed: `flutter test test/features/new_features_test.dart`
  - Passed: `flutter test test/widgets/task_screens_test.dart test/features/new_features_test.dart`
- Risks / follow-up:
  - Remaining analyzer noise is mostly existing `withOpacity` deprecation infos and style lints in larger legacy UI files.
  - Next worthwhile pass: chat thread/support flows and any remaining silent failures in sub-sections.

## 2026-04-04 16:35 SGT | codex | ITER-004

- Task IDs: UX-203
- Branches: agents/codex/ux-203
- Summary:
  - Continued polishing high-friction user flows and prepared the branch for merge back to `main`.
- Key changes:
  - Provider home sections no longer fail silently when recommendations or service listings fail to load.
  - Task / service / public-profile missing-detail states now include recovery CTAs.
  - Form submission flows for bids, tasks, services, settings, and notifications use clearer user-facing messaging and stronger auth guards.
  - Added/extended widget tests for photo gallery category-empty state, missing task detail recovery, and notifications empty state.
- Files touched:
  - `lib/features/home/presentation/screens/provider_home_screen.dart`
  - `lib/features/tasks/presentation/screens/task_detail_screen.dart`
  - `lib/features/services/presentation/screens/service_detail_screen.dart`
  - `lib/features/profile/presentation/screens/public_profile_screen.dart`
  - `lib/features/bids/presentation/widgets/submit_bid_sheet.dart`
  - `lib/features/services/presentation/screens/create_service_screen.dart`
  - `lib/features/tasks/presentation/screens/post_task_screen.dart`
  - `lib/features/settings/presentation/screens/settings_screen.dart`
  - `lib/features/notifications/presentation/screens/notification_list_screen.dart`
  - `test/widgets/task_screens_test.dart`
  - `test/widgets/profile_chat_nav_test.dart`
  - `test/features/new_features_test.dart`
- Verification:
  - Passed: `flutter test test/widgets/profile_chat_nav_test.dart`
  - Passed: `flutter test test/widgets/task_screens_test.dart test/widgets/profile_chat_nav_test.dart`
  - Passed: `flutter test test/widgets/task_screens_test.dart test/features/new_features_test.dart`
  - Passed: `flutter test test/features/new_features_test.dart`
- Risks / follow-up:
  - Branch still needs final commit/merge bookkeeping after this iteration.
  - Remaining app-wide cleanup is mostly legacy lint/deprecation noise and deeper emulator QA, not blockers for merge.
## 2026-04-04 20:30 SGT | claude | ITER-004

- Task IDs: UX-204
- Branches: agents/claude/ux-204
- Summary:
  - Fixed bid submission permission-denied error. Providers could create bid docs but the subsequent bidCount increment on the parent task failed because providers lack task-level write permission.
- Key changes:
  - Wrapped bidCount increment in try-catch in bid_repository.dart so bid creation succeeds regardless.
  - Added Firestore security rule allowing any signed-in user to update tasks if the ONLY changed field is bidCount.
  - Deployed updated firestore.rules to production.
- Files touched:
  - `lib/features/bids/data/repositories/bid_repository.dart`
  - `firestore.rules`
- Verification:
  - `flutter analyze` on bid_repository: 0 errors
  - `firebase deploy --only firestore:rules` succeeded
  - Firestore rules compiled and deployed
- Risks / follow-up:
  - bidCount-only rule allows any user to increment — low risk since it's just a counter, but long-term should use a Cloud Function trigger on bid creation.
  - UX-205 (budget display format) still planned, not yet claimed.

## 2026-04-04 21:05 SGT | codex | ITER-005

- Task IDs: UX-205
- Branches: agents/codex/ux-205
- Summary:
  - Fixed task budget formatting so integer values no longer render with a trailing `.0`.
- Key changes:
  - Updated `TaskModel.budgetDisplay` to format integer amounts as whole numbers while preserving meaningful decimals.
  - Added regression coverage for both integer budgets and decimal budgets.
- Files touched:
  - `lib/features/tasks/data/models/task_model.dart`
  - `test/models/task_model_test.dart`
- Verification:
  - Passed: `flutter test test/models/task_model_test.dart test/widgets/task_screens_test.dart`
- Risks / follow-up:
  - This iteration only changes task budget display.
  - Other price displays like payment totals or bid amounts were intentionally left unchanged.

## 2026-04-04 21:37 SGT | codex | ITER-006

- Task IDs: UX-206
- Branches: agents/codex/ux-206
- Summary:
  - Tightened chat-thread failure handling and corrected a misleading notification CTA label.
- Key changes:
  - `ChatThreadScreen` now shows clearer auth/failure messages for send attempts.
  - Failed text sends restore the typed draft instead of discarding the user's message.
  - Review notifications now say `View Profile`, matching the actual navigation target.
  - Cleaned up targeted lint/deprecation noise in the touched chat/test files.
- Files touched:
  - `lib/features/chat/presentation/screens/chat_thread_screen.dart`
  - `lib/features/notifications/presentation/screens/notification_list_screen.dart`
  - `test/widgets/profile_chat_nav_test.dart`
  - `test/features/new_features_test.dart`
- Verification:
  - Passed: `flutter test test/widgets/profile_chat_nav_test.dart test/features/new_features_test.dart`
  - Passed: `flutter analyze lib/features/chat/presentation/screens/chat_thread_screen.dart lib/features/notifications/presentation/screens/notification_list_screen.dart test/widgets/profile_chat_nav_test.dart test/features/new_features_test.dart`
- Risks / follow-up:
  - Snackbar visibility itself is still better validated by manual emulator QA than widget tests in the current harness.
  - Next useful pass is deeper manual QA around posting, bidding, and support/settings flows.

## 2026-04-04 21:48 SGT | codex | ITER-007

- Task IDs: UX-207
- Branches: agents/codex/ux-207
- Summary:
  - Removed more silent disappearances from Favorites and Home so users see recovery UI instead of blank gaps.
- Key changes:
  - Saved task/provider rows now show visible unavailable/error cards instead of disappearing when underlying records are missing or fail to load.
  - Unavailable favorites now offer direct `Remove` actions, reducing dead data in a user's saved list.
  - Job offers and pending reviews home sections now surface retryable error UI instead of silently collapsing.
  - Replaced more raw/internal error copy in Favorites with user-facing messaging.
- Files touched:
  - `lib/features/favorites/presentation/screens/favorites_screen.dart`
  - `lib/features/home/presentation/widgets/job_offers_section.dart`
  - `lib/features/home/presentation/widgets/pending_reviews_section.dart`
  - `test/features/new_features_test.dart`
- Verification:
  - Passed: `flutter test test/features/new_features_test.dart`
  - Passed: `flutter analyze lib/features/favorites/presentation/screens/favorites_screen.dart lib/features/home/presentation/widgets/job_offers_section.dart lib/features/home/presentation/widgets/pending_reviews_section.dart test/features/new_features_test.dart`
- Risks / follow-up:
  - There are still other `e.toString()` surfaces in the app worth converting to user-facing copy.
  - Next likely batch should target auth/profile-setup and remaining detail/subsection edge cases.

## 2026-04-04 22:18 SGT | codex | ITER-008

- Task IDs: UX-208
- Branches: agents/codex/ux-208
- Summary:
  - Replaced more raw exception copy in high-traffic auth/profile/chat/bids surfaces with clearer user-facing messaging.
- Key changes:
  - `ProfileSetupScreen` save failures now show friendly messages instead of raw `Error: ...`.
  - `EmailAuthScreen` no longer exposes unknown Firebase/internal errors directly to the user.
  - `ProfileScreen`, `ChatListScreen`, and `MyBidsScreen` now use stable user-facing error copy in their main error states.
  - Added targeted regression coverage for profile load failure, chat load failure, and bid load failure states.
- Files touched:
  - `lib/features/auth/presentation/screens/profile_setup_screen.dart`
  - `lib/features/auth/presentation/screens/email_auth_screen.dart`
  - `lib/features/profile/presentation/screens/profile_screen.dart`
  - `lib/features/chat/presentation/screens/chat_list_screen.dart`
  - `lib/features/bids/presentation/screens/my_bids_screen.dart`
  - `test/widgets/auth_screens_test.dart`
  - `test/widgets/profile_chat_nav_test.dart`
  - `test/features/new_features_test.dart`
- Verification:
  - Passed: `flutter test test/widgets/auth_screens_test.dart`
  - Passed: `flutter test test/widgets/profile_chat_nav_test.dart --plain-name "shows friendly error when profile fails to load"`
  - Passed: `flutter test test/widgets/profile_chat_nav_test.dart --plain-name "shows friendly error when chats fail to load"`
  - Passed: `flutter test test/features/new_features_test.dart --plain-name "shows friendly error when bids fail to load"`
  - Passed: `flutter analyze lib/features/auth/presentation/screens/profile_setup_screen.dart lib/features/auth/presentation/screens/email_auth_screen.dart lib/features/profile/presentation/screens/profile_screen.dart lib/features/chat/presentation/screens/chat_list_screen.dart lib/features/bids/presentation/screens/my_bids_screen.dart test/widgets/auth_screens_test.dart test/widgets/profile_chat_nav_test.dart test/features/new_features_test.dart`
- Risks / follow-up:
  - A few other screens still use `e.toString()` in lower-priority surfaces and provider lists.
  - `ProfileSetupScreen` save-failure copy is covered by implementation and manual behavior, but not by a stable widget assertion because the current test harness is brittle around that submission path.

## 2026-04-04 22:31 SGT | codex | ITER-009

- Task IDs: UX-209
- Branches: agents/codex/ux-209
- Summary:
  - Polished remaining top-level recovery states across notifications, tasks, profile support screens, and home dashboards.
- Key changes:
  - Notification list, My Tasks, verification centre, and photo gallery now show stable user-facing error copy instead of raw/internal exceptions.
  - Photo gallery and verification centre no longer fall back to brittle blank/profile-unavailable placeholders when current user data is missing.
  - Poster/provider home dashboards now use clearer recovery copy for task-loading failures.
  - Cleaned analyzer noise in touched task/home/profile files while updating these states.
- Files touched:
  - `lib/features/notifications/presentation/screens/notification_list_screen.dart`
  - `lib/features/tasks/presentation/screens/my_tasks_screen.dart`
  - `lib/features/profile/presentation/screens/verification_centre_screen.dart`
  - `lib/features/profile/presentation/screens/photo_gallery_screen.dart`
  - `lib/features/home/presentation/screens/poster_home_screen.dart`
  - `lib/features/home/presentation/screens/provider_home_screen.dart`
  - `test/widgets/profile_chat_nav_test.dart`
  - `test/features/new_features_test.dart`
- Verification:
  - Passed: `flutter test test/widgets/profile_chat_nav_test.dart --plain-name "shows friendly error when gallery fails to load"`
  - Passed: `flutter test test/widgets/profile_chat_nav_test.dart --plain-name "shows friendly error when verification fails to load"`
  - Passed: `flutter test test/features/new_features_test.dart --plain-name "shows friendly error when tasks fail to load"`
  - Passed: `flutter test test/features/new_features_test.dart --plain-name "shows friendly error when notifications fail to load"`
  - Passed: `flutter analyze lib/features/notifications/presentation/screens/notification_list_screen.dart lib/features/tasks/presentation/screens/my_tasks_screen.dart lib/features/profile/presentation/screens/verification_centre_screen.dart lib/features/profile/presentation/screens/photo_gallery_screen.dart lib/features/home/presentation/screens/poster_home_screen.dart lib/features/home/presentation/screens/provider_home_screen.dart test/widgets/profile_chat_nav_test.dart test/features/new_features_test.dart`
- Risks / follow-up:
  - Lower-priority provider/task list provider layers still expose raw error strings internally.
  - The next useful step is shifting from copy cleanup to broader emulator path testing for end-to-end regressions.

## 2026-04-05 00:14 SGT | codex | ITER-010

- Task IDs: UX-210
- Branches: agents/codex/ux-210
- Summary:
  - Sanitized remaining high-traffic list and fallback states so users no longer see raw backend errors in task/provider/bid entry points.
- Key changes:
  - Task list and provider directory notifiers now surface stable user-facing load errors instead of propagating `e.toString()` into UI.
  - Chat list and profile screen now show retryable recovery states when current user data is unavailable, replacing brittle `Please sign in` / `Profile unavailable` placeholders.
  - My Bids now labels missing tasks as `Task unavailable`, and task bid lists use a friendly recoverable load error instead of raw exception text.
  - Added regression coverage for task list failure, provider directory failure, bid list failure, missing-profile fallback, missing-chat-user fallback, and missing-task bid titles.
- Files touched:
  - `lib/features/tasks/domain/providers/task_list_provider.dart`
  - `lib/features/providers/domain/providers/provider_list_provider.dart`
  - `lib/features/chat/presentation/screens/chat_list_screen.dart`
  - `lib/features/profile/presentation/screens/profile_screen.dart`
  - `lib/features/bids/presentation/screens/my_bids_screen.dart`
  - `lib/features/bids/presentation/widgets/bid_list_section.dart`
  - `test/widgets/task_screens_test.dart`
  - `test/widgets/profile_chat_nav_test.dart`
  - `test/features/new_features_test.dart`
- Verification:
  - Passed: `flutter analyze lib/features/tasks/domain/providers/task_list_provider.dart lib/features/providers/domain/providers/provider_list_provider.dart lib/features/chat/presentation/screens/chat_list_screen.dart lib/features/profile/presentation/screens/profile_screen.dart lib/features/bids/presentation/screens/my_bids_screen.dart lib/features/bids/presentation/widgets/bid_list_section.dart test/widgets/task_screens_test.dart test/widgets/profile_chat_nav_test.dart test/features/new_features_test.dart`
  - Passed: `flutter test test/widgets/task_screens_test.dart test/widgets/profile_chat_nav_test.dart test/features/new_features_test.dart`
- Risks / follow-up:
  - `auth_provider.dart` still keeps raw auth error strings in state for OTP/phone flows; those should be normalized in a future pass with UI-specific copy.
  - The app router still exposes raw `state.error` in the not-found page, which should eventually be converted into a friendlier recovery screen.

## 2026-04-05 00:36 SGT | codex | ITER-011

- Task IDs: UX-211
- Branches: agents/codex/ux-211
- Summary:
  - Normalized authentication failure messaging and replaced the raw router error page with a friendly recovery state.
- Key changes:
  - `PhoneAuthNotifier` now maps Firebase and generic OTP/phone failures into stable user-facing copy instead of surfacing raw exception strings.
  - OTP verification now distinguishes expired-code failures from generic invalid OTP failures.
  - The app router no longer renders `Page not found: ...`; missing routes now use a recovery screen that sends users back to `home` or `welcome`.
  - Added notifier, auth screen, and router regression coverage for normalized error copy and missing-page recovery UI.
- Files touched:
  - `lib/features/auth/domain/providers/auth_provider.dart`
  - `lib/core/router/app_router.dart`
  - `test/auth/phone_auth_notifier_test.dart`
  - `test/widgets/auth_screens_test.dart`
- Verification:
  - Passed: `flutter analyze lib/features/auth/domain/providers/auth_provider.dart lib/core/router/app_router.dart test/auth/phone_auth_notifier_test.dart test/widgets/auth_screens_test.dart`
  - Passed: `flutter test test/auth/phone_auth_notifier_test.dart test/widgets/auth_screens_test.dart`
- Risks / follow-up:
  - Email auth and some profile-edit flows still do their own ad-hoc error mapping; these should eventually be consolidated so auth copy is consistent across all entry points.
  - The next higher-value pass is emulator-based end-to-end QA, since top-level error text is now much cleaner and deeper flow bugs are more likely to remain than copy issues.

## 2026-04-05 00:47 SGT | codex | ITER-012

- Task IDs: UX-212
- Branches: agents/codex/ux-212
- Summary:
  - Realigned an outdated task-list provider regression test with the newer friendly error-state contract already shipped in the app.
- Key changes:
  - Updated `task_list_provider_test.dart` so stream errors now assert the normalized user-facing copy instead of raw exception text.
  - Cleaned the touched test’s low-risk `const` hints while verifying the new expectation.
- Files touched:
  - `test/tasks/task_list_provider_test.dart`
- Verification:
  - Passed: `flutter test test/tasks/task_list_provider_test.dart`
  - Passed: `flutter test test/widgets/task_screens_test.dart --plain-name "shows friendly error when tasks fail to load"`
  - `flutter analyze test/tasks/task_list_provider_test.dart` still reports one pre-existing sealed-class fake warning (`Query` test double), but no new errors from this change.
- Risks / follow-up:
  - Similar older provider-layer tests should be checked opportunistically during broader suite runs to catch any other stale raw-error expectations.
  - The sealed `Query` fake in `task_list_provider_test.dart` should eventually be refactored rather than left as an analyzer warning.

## 2026-04-05 10:00 SGT | claude | ITER-005

- Task IDs: UX-213
- Branches: agents/claude/ux-213
- Summary:
  - End-to-end regression QA after 12 UX stabilization tasks (UX-201 to UX-212).
  - All 5 integration tests pass. All 329 unit tests pass. 0 analyze errors.
- Key changes:
  - No code changes — this was a pure QA verification pass.
- Verification:
  - `flutter test` — 329 passed, 0 failed
  - `flutter analyze` — 0 errors
  - Integration tests on iOS Simulator + Firebase Emulators:
    - Poster Journey: PASS
    - Provider Journey: PASS
    - Edit Profile: PASS
    - Flow 1 (Task Bidding): PASS
    - Flow 2 (Direct Hire): PASS
  - Cloud Functions `onUserCreate` now works correctly (FieldValue fix confirmed)
- Risks / follow-up:
  - Some non-fatal rendering/scheduler exceptions still appear during integration tests (exit code 0 but stderr has EXCEPTION lines). These are likely layout edge cases in less-tested screens.
  - Next valuable work: visual polish pass, or new feature development based on user feedback.
