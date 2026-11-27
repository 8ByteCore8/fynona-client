import 'package:go_router/go_router.dart';

import '../screens/analytics_screen.dart';
import '../screens/more_screen.dart';
import '../screens/operations_screen.dart';
import '../screens/overview_screen.dart';
import 'app_shell.dart';

const overviewPath = '/overview';
const operationsPath = '/operations';
const analyticsPath = '/analytics';
const morePath = '/more';

/// One branch per top-level destination (CLI-10); each keeps its own stack
/// and scroll position.
GoRouter buildRouter({String initialLocation = overviewPath}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: overviewPath,
              builder: (context, state) => const OverviewScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: operationsPath,
              builder: (context, state) => const OperationsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: analyticsPath,
              builder: (context, state) => const AnalyticsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: morePath,
              builder: (context, state) => const MoreScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
