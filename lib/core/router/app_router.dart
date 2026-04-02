import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/phone_auth_screen.dart';
import '../../features/auth/presentation/screens/email_auth_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';
import '../../features/home/presentation/screens/main_shell_screen.dart';
import '../../features/tasks/presentation/screens/task_detail_screen.dart';
import '../../features/tasks/presentation/screens/post_task_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/public_profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/photo_gallery_screen.dart';
import '../../features/profile/presentation/screens/verification_centre_screen.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/chat/presentation/screens/chat_thread_screen.dart';
import '../../features/tasks/presentation/screens/task_list_screen.dart';
import '../../features/discover/presentation/screens/discover_screen.dart';
import '../../features/notifications/presentation/screens/notification_list_screen.dart';
import '../../features/payment/checkout_screen.dart';
import '../../features/reviews/presentation/screens/submit_review_screen.dart';
import '../../features/providers/presentation/screens/provider_directory_screen.dart';
import '../../features/services/presentation/screens/create_service_screen.dart';
import '../../features/services/presentation/screens/service_detail_screen.dart';
import '../../features/tasks/presentation/screens/my_tasks_screen.dart';
import '../../features/bids/presentation/screens/my_bids_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Router Provider
// ─────────────────────────────────────────────────────────────────────────────
// Notifier that fires when Firebase auth state changes — used by GoRouter
// to re-evaluate redirects without rebuilding the entire router.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);

      // While auth state is still loading, don't redirect — avoids flash to welcome
      if (authState.isLoading) return null;

      final isLoggedIn    = authState.valueOrNull != null;
      final isAuthRoute   = state.matchedLocation.startsWith('/auth') ||
                            state.matchedLocation == AppRoutes.welcome ||
                            state.matchedLocation == AppRoutes.splash;

      if (!isLoggedIn && !isAuthRoute) return AppRoutes.welcome;
      if (isLoggedIn && isAuthRoute &&
          state.matchedLocation != AppRoutes.splash &&
          state.matchedLocation != AppRoutes.roleSelect &&
          state.matchedLocation != AppRoutes.profileSetup &&
          state.matchedLocation != AppRoutes.emailAuth &&
          state.matchedLocation != AppRoutes.phoneAuth &&
          state.matchedLocation != AppRoutes.otpVerify) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      // ── Auth flow ──────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.phoneAuth,
        builder: (_, __) => const PhoneAuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.emailAuth,
        builder: (_, __) => const EmailAuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.otpVerify,
        builder: (_, state) => OtpScreen(
          verificationId: state.uri.queryParameters['vid'] ?? '',
          phoneNumber:    state.uri.queryParameters['phone'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.roleSelect,
        builder: (_, __) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (_, __) => const ProfileSetupScreen(),
      ),

      // ── Main Shell (with bottom nav) ───────────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => MainShellScreen(child: child),
        routes: [
          GoRoute(path: AppRoutes.home,    builder: (_, __) => const HomeScreen()),
          GoRoute(path: AppRoutes.taskList, builder: (_, __) => const DiscoverScreen()),
          GoRoute(path: AppRoutes.myTasks,  builder: (_, __) => const MyTasksScreen()),
          GoRoute(path: AppRoutes.chatList, builder: (_, __) => const ChatListScreen()),
          GoRoute(path: AppRoutes.myProfile, builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Favorites ──────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.favorites,
        builder: (_, __) => const FavoritesScreen(),
      ),

      // ── My Bids (provider bid history) ─────────────────────────────────────
      GoRoute(
        path: AppRoutes.myBids,
        builder: (_, __) => const MyBidsScreen(),
      ),

      // ── Provider directory ──────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.providers,
        builder: (_, __) => const ProviderDirectoryScreen(),
      ),

      // ── Service listings ──────────────────────────────────────────────────
      // createService must come before serviceDetail to avoid :listingId match
      GoRoute(
        path: AppRoutes.createService,
        builder: (_, __) => const CreateServiceScreen(),
      ),
      GoRoute(
        path: AppRoutes.serviceDetail,
        builder: (_, state) =>
            ServiceDetailScreen(listingId: state.pathParameters['listingId']!),
      ),

      // ── Task screens (full-screen, outside shell) ──────────────────────────
      // postTask must come before taskDetail to avoid /tasks/post matching /tasks/:taskId
      GoRoute(
        path: AppRoutes.postTask,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PostTaskScreen(
            directHireProviderId: extra?['directHireProviderId'] as String?,
            directHireProviderName: extra?['directHireProviderName'] as String?,
            preSelectedCategory: extra?['preSelectedCategory'] as String?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.taskDetail,
        builder: (_, state) => TaskDetailScreen(taskId: state.pathParameters['taskId']!),
      ),

      // ── Profile screens (edit before :userId to avoid wildcard match) ────
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.photoGallery,
        builder: (_, __) => const PhotoGalleryScreen(),
      ),
      GoRoute(
        path: AppRoutes.verificationCentre,
        builder: (_, __) => const VerificationCentreScreen(),
      ),
      GoRoute(
        path: AppRoutes.publicProfile,
        builder: (_, state) => PublicProfileScreen(userId: state.pathParameters['userId']!),
      ),

      // ── Chat ──────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.chatThread,
        builder: (_, state) => ChatThreadScreen(chatId: state.pathParameters['chatId']!),
      ),

      // ── Checkout ───────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.checkout,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CheckoutScreen(
            taskId:       extra['taskId']       as String,
            bidId:        extra['bidId']        as String,
            providerName: extra['providerName'] as String,
            bidAmount:    extra['bidAmount']    as double,
          );
        },
      ),

      // ── Notifications ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.notificationList,
        builder: (_, __) => const NotificationListScreen(),
      ),

      // ── Reviews ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.submitReview,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return SubmitReviewScreen(
            taskId:           extra['taskId']           as String,
            reviewedUserId:   extra['reviewedUserId']   as String,
            reviewedUserName: extra['reviewedUserName'] as String,
            taskCategory:     extra['taskCategory']     as String,
          );
        },
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});

// (Stubs removed – real screens imported from feature modules)
