# Journey Test Bug Report — Sprint 6

**Date:** 2026-03-30
**Tests:** `poster_journey_test.dart`, `provider_journey_test.dart`
**Environment:** iOS Simulator (iPhone 17 Pro Max), Firebase Emulators (Auth:9099, Firestore:8080)

---

## Bugs Found & Fixed

### BUG-001 — CRITICAL: FirebaseFirestore.instance accessed before Firebase.initializeApp()
- **Where:** `poster_journey_test.dart:39`, `provider_journey_test.dart:43`, `test_data.dart:157`
- **Expected:** Tests load and run
- **Actual:** `[core/no-app] No Firebase App '[DEFAULT]' has been created`
- **Root cause:** `final firestore = FirebaseFirestore.instance;` evaluated at parse time in `main()`, before `setUpAll()` calls `initializeTestApp()`
- **Fix:** Changed to `late final FirebaseFirestore firestore;` initialized after `initializeTestApp()`. Changed `test_data.dart` to use a getter.

### BUG-002 — CRITICAL: Router redirect bypasses onboarding flow after registration
- **Where:** `lib/core/router/app_router.dart:45-49`
- **Expected:** After email registration → navigate to role selection
- **Actual:** User sent directly to home screen, skipping role selection and profile setup
- **Root cause:** When auth state changes, `appRouterProvider` creates a new GoRouter (because it watches `authStateProvider`). The new router starts at `/splash`, and the SplashScreen only checked if user was logged in (not if profile was complete). Logged-in users were sent to home.
- **Fix:** (1) SplashScreen now checks `isProfileComplete` before routing to home vs roleSelect. (2) Router redirect excludes email/phone/OTP auth routes from the "logged-in → home" redirect.

### BUG-003 — MAJOR: Role selection doesn't persist selected role
- **Where:** `lib/features/auth/data/repositories/auth_repository.dart:91-93`, `lib/features/auth/presentation/screens/role_selection_screen.dart:26-28`
- **Expected:** Selecting "I need help" saves role as `poster`
- **Actual:** Role stays as `both` (default from registration)
- **Root cause:** `createOrUpdateUser()` only updates `lastActiveAt` when document already exists, ignoring all other fields including role.
- **Fix:** Added `updateUserRole()` method to AuthRepository. RoleSelectionScreen now calls `updateUserRole(uid, role)` directly.

### BUG-004 — MAJOR: Profile setup fails silently when currentUserProvider is null
- **Where:** `lib/features/auth/presentation/screens/profile_setup_screen.dart:55-56`
- **Expected:** Profile save succeeds and navigates to home
- **Actual:** `_save()` returns silently, user stuck on profile setup screen
- **Root cause:** `ref.read(currentUserProvider).valueOrNull` returns null when the Riverpod stream hasn't emitted yet (can happen after GoRouter recreation resets provider states).
- **Fix:** Added fallback: `currentUser ??= await AuthRepository().fetchCurrentUser()`.

### BUG-005 — CRITICAL: `/tasks/post` route matches `/tasks/:taskId` (route conflict)
- **Where:** `lib/core/router/app_router.dart:102-108`
- **Expected:** "Post a Task" navigates to PostTaskScreen
- **Actual:** Navigates to TaskDetailScreen with taskId='post', shows "Task not found"
- **Root cause:** GoRouter matches routes top-to-bottom. `taskDetail` (`/tasks/:taskId`) was defined before `postTask` (`/tasks/post`), so `/tasks/post` matched the wildcard `:taskId` parameter.
- **Fix:** Moved `postTask` route before `taskDetail` route.

### BUG-006 — CRITICAL: Chat creation fails — field name mismatch with security rules
- **Where:** `lib/features/chat/data/repositories/chat_repository.dart:131-140`
- **Expected:** Chat document created with correct field names
- **Actual:** `permission-denied` error on chat creation
- **Root cause:** Code wrote `participants` field but Firestore security rules check `participantIds`. Also, the `getChatsStream` query used `participants` instead of `participantIds`.
- **Fix:** Updated `createOrGetChat()` to write `participantIds`. Added `@JsonKey(name: 'participantIds')` to ChatModel. Updated query to use `participantIds`.

### BUG-007 — MAJOR: Chat creation fails reading non-existent document
- **Where:** `lib/features/chat/data/repositories/chat_repository.dart:116`
- **Expected:** `chatRef.get()` on non-existent doc returns exists=false
- **Actual:** `permission-denied` because security rules check `resource.data.participantIds` which doesn't exist for non-existent docs
- **Root cause:** Firestore security rules evaluate even for non-existent documents on `get()`. The `read` rule requires `participantIds` to contain the user, but non-existent docs have no data.
- **Fix:** Wrapped `get()` in try-catch. On permission error, proceeds to create the chat.

### BUG-008 — MINOR: tearDownAll signs out before cleanup, causing permission errors
- **Where:** `poster_journey_test.dart:57-59`, `provider_journey_test.dart:72-74`
- **Expected:** Emulator data cleaned up after test
- **Actual:** `permission-denied` on Firestore operations because user was signed out first
- **Fix:** Wrapped `cleanupEmulatorData()` in try-catch. Moved `signOutTestUser()` after cleanup.

---

## Test Step Results — Poster Journey

| Step | Description | Result |
|------|-------------|--------|
| 1 | App Launch (splash → welcome) | ✅ PASS |
| 2 | Register with email | ✅ PASS |
| 3 | Select poster role | ✅ PASS (after BUG-002, BUG-003 fix) |
| 4 | Profile setup | ✅ PASS (after BUG-004 fix) |
| 5 | Post task (5-step flow) | ✅ PASS (after BUG-005 fix) |
| 6 | Verify task in Firestore | ✅ PASS |
| 7 | Seed bid from provider | ✅ PASS (used REST API for cross-user seeding) |
| 8 | View bids on task detail | ✅ PASS |
| 9 | Accept bid | ✅ PASS |
| 10 | Chat with provider | ✅ PASS (after BUG-006, BUG-007 fix) |
| 11 | Mark task as complete | ✅ PASS |
| 12 | Final state verification | ✅ PASS |

### BUG-009 — MAJOR: setState() called after dispose in EmailAuthScreen
- **Where:** `lib/features/auth/presentation/screens/email_auth_screen.dart:78,97`
- **Expected:** Email auth flow completes without errors
- **Actual:** `setState() called after dispose(): _EmailAuthScreenState` — crash in integration test
- **Root cause:** After `await repo.fetchCurrentUser()` yields, the GoRouter recreation unmounts the email auth screen. The `catch` block at line 97 and `context.go()` at line 78 run on a defunct state.
- **Fix:** Added `if (!mounted) return;` guards before `context.go()` and before `setState()` in catch blocks.

## Test Step Results — Provider Journey

| Step | Description | Result |
|------|-------------|--------|
| 1 | App Launch (splash → welcome) | ✅ PASS |
| 2 | Register with email | ✅ PASS |
| 3 | Select provider role | ✅ PASS |
| 4 | Profile setup | ✅ PASS |
| 5 | Browse tasks | ✅ PASS |
| 6 | Verify provider task detail | ✅ PASS |
| 7 | Submit bid | ✅ PASS |
| 8 | Verify bid in Firestore | ✅ PASS |
| 9 | Verify own bid view | ✅ PASS |
| 10 | Seed acceptance | ✅ PASS (REST API for cross-user ops) |
| 11 | Verify accepted state | ✅ PASS |
| 12 | Chat with poster | ✅ PASS |
| 13 | Seed completion | ✅ PASS (REST API for cross-user ops) |
| 14 | Verify completed state | ✅ PASS |
| 15 | Final state verification | ✅ PASS |

## Summary

- **9 bugs found** (3 CRITICAL, 4 MAJOR, 2 MINOR)
- **All 9 bugs fixed** in this iteration
- **Poster journey:** 12/12 steps passing
- **Provider journey:** 15/15 steps passing
- **Unit tests:** 240 passed, 2 failed (pre-existing WelcomeScreen Dev Login failures)
- **`flutter analyze`:** 0 errors (112 warnings/infos, all pre-existing)
