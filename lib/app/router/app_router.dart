import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:focus_flow/features/focus_mode/presentation/pages/focus_page.dart';
import 'package:focus_flow/features/stats/presentation/screens/dashboard_screen.dart';
import 'package:focus_flow/features/session_history/presentation/pages/session_history_page.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const FocusPage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) {
        final filterDate = state.extra as DateTime?;
        return SessionHistoryPage(filterDate: filterDate);
      },
    ),
  ],
);
