// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Fynona';

  @override
  String get navOverview => 'Overview';

  @override
  String get navOperations => 'Operations';

  @override
  String get navAnalytics => 'Analytics';

  @override
  String get navMore => 'More';

  @override
  String get navLandmark => 'Main navigation';

  @override
  String get profileAll => 'All profiles';

  @override
  String get profilePlaceholderPersonal => 'Personal';

  @override
  String get profilePlaceholderBusiness => 'Sole proprietor';

  @override
  String profileSwitcherLabel(String name) {
    return 'Profile: $name. Change profile';
  }

  @override
  String get profileSheetTitle => 'Profile';

  @override
  String get operationsSummary => 'All accounts · This month';

  @override
  String operationsPlaceholderTitle(int number) {
    return 'Operation $number';
  }

  @override
  String get operationsPlaceholderSubtitle => 'Demo data';

  @override
  String get overviewPlaceholder =>
      'Balance, recent operations and widgets will appear here.';

  @override
  String get analyticsPlaceholder => 'Charts and reports will appear here.';

  @override
  String get moreProfiles => 'Profiles';

  @override
  String get moreConnections => 'Connections and accounts';

  @override
  String get moreCategories => 'Categories and rules';

  @override
  String get moreReconciliation => 'Reconciliation';

  @override
  String get moreInvestments => 'Investments';

  @override
  String get moreExports => 'Exports';

  @override
  String get moreSubscription => 'Subscription';

  @override
  String get moreSecurity => 'Security';

  @override
  String get moreAbout => 'About';

  @override
  String get moreAppearance => 'Appearance';

  @override
  String get settingsNoGlass => 'No glass';

  @override
  String get settingsNoGlassHint => 'Opaque bars instead of blur';

  @override
  String get settingsHighContrast => 'High contrast';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get connectionLost => 'No connection to the server';

  @override
  String get appOutdatedTitle => 'The app is out of date';

  @override
  String get appOutdatedMessage => 'Update the app to keep using it.';

  @override
  String get appOutdatedReload => 'Reload';

  @override
  String get serverBehindTitle => 'The service is updating';

  @override
  String get serverBehindMessage => 'Please try again later.';

  @override
  String get serverBehindRetry => 'Try again';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authNewPassword => 'New password (at least 8 characters)';

  @override
  String get authSignInTitle => 'Sign in';

  @override
  String get authSignInAction => 'Sign in';

  @override
  String get authSignUpTitle => 'Create an account';

  @override
  String get authSignUpAction => 'Sign up';

  @override
  String get authToSignUp => 'No account? Sign up';

  @override
  String get authToSignIn => 'Have an account? Sign in';

  @override
  String get authBackToSignIn => 'Back to sign in';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authPasskeySignIn => 'Sign in with a passkey';

  @override
  String get authPasskeyFailed => 'Could not sign in with a passkey';

  @override
  String get authInvalidCredentials => 'Wrong email or password';

  @override
  String get authEmailUnverified =>
      'Confirm your email with the link we sent first';

  @override
  String get authAccountBlocked => 'This account is blocked. Contact support';

  @override
  String get authRateLimited => 'Too many attempts. Try again later';

  @override
  String get authNetworkError => 'No connection to the server. Try again';

  @override
  String get authUnknownError => 'Something went wrong. Try again';

  @override
  String get authEmailInvalid => 'Enter an email address';

  @override
  String get authPasswordRequired => 'Enter your password';

  @override
  String get authPasswordTooShort => 'At least 8 characters';

  @override
  String get authVerifyPendingTitle => 'Check your email';

  @override
  String authVerifyPendingMessage(String email) {
    return 'We sent an email to $email. Follow its link to finish signing up.';
  }

  @override
  String get authVerifyPendingHint =>
      'No email? Check your inbox and spam folder, or go back and sign up again.';

  @override
  String get authSignUpAgain => 'Sign up again';

  @override
  String get authVerifyTitle => 'Email confirmation';

  @override
  String get authVerifyDone => 'Your email is confirmed. You can sign in now';

  @override
  String get authLinkInvalid => 'This link is invalid or has expired';

  @override
  String get authForgotTitle => 'Reset your password';

  @override
  String get authForgotSend => 'Send link';

  @override
  String get authForgotSent =>
      'If an account with this email exists, we sent it a link to set a new password.';

  @override
  String get authResetTitle => 'New password';

  @override
  String get authResetAction => 'Save password';

  @override
  String get authResetDone =>
      'Your password is changed. Sign in with the new one';

  @override
  String get authMfaTitle => 'Two-step verification';

  @override
  String get authMfaCode => 'Code from your authenticator app';

  @override
  String get authMfaRecoveryCode => 'Recovery code';

  @override
  String get authMfaUseRecovery => 'Use a recovery code';

  @override
  String get authMfaUseCode => 'Use an authenticator code';

  @override
  String get authMfaCodeInvalid => 'Enter 6 digits';

  @override
  String get authMfaInvalid => 'Wrong code';

  @override
  String get authMfaExpired => 'Time is up. Sign in again';

  @override
  String get authMfaAction => 'Confirm';

  @override
  String get authLoading => 'Restoring your session';

  @override
  String get authSignOut => 'Sign out';
}
