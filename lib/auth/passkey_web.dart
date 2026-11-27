import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

JSObject? get _publicKeyCredential =>
    globalContext['PublicKeyCredential'] as JSObject?;

/// Whether the browser can run a WebAuthn ceremony from JSON options
/// (`PublicKeyCredential.parseRequestOptionsFromJSON`).
bool get passkeysSupported =>
    _publicKeyCredential?.has('parseRequestOptionsFromJSON') ?? false;

/// Runs `navigator.credentials.get()` with the server's ceremony [options]
/// (binary members in base64url) and returns the assertion as JSON
/// (`PublicKeyCredential.toJSON()`). Throws when the user cancels.
Future<Map<String, Object?>> getPasskeyAssertion(
  Map<String, Object?> options,
) async {
  final publicKey = _publicKeyCredential!.callMethod<JSObject>(
    'parseRequestOptionsFromJSON'.toJS,
    options['publicKey'].jsify(),
  );
  final request = JSObject()..['publicKey'] = publicKey;
  final credential = await web.window.navigator.credentials
      .get(request as web.CredentialRequestOptions)
      .toDart;
  if (credential == null) throw StateError('no passkey was chosen');
  return _toJson(credential);
}

/// Runs `navigator.credentials.create()` with the server's registration
/// [options] and returns the new credential as JSON. Throws when the user
/// cancels.
Future<Map<String, Object?>> createPasskey(Map<String, Object?> options) async {
  final publicKey = _publicKeyCredential!.callMethod<JSObject>(
    'parseCreationOptionsFromJSON'.toJS,
    options['publicKey'].jsify(),
  );
  final request = JSObject()..['publicKey'] = publicKey;
  final credential = await web.window.navigator.credentials
      .create(request as web.CredentialCreationOptions)
      .toDart;
  if (credential == null) throw StateError('no passkey was created');
  return _toJson(credential);
}

Map<String, Object?> _toJson(web.Credential credential) {
  final json = (credential as JSObject).callMethod<JSObject>('toJSON'.toJS);
  return Map<String, Object?>.from(json.dartify()! as Map);
}
