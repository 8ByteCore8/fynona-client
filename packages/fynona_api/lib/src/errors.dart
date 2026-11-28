import 'package:fynona_core/fynona_core.dart';

/// Problem code of an action over the caller's plan (MON-4).
const entitlementExceededCode = 'entitlement.exceeded';

/// `402 Payment Required` with code `entitlement.exceeded`: the action is
/// over the caller's plan (MON-4). The server decides; the client only offers
/// a plan that has more of [entitlement].
final class EntitlementExceededException extends ApiProblemException {
  const EntitlementExceededException(super.problem, {super.retryAfter});

  /// The exceeded entitlement, e.g. `connections.max`; null when the server
  /// did not name it.
  String? get entitlement => switch (problem.extensions['entitlement']) {
    final String name => name,
    _ => null,
  };
}

/// The public API's own problem types for [HttpTransport]: a `402` with
/// code `entitlement.exceeded` is an [EntitlementExceededException].
ApiProblemException? classifyPublicProblem(
  int status,
  ProblemDetails problem,
  Duration? retryAfter,
) => status == 402 && problem.code == entitlementExceededCode
    ? EntitlementExceededException(problem, retryAfter: retryAfter)
    : null;
