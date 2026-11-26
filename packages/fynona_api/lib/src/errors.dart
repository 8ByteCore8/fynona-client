import 'gen/exports.dart' show Problem;

/// Every failure of a call made through `ApiTransport.call`.
sealed class ApiException implements Exception {
  const ApiException();
}

/// The server answered with `application/problem+json` (API-30).
///
/// Branch on [code], never on [Problem.title].
class ApiProblemException extends ApiException {
  const ApiProblemException(this.problem);

  final Problem problem;

  /// Stable machine code, e.g. `rate_limited`.
  String get code => problem.code;

  /// Server trace id of the failed request (API-21).
  String get requestId => problem.requestId;

  int get status => problem.status;

  @override
  String toString() =>
      'ApiProblemException($status $code, request_id $requestId)';
}

/// `426 Upgrade Required`: this client is older than the server's minimum for
/// its platform (API-12). [updateUrl] says where to get a supported build.
final class UpgradeRequiredException extends ApiProblemException {
  const UpgradeRequiredException(super.problem);

  String? get updateUrl => problem.updateUrl;
}

/// An HTTP error without a parseable problem body.
final class ApiHttpException extends ApiException {
  const ApiHttpException(this.status, {this.requestId});

  final int status;

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

/// The circuit breaker of [group] is open: the call failed without being
/// sent (API-63).
final class CircuitOpenException extends ApiException {
  const CircuitOpenException(this.group);

  final String group;

  @override
  String toString() => 'CircuitOpenException($group)';
}
