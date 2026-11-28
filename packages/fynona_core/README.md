# fynona_core

Pure Dart network core of the Fynona clients (no Flutter import; runs under `dart test`;
depends only on `dio`). It holds no API path and no generated model: each API client
(`fynona_api` for the public API, the admin client for its own) passes its routes and
rules. `test/no_api_paths_test.dart` fails on any real API path prefix in the package.

## Transport

`HttpTransport` gives a dio client with `ResilientAdapter`:

| Rule | Value |
|---|---|
| Headers | `X-Request-ID` (UUIDv7), `User-Agent: Fynona/<version> (<platform>)`, `X-Fynona-API: <declaredContractVersion>` (API-12); `Idempotency-Key` (UUIDv7) on POST/PUT/PATCH/DELETE unless `idempotencyExempt(method, uri)` says otherwise, reused on every retry |
| Retry (API-60, API-61) | GET and requests with `Idempotency-Key`; network errors, 408, 429, 502, 503, 504; `Retry-After` (seconds) wins, else full jitter base 200 ms, cap 10 s; at most 3 retries |
| Retry budget (API-62) | retries ≤ 10 % of primary requests in a 60 s window, reserve of 3 |
| Circuit breaker (API-63) | per group (first two path segments): opens above 50 % failures over ≥ 10 outcomes in 30 s; one probe after 15 s |
| Timeouts (API-64) | connect 10 s, read 30 s |

`idempotencyExempt` has no default: every consumer names the routes whose bodies carry
passwords or whose answers carry tokens. A request without the key is never retried.

`HttpTransport.call` throws typed `ApiException`s: `ApiProblemException` (a hand-written
`ProblemDetails`: `type`, `title`, `status`, `detail`, `code`, `request_id`, `errors[]`,
`update_url`, other members in `extensions`; API-30), `UpgradeRequiredException` (426),
`ApiHttpException`, `ApiNetworkException`, `CircuitOpenException`,
`ContractVersionException`. `classifyProblem` lets a consumer type its own codes (the
public client's `402 entitlement.exceeded`). `problems` emits every problem answer,
`contractRejections` every `426 api_version_unsupported`; `isOffline` and
`offlineChanges` report whether any breaker is not closed.

## Contract version (API-12)

`checkContract(readMeta, client:)` and `HttpTransport.checkContract(readMeta)` read the
API's meta route through the consumer's `readMeta` and return a `ContractCompatibility`:

| Verdict | When |
|---|---|
| `compatible` | same major, client ≥ `min_contract_version`, server minor ≥ client minor |
| `clientOutdated` | another major, client < `min_contract_version` (full SemVer), meta route 404 or 410, `426 api_version_unsupported` |
| `serverBehind` | same major, server minor < client minor (rollback or deploy in progress) |

## Session (SEC-2, SEC-4, SEC-5)

`AuthSession` runs over an `HttpTransport` with `AuthRoutes` (sign-in, second factor,
refresh, logout, optional passkey sign-in, further routes without `Authorization`, the
web refresh cookie name, and whether the sign-in body takes `token_delivery`). It parses
the token pair and the second-factor challenge itself (`AuthTokens`, `AuthChallenge`);
the public and admin specs give both the same shape. Rules: one refresh for parallel
`401`s, a refused refresh (any 4xx but 408, 426, 429) signs out, a refresh without a
connection keeps the session, a failing secret store ends signed out, logout with a
stale token renews it once first, and a `403` whose code is in
`revokingForbiddenCodes` signs out at once.

## Money

`WireDecimal` keeps the wire string and its scale; `wireDecimalFromJson` and
`wireDecimalToJson` are the codec of the generated models (swagger_parser
`type_mappings`). No `double` or `num` outside the resilience ratios
(`test/money_test.dart`).

```sh
dart test
```
