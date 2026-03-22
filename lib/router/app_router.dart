import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home/home_shell.dart';
import '../screens/home/tasks_screen.dart';
import '../screens/home/profile_screen.dart';
import '../screens/onboarding/onboarding_gate_screen.dart';
import '../screens/onboarding/onboarding_flow.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/task/add_task_screen.dart';
import '../screens/task/edit_task_screen.dart';
import '../screens/task/import_tasks_screen.dart';
import '../screens/timer/timer_screen.dart';
import '../screens/celebration/celebration_screen.dart';
import '../screens/groups/groups_screen.dart';
import '../screens/groups/leaderboard_screen.dart';
import '../screens/groups/group_detail_screen.dart';
import '../screens/groups/add_group_task_screen.dart';
import '../screens/premium/premium_screen.dart';
import '../models/task.dart';
import '../models/group.dart';
import '../models/group_member.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthNotifier authNotifier) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isOnAuth = state.matchedLocation.startsWith('/auth');
      final isOnSplash = state.matchedLocation == '/splash';

      if (session == null) {
        if (isOnAuth) return null;
        return '/auth/login';
      }

      if (isOnAuth || isOnSplash) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingFlow(),
      ),
      GoRoute(
        path: '/add-task',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddTaskScreen(),
      ),
      GoRoute(
        path: '/import-tasks',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ImportTasksScreen(),
      ),
      GoRoute(
        path: '/edit-task',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => EditTaskScreen(task: state.extra! as Task),
      ),
      GoRoute(
        path: '/timer',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => TimerScreen(task: state.extra! as Task),
      ),
      GoRoute(
        path: '/celebration',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final data = state.extra! as Map<String, dynamic>;
          return CelebrationScreen(
            taskName: data['taskName'] as String,
            points: data['points'] as int,
            timeSpent: data['timeSpent'] as int,
            newMilestones: (data['newMilestones'] as List<int>?) ?? const [],
          );
        },
      ),
      GoRoute(
        path: '/groups',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const GroupsScreen(),
      ),
      GoRoute(
        path: '/premium',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PremiumScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            LeaderboardScreen(group: state.extra! as Group),
      ),
      GoRoute(
        path: '/group-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            GroupDetailScreen(group: state.extra! as Group),
      ),
      GoRoute(
        path: '/add-group-task',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final data = state.extra! as Map<String, dynamic>;
          return AddGroupTaskScreen(
            groupId: data['groupId'] as String,
            members: data['members'] as List<GroupMember>,
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const OnboardingGateScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tasks',
                builder: (context, state) => const TasksScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
