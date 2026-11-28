/// Fynona network core shared by every Fynona API client: the resilient
/// transport (API-20, API-21, API-60…API-64), typed errors and problem
/// details (API-30), the contract check (API-12), the sign-in session
/// (SEC-2, SEC-4, SEC-5) and the wire decimal (API-5). No API path and no
/// generated model: each API client passes its own routes and rules.
library;

export 'src/auth.dart';
export 'src/circuit_breaker.dart';
export 'src/contract.dart';
export 'src/decimal.dart';
export 'src/errors.dart';
export 'src/problem.dart';
export 'src/retry.dart';
export 'src/transport.dart';
export 'src/uuid.dart';
