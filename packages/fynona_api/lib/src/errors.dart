import 'gen/exports.dart' show Problem;

/// Every failure of a call made through `ApiTransport.call`.
sealed class ApiException implements Exception {
  const ApiException();
}

/// The server answered with `application/problem+json` (API-30).
///
/// Branch on [code], never on [Problem.title].
class ApiProblemException extends ApiException {
  const ApiProblemException(this.problem, {this.retryAfter});

  final Problem problem;

  /// The wait asked for by a `Retry-After` header in seconds, if any.
  final Duration? retryAfter;

  /// Stable machine code, e.g. `rate_limited`.
  String get code => problem.code;

  /// Server trace id of the failed request (API-21).
  String get requestId => problem.requestId;

  int get status => problem.status;

  @override
  String toString() =>
      'ApiProblemException($status $code, request_id $requestId)';
}

/// `426 Upgrade Required`: the contract version declared in `X-Fynona-API` is
/// of another major or below the server's minimum (code
/// `api_version_unsupported`, API-12). [updateUrl] says where to get a
/// supported build.
final class UpgradeRequiredException extends ApiProblemException {
  const UpgradeRequiredException(super.problem, {super.retryAfter});

  String? get updateUrl => problem.updateUrl;
}

/// Problem code of an action over the caller's plan (MON-4).
const entitlementExceededCode = 'entitlement.exceeded';

/// `402 Payment Required` with code `entitlement.exceeded`: the action is
/// over the caller's plan (MON-4). The server decides; the client only offers
/// a plan that has more of [entitlement].
final class EntitlementExceededException extends ApiProblemException {
  const EntitlementExceededException(super.problem, {super.retryAfter});

  /// The exceeded entitlement, e.g. `connections.max`; null when the server
  /// did not name it.
  String? get entitlement => problem.entitlement;
}

/// An HTTP error without a parseable problem body.
final class ApiHttpException extends ApiException {
  const ApiHttpException(this.status, {this.requestId, this.retryAfter});

  final int status;

  /// The wait asked for by a `Retry-After` header in seconds, if any.
  final Duration? retryAfter;

  /// `X-Request-ID` of the response, when present.
  final String? requestId;

  @override
  String toString() => 'ApiHttpException($status, request_id $requestId)';
}

/// The request did not reach the server or its answer did not arrive:
/// connection failure or timeout (API-64).
final class ApiNetworkException extends ApiException {
  const ApiNetworkException(this.cause);

  final Object cause;

  @override
  String toString() => 'ApiNetworkException($cause)';
}

/// A contract version in `GET /v1/meta` is not SemVer (API-12): an error to
/// report, not a reason to block the app.
final class ContractVersionException extends ApiException {
  const ContractVersionException(this.value);

  final String value;

  @override
  String toString() => 'ContractVersionException($value is not SemVer)';
}

/// The circuit breaker of [group] is open: the call failed without being
/// sent (API-63).
final class CircuitOpenException extends ApiException {
  const CircuitOpenException(this.group);

  final String group;

  @override
  String toString() => 'CircuitOpenException($group)';
}
