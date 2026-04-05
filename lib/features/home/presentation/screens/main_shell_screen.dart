import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../chat/data/repositories/chat_repository.dart';

import 'poster_home_screen.dart';
import 'provider_home_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
class MainShellScreen extends ConsumerWidget {
  final Widget child;
  const MainShellScreen({super.key, required this.child});

  static const _tabs = [
    (icon: Icons.home_outlined,       activeIcon: Icons.home,         label: 'Home',     route: AppRoutes.home),
    (icon: Icons.search_outlined,     activeIcon: Icons.search,       label: 'Discover', route: AppRoutes.taskList),
    (icon: Icons.add_circle_outline,  activeIcon: Icons.add_circle,   label: 'Post',     route: ''),  // FAB-style
    (icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble,  label: 'Messages', route: AppRoutes.chatList),
    (icon: Icons.person_outline,      activeIcon: Icons.person,       label: 'Profile',  route: AppRoutes.myProfile),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String location = AppRoutes.home;
    try {
      location = GoRouterState.of(context).matchedLocation;
    } catch (_) {
      // Widget tests and non-router mounts can render the shell without GoRouter.
    }
    final idx = switch (location) {
      AppRoutes.home => 0,
      AppRoutes.taskList || AppRoutes.myTasks => 1,
      AppRoutes.chatList => 3,
      AppRoutes.myProfile => 4,
      _ => 0,
    };
    final unreadChats = ref.watch(unreadChatsCountProvider).valueOrNull ?? 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final isPost    = tab.route.isEmpty;
                final selected  = idx == i;
                final isMessages = tab.label == 'Messages';

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (isPost) {
                        context.push(AppRoutes.postTask);
                        return;
                      }
                      context.go(tab.route);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        isPost
                            ? Container(
                                width: 44, height: 44,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppColors.primary, AppColors.primaryLight],
                                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add, color: Colors.white, size: 26),
                              )
                            : Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    selected ? tab.activeIcon : tab.icon,
                                    color: selected ? AppColors.primary : AppColors.textHint,
                                    size: 24,
                                  ),
                                  if (isMessages && unreadChats > 0)
                                    Positioned(
                                      top: -4,
                                      right: -8,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: AppColors.error,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                        child: Text(
                                          unreadChats > 99 ? '99+' : '$unreadChats',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                        if (!isPost) ...[
                          const SizedBox(height: 2),
                          Text(
                            tab.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                              color: selected ? AppColors.primary : AppColors.textHint,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home Tab Content – role-aware dispatcher
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    // Use valueOrNull so we never spin forever — fall back to 'both' role
    // while the Firestore doc is still loading.
    final user = userAsync.valueOrNull;
    final role = user?.role ?? UserRole.both;

    switch (role) {
      case UserRole.poster:
        return const PosterHomeScreen();

      case UserRole.provider:
        return const ProviderHomeScreen();

      case UserRole.both:
        _tabController ??= TabController(length: 2, vsync: this);
        return Scaffold(
          backgroundColor: AppColors.bgLight,
          appBar: AppBar(
            backgroundColor: AppColors.bgCard,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Find Help'),
                Tab(text: 'Find Work'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: const [
              PosterHomeScreen(),
              ProviderHomeScreen(),
            ],
          ),
        );
    }
  }
}
