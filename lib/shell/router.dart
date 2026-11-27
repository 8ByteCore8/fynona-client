import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth.dart';
import '../screens/analytics_screen.dart';
import '../screens/auth/password_screens.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/more_screen.dart';
import '../screens/operations_screen.dart';
import '../screens/overview_screen.dart';
import 'app_shell.dart';

const overviewPath = '/overview';
const operationsPath = '/operations';
const analyticsPath = '/analytics';
const morePath = '/more';

const signInPath = '/sign-in';
const mfaPath = '/sign-in/mfa';
const signUpPath = '/sign-up';
const verifyPendingPath = '/sign-up/check-email';
const forgotPasswordPath = '/forgot-password';

/// Targets of the emailed links (`<app URL>/verify-email?token=…`,
/// `<app URL>/reset-password?token=…`); they work signed in or out.
const verifyEmailPath = '/verify-email';
const resetPasswordPath = '/reset-password';

/// Routes a signed-out user may see.
const authPaths = {
  signInPath,
  mfaPath,
  signUpPath,
  verifyPendingPath,
  forgotPasswordPath,
  verifyEmailPath,
  resetPasswordPath,
};

/// The guard (SEC-4): signed out, only [authPaths]; signed in, the shell
/// (plus the emailed link targets). While the saved session is being resumed
/// the location stays as it is, so a deep link survives a reload.
String? authRedirect(AuthState state, Uri location) {
  final path = location.path;
  final authRoute = authPaths.contains(path);
  return switch (state) {
    AuthState.unknown => null,
    AuthState.signedOut => authRoute ? null : signInPath,
    AuthState.signedIn =>
      authRoute && path != verifyEmailPath && path != resetPasswordPath
          ? overviewPath
          : null,
  };
}

/// One branch per top-level destination (CLI-10); each keeps its own stack
/// and scroll position. [auth] drives the guard ([authRedirect]).
GoRouter buildRouter({
  String initialLocation = overviewPath,
  required ValueListenable<AuthState> auth,
}) => GoRouter(
  initialLocation: initialLocation,
  refreshListenable: auth,
  redirect: (context, state) => authRedirect(auth.value, state.uri),
  routes: [
    GoRoute(
      path: signInPath,
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(path: mfaPath, builder: (context, state) => const MfaScreen()),
    GoRoute(
      path: signUpPath,
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: verifyPendingPath,
      builder: (context, state) => const VerifyPendingScreen(),
    ),
    GoRoute(
      path: forgotPasswordPath,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: verifyEmailPath,
      builder: (context, state) =>
          VerifyEmailScreen(token: state.uri.queryParameters['token']),
    ),
    GoRoute(
      path: resetPasswordPath,
      builder: (context, state) =>
          ResetPasswordScreen(token: state.uri.queryParameters['token']),
    ),
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
