/// Passkey sign-in runs only in the browser in this release (SEC-1); mobile
/// passkeys come later.
bool get passkeysSupported => false;

/// Never called where [passkeysSupported] is false.
Future<Map<String, Object?>> getPasskeyAssertion(
  Map<String, Object?> options,
) => throw UnsupportedError('passkeys need a browser');

/// Never called where [passkeysSupported] is false.
Future<Map<String, Object?>> createPasskey(Map<String, Object?> options) =>
    throw UnsupportedError('passkeys need a browser');
