import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/agent/agent_home_screen.dart';
import '../../features/agent/agent_profile_screen.dart';
import '../../features/chef/chef_home_screen.dart';
import '../../features/chef/screens/select_site_screen.dart';
import '../../features/chef/screens/compose_team_screen.dart';
import '../../features/chef/screens/pointage_screen.dart';
import '../../features/chef/screens/rate_agents_screen.dart';
import '../../features/chef/screens/transfers_screen.dart';
import '../../features/chef/screens/report_incident_screen.dart';
import '../../features/chef/screens/site_tasks_screen.dart';
import '../../features/chef/screens/close_report_screen.dart';
import '../../features/chef/repositories/sites_repository.dart';
import '../../features/magasinier/magasinier_home_screen.dart';
import '../../features/magasinier/screens/material_out_screen.dart';
import '../../features/magasinier/screens/material_return_screen.dart';
import '../../features/comptable/comptable_home_screen.dart';
import '../../features/comptable/screens/period_detail_screen.dart';
import '../../features/admin/admin_home_screen.dart';
import '../../features/admin/screens/create_user_screen.dart';
import '../../features/admin/screens/create_site_screen.dart';
import '../../features/admin/screens/users_list_screen.dart';
import '../../features/shared/ranking_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/agent',
        builder: (_, __) => const AgentHomeScreen(),
        routes: [
          GoRoute(path: 'ranking', builder: (_, __) => const RankingScreen()),
          GoRoute(path: 'profile', builder: (_, __) => const AgentProfileScreen()),
        ],
      ),
      GoRoute(
        path: '/chef',
        builder: (_, __) => const ChefHomeScreen(),
        routes: [
          GoRoute(path: 'select-site', builder: (_, __) => const SelectSiteScreen()),
          GoRoute(
            path: 'compose/:siteId',
            builder: (_, state) => ComposeTeamScreen(
              siteId: state.pathParameters['siteId']!,
              site: state.extra as SiteModel?,
            ),
          ),
          GoRoute(
            path: 'pointage/:siteId',
            builder: (_, state) => PointageScreen(
              siteId: state.pathParameters['siteId']!,
              site: state.extra as SiteModel?,
            ),
          ),
          GoRoute(
            path: 'ranking',
            builder: (_, __) => const RankingScreen(),
          ),
          GoRoute(
            path: 'transfers',
            builder: (_, __) => const TransfersScreen(),
          ),
          GoRoute(
            path: 'incident',
            builder: (_, __) => const ReportIncidentScreen(),
          ),
          GoRoute(
            path: 'tasks/:siteId',
            builder: (_, state) => SiteTasksScreen(
              siteId: state.pathParameters['siteId']!,
              site: state.extra as SiteModel?,
            ),
          ),
          GoRoute(
            path: 'report/:siteId',
            builder: (_, state) => CloseReportScreen(
              siteId: state.pathParameters['siteId']!,
              site: state.extra as SiteModel?,
            ),
          ),
          GoRoute(
            path: 'rate/:siteId',
            builder: (_, state) => RateAgentsScreen(
              siteId: state.pathParameters['siteId']!,
              site: state.extra as SiteModel?,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/magasinier',
        builder: (_, __) => const MagasinierHomeScreen(),
        routes: [
          GoRoute(path: 'out', builder: (_, __) => const MaterialOutScreen()),
          GoRoute(path: 'return', builder: (_, __) => const MaterialReturnScreen()),
          GoRoute(
            path: 'catalog',
            builder: (_, __) => const _PlaceholderScreen(title: 'Catalogue'),
          ),
          GoRoute(
            path: 'alerts',
            builder: (_, __) => const _PlaceholderScreen(title: 'Alertes véhicules'),
          ),
        ],
      ),
      GoRoute(
        path: '/comptable',
        builder: (_, __) => const ComptableHomeScreen(),
        routes: [
          GoRoute(
            path: 'period/:id',
            builder: (_, state) => PeriodDetailScreen(
              periodId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminHomeScreen(),
        routes: [
          GoRoute(path: 'users', builder: (_, __) => const UsersListScreen()),
          GoRoute(
            path: 'users/create',
            builder: (_, __) => const CreateUserScreen(),
          ),
          GoRoute(
            path: 'sites/create',
            builder: (_, __) => const CreateSiteScreen(),
          ),
          GoRoute(
            path: 'sites',
            builder: (_, __) => const SelectSiteScreen(),
          ),
          GoRoute(
            path: 'ranking',
            builder: (_, __) =>
                const RankingScreen(),
          ),
        ],
      ),
    ],
  );
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Text('Écran $title — à venir'),
      ),
    );
  }
}
