import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../../features/tasks/presentation/screens/post_task_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Current tab index provider
// ─────────────────────────────────────────────────────────────────────────────
final _tabIndexProvider = StateProvider<int>((ref) => 0);

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
    final idx = ref.watch(_tabIndexProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -2))],
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

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (isPost) {
                        context.push(AppRoutes.postTask);
                        return;
                      }
                      ref.read(_tabIndexProvider.notifier).state = i;
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
                            : Icon(
                                selected ? tab.activeIcon : tab.icon,
                                color: selected ? AppColors.primary : AppColors.textHint,
                                size: 24,
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
// Home Tab Content
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.bgCard,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userAsync.valueOrNull?.neighbourhood ?? 'Singapore',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
                ),
                Row(children: [
                  const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                  const SizedBox(width: 2),
                  Text(
                    'Hi, ${userAsync.valueOrNull?.displayName?.split(' ').first ?? 'Neighbour'}! 👋',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ]),
              ],
            ),
            actions: [
              IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Search bar ─────────────────────────────────────────────
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.taskList),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: AppRadius.button,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(children: [
                        const Icon(Icons.search, color: AppColors.textHint),
                        const SizedBox(width: 10),
                        Text('Search tasks, services…', style: TextStyle(color: AppColors.textHint.withOpacity(0.8), fontSize: 15)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Quick stats (if provider) ──────────────────────────────
                  if (userAsync.valueOrNull?.isProvider == true) ...[
                    _EarningsBanner(user: userAsync.valueOrNull),
                    const SizedBox(height: 24),
                  ],

                  // ── Category grid ──────────────────────────────────────────
                  const Text('Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  _CategoryGrid(),
                  const SizedBox(height: 24),

                  // ── Recent / Nearby tasks ─────────────────────────────────
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Nearby Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    TextButton(onPressed: () => context.go(AppRoutes.taskList), child: const Text('See all')),
                  ]),
                  const SizedBox(height: 12),
                  _NearbyTasksList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsBanner extends StatelessWidget {
  final dynamic user;
  const _EarningsBanner({this.user});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF0D5C47)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: AppRadius.card,
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Your Earnings', style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 4),
        Text('S\$${user?.stats?.earningsTotal.toStringAsFixed(2) ?? '0.00'}',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text('${user?.stats?.completedTasks ?? 0} tasks completed',
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ])),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary, minimumSize: const Size(80, 36)),
        onPressed: () {},
        child: const Text('Withdraw'),
      ),
    ]),
  );
}

class _CategoryGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GridView.count(
    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 5, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.75,
    children: AppCategories.all.map((cat) => GestureDetector(
      onTap: () => context.go('${AppRoutes.taskList}?category=${cat.id}'),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: cat.color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
          child: Center(child: Text(cat.emoji, style: const TextStyle(fontSize: 24))),
        ),
        const SizedBox(height: 4),
        Text(cat.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
    )).toList(),
  );
}

class _NearbyTasksList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real app, query Firestore for nearby tasks
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('Loading nearby tasks…', style: TextStyle(color: AppColors.textHint)),
      ),
    );
  }
}
