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
import '../../features/payment/checkout_screen.dart';
import '../constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Router Provider
// ─────────────────────────────────────────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
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
          GoRoute(path: AppRoutes.taskList, builder: (_, __) => const TaskListScreen()),
          GoRoute(path: AppRoutes.myTasks,  builder: (_, __) => const _MyTasksTab()),
          GoRoute(path: AppRoutes.chatList, builder: (_, __) => const ChatListScreen()),
          GoRoute(path: AppRoutes.myProfile, builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Task screens (full-screen, outside shell) ──────────────────────────
      // postTask must come before taskDetail to avoid /tasks/post matching /tasks/:taskId
      GoRoute(
        path: AppRoutes.postTask,
        builder: (_, __) => const PostTaskScreen(),
      ),
      GoRoute(
        path: AppRoutes.taskDetail,
        builder: (_, state) => TaskDetailScreen(taskId: state.pathParameters['taskId']!),
      ),

      // ── Profile screens ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.publicProfile,
        builder: (_, state) => PublicProfileScreen(userId: state.pathParameters['userId']!),
      ),
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
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});

// Stub tab builders – replaced by real screens in their feature modules
class _MyTasksTab  extends StatelessWidget { const _MyTasksTab();  @override Widget build(BuildContext ctx) => const _TabPlaceholder('My Tasks'); }

class _TabPlaceholder extends StatelessWidget {
  final String label;
  const _TabPlaceholder(this.label);
  @override
  Widget build(BuildContext context) => Center(
    child: Text(label, style: Theme.of(context).textTheme.headlineMedium),
  );
}
