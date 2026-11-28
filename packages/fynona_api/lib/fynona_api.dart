/// Fynona public API client: generated models and endpoint clients
/// (swagger_parser 2.4.0 from `api/openapi.yaml`, ADR-001) and the public
/// routes and rules over the shared network core `fynona_core`, whose public
/// API this library re-exports. Its session types are replaced by the public
/// [AuthSession], which works with the generated models.
library;

export 'package:fynona_core/fynona_core.dart'
    hide AuthSession, AuthSignedIn, AuthMfaRequired, AuthLoginOutcome;

export 'src/account.dart';
export 'src/auth.dart';
export 'src/contract.dart';
export 'src/errors.dart';
export 'src/gen/fynona_api.dart';
export 'src/transport.dart';
