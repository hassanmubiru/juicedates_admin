import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import 'dashboard_screen.dart';
import 'users_screen.dart';
import 'reports_screen.dart';
import 'moments_screen.dart';
import 'notifications_screen.dart';
import 'winks_screen.dart';
import 'matches_screen.dart';
import 'analytics_screen.dart';
import 'subscriptions_screen.dart';
import 'content_moderation_screen.dart';
import 'app_config_screen.dart';
import 'fake_profiles_screen.dart';
import 'revenue_screen.dart';

const _navItems = [
  (icon: Icons.dashboard_rounded,         label: 'Dashboard'),
  (icon: Icons.people_rounded,            label: 'Users'),
  (icon: Icons.favorite_rounded,          label: 'Matches'),
  (icon: Icons.bar_chart_rounded,         label: 'Analytics'),
  (icon: Icons.star_rounded,              label: 'Subscriptions'),
  (icon: Icons.flag_rounded,              label: 'Reports'),
  (icon: Icons.auto_stories_rounded,      label: 'Moments'),
  (icon: Icons.waving_hand_rounded,       label: 'Winks'),
  (icon: Icons.shield_rounded,            label: 'Moderation'),
  (icon: Icons.notifications_rounded,     label: 'Notifications'),
  (icon: Icons.settings_rounded,          label: 'App Config'),
  (icon: Icons.gpp_bad_rounded,           label: 'Fake Profiles'),
  (icon: Icons.attach_money_rounded,      label: 'Revenue'),
];

const _kSidebarWidth = 220.0;
const _kRailWidth    = 72.0;
const _kBreakpoint   = 900.0;

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  final _screens = const [
    DashboardScreen(),
    UsersScreen(),
    MatchesScreen(),
    AnalyticsScreen(),
    SubscriptionsScreen(),
    ReportsScreen(),
    MomentsScreen(),
    WinksScreen(),
    ContentModerationScreen(),
    NotificationsScreen(),
    AppConfigScreen(),
    FakeProfilesScreen(),
    RevenueScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final wide  = width >= _kBreakpoint;

    return Scaffold(
      backgroundColor: kDarkBg,
      body: Row(
        children: [
          // ── Sidebar / rail ───────────────────────────────────────────
          if (wide) _FullSidebar(index: _index, onTap: (i) => setState(() => _index = i))
          else       _RailSidebar(index: _index, onTap: (i) => setState(() => _index = i)),

          // ── Content ──────────────────────────────────────────────────
          Expanded(child: _screens[_index]),
        ],
      ),
    );
  }
}

// ── Full sidebar (wide screens) ───────────────────────────────────────────
class _FullSidebar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _FullSidebar({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kSidebarWidth,
      color: kSidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kTangerine,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('JuiceDates',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    Text('Admin Panel',
                        style: TextStyle(color: kMuted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: kBorder, height: 1),
          const SizedBox(height: 12),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _navItems.length,
              itemBuilder: (_, i) {
                final item    = _navItems[i];
                final active  = i == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    tileColor:
                        active ? kTangerine.withValues(alpha: 0.15) : Colors.transparent,
                    selectedTileColor: kTangerine.withValues(alpha: 0.15),
                    leading: Icon(item.icon,
                        color: active ? kTangerine : kMuted, size: 20),
                    title: Text(item.label,
                        style: TextStyle(
                            color: active ? kTangerine : Colors.white,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 14)),
                    selected: active,
                    onTap: () => onTap(i),
                  ),
                );
              },
            ),
          ),

          // Sign out
          const Divider(color: kBorder, height: 1),
          Padding(
            padding: const EdgeInsets.all(10),
            child: ListTile(
              dense: true,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              leading: const Icon(Icons.logout_rounded, color: kMuted, size: 20),
              title: const Text('Sign Out',
                  style: TextStyle(color: kMuted, fontSize: 14)),
              onTap: () => FirebaseAuth.instance.signOut(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Icon rail (narrow screens) ────────────────────────────────────────────
class _RailSidebar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _RailSidebar({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      backgroundColor: kSidebar,
      selectedIndex: index,
      onDestinationSelected: onTap,
      minWidth: _kRailWidth,
      useIndicator: true,
      indicatorColor: kTangerine.withValues(alpha: 0.2),
      selectedIconTheme: const IconThemeData(color: kTangerine),
      unselectedIconTheme: const IconThemeData(color: kMuted),
      destinations: [
        for (final item in _navItems)
          NavigationRailDestination(
            icon: Icon(item.icon),
            label: Text(item.label,
                style: const TextStyle(fontSize: 10)),
          ),
      ],
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: kMuted),
              tooltip: 'Sign Out',
              onPressed: () => FirebaseAuth.instance.signOut(),
            ),
          ),
        ),
      ),
    );
  }
}
