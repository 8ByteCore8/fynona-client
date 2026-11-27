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

  @override
  String get moreAccount => 'Account';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonCopied => 'Copied';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonDone => 'Done';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSave => 'Save';

  @override
  String commonSavedTo(String where) {
    return 'Saved: $where';
  }

  @override
  String get commonSaveFailed => 'Couldn\'t save the file';

  @override
  String get securitySessions => 'Sessions';

  @override
  String get securitySessionThisDevice => 'This device';

  @override
  String get securitySessionUnknownDevice => 'Unknown device';

  @override
  String securitySessionLastUsed(String date) {
    return 'last used $date';
  }

  @override
  String get securitySessionRevoke => 'End session';

  @override
  String get securitySessionsRevokeOthers => 'Sign out other devices';

  @override
  String get securitySessionsRevokeOthersConfirm =>
      'End every session but this one? Other devices will have to sign in again.';

  @override
  String get securityTotp => 'Two-factor authentication';

  @override
  String get securityTotpOff => 'Off';

  @override
  String get securityTotpOffHint =>
      'A code from an authenticator app at sign-in';

  @override
  String get securityTotpOn => 'On';

  @override
  String securityRecoveryCodesLeft(int count) {
    return 'Recovery codes left: $count';
  }

  @override
  String get securityTotpEnable => 'Turn on';

  @override
  String get securityTotpDisable => 'Turn off 2FA';

  @override
  String get securityTotpDisableConfirm =>
      'Sign-in will need only the password again. Confirm with a code from the app or your password.';

  @override
  String get securityTotpOrPassword => 'Or your password';

  @override
  String get securityTotpRegenerate => 'New recovery codes';

  @override
  String get securityTotpRegenerateHint =>
      'The old codes stop working. Enter a code from the app.';

  @override
  String get securityTotpCode => 'Code from the app';

  @override
  String get securityTotpCodeInvalid => 'Six digits';

  @override
  String get securityPasskeys => 'Passkeys';

  @override
  String get securityPasskeysEmpty => 'No passkeys yet';

  @override
  String get securityPasskeyAdd => 'Add a passkey';

  @override
  String get securityPasskeyName => 'Name, e.g. MacBook';

  @override
  String securityPasskeyCreated(String date) {
    return 'Added $date';
  }

  @override
  String securityPasskeyDeleteConfirm(String name) {
    return 'Delete the passkey “$name”? It will no longer sign you in.';
  }

  @override
  String get totpSetupTitle => 'Turn on 2FA';

  @override
  String get totpSetupScan =>
      'Scan the QR code with an authenticator app or enter the key by hand, then enter the code it shows.';

  @override
  String get totpSetupQrLabel => 'QR code for the authenticator app';

  @override
  String get totpSetupManualKey => 'Key for manual entry';

  @override
  String get recoveryCodesTitle => 'Recovery codes';

  @override
  String get recoveryCodesHint =>
      'Keep these codes somewhere safe: each one signs you in once without your phone. They will not be shown again.';

  @override
  String get accountProfile => 'Profile';

  @override
  String get accountDisplayName => 'Display name';

  @override
  String get accountLocale => 'Language';

  @override
  String get accountCurrency => 'Display currency';

  @override
  String get accountCurrencyInvalid => 'A three-letter currency code, e.g. UAH';

  @override
  String get accountSaved => 'Saved';

  @override
  String get accountConflict =>
      'The account changed elsewhere. It is reloaded; make your changes again.';

  @override
  String get accountEmail => 'Email';

  @override
  String accountEmailPending(String email) {
    return 'Awaiting confirmation: $email. Open the link in the email.';
  }

  @override
  String get accountEmailChange => 'Change email';

  @override
  String get accountEmailNew => 'New email';

  @override
  String get accountReauthHint =>
      'Confirm it\'s you: your password and, with 2FA on, a code or a recovery code.';

  @override
  String get accountReauthCode => '2FA code or recovery code';

  @override
  String get accountExport => 'Export your data';

  @override
  String get accountExportHint => 'An archive of all your data as JSON.';

  @override
  String get accountExportStart => 'Start export';

  @override
  String get accountExportPending => 'Preparing the archive…';

  @override
  String get accountExportReady => 'The archive is ready';

  @override
  String accountExportReadyUntil(String date) {
    return 'The archive is ready until $date';
  }

  @override
  String get accountExportDownload => 'Download';

  @override
  String get accountExportFailed => 'The export failed. Try again.';

  @override
  String get accountExportExpired =>
      'The archive is no longer available. Start a new export.';

  @override
  String get accountDanger => 'Account deletion';

  @override
  String get accountDelete => 'Delete account';

  @override
  String get accountDeleteWarning =>
      'The account and all its data are deleted for good. This cannot be undone.';

  @override
  String accountDeleteType(String email) {
    return 'To confirm, type $email';
  }

  @override
  String get languageUk => 'Українська';

  @override
  String get languageRu => 'Русский';

  @override
  String get languageEn => 'English';

  @override
  String subscriptionPlan(String name) {
    return 'Plan: $name';
  }

  @override
  String get subscriptionEntitlements => 'What\'s included';

  @override
  String get entitlementProfilesMax => 'Profiles';

  @override
  String get entitlementConnectionsMax => 'Connections';

  @override
  String get entitlementConnectorsBusiness => 'Business connectors';

  @override
  String get entitlementHistoryMonths => 'History, months';

  @override
  String get entitlementSyncMinInterval => 'Sync at most every';

  @override
  String get entitlementExports => 'Export formats';

  @override
  String get entitlementAiAnalyses => 'AI analyses per month';

  @override
  String get entitlementInvestmentsRebalance => 'Portfolio rebalancing';

  @override
  String get entitlementUnlimited => 'Unlimited';

  @override
  String get entitlementYes => 'Yes';

  @override
  String get entitlementNo => 'No';

  @override
  String entitlementMinutes(int count) {
    return '$count min';
  }

  @override
  String get planOfferTitle => 'Your plan\'s limit is reached';

  @override
  String planOfferMessage(String entitlement) {
    return 'Your plan has no more “$entitlement”. The plans below give more.';
  }

  @override
  String get planOfferMessageUnknown => 'This action is not part of your plan.';

  @override
  String get planOfferSeePlans => 'My plan';
}
