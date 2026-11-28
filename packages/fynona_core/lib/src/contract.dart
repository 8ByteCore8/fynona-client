import 'errors.dart';

/// Request header that declares the contract version a client was built
/// against (API-12).
const contractVersionHeader = 'X-Fynona-API';

/// Problem code of the `426` for an unsupported declared contract version.
const apiVersionUnsupportedCode = 'api_version_unsupported';

/// A semantic version `MAJOR.MINOR.PATCH[-PRE][+BUILD]` (semver.org 2.0.0).
final class SemVer implements Comparable<SemVer> {
  const SemVer(this.major, this.minor, this.patch, {this.preRelease = ''});

  /// Parses [text]; throws [FormatException] when it is not SemVer.
  factory SemVer.parse(String text) {
    final match = _pattern.firstMatch(text);
    if (match == null) {
      throw FormatException('not a semantic version', text);
    }
    return SemVer(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
      preRelease: match[4] ?? '',
    );
  }

  static final _pattern = RegExp(
    r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)'
    r'(?:-((?:0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*)'
    r'(?:\.(?:0|[1-9]\d*|\d*[A-Za-z-][0-9A-Za-z-]*))*))?'
    r'(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$',
  );

  final int major;
  final int minor;
  final int patch;

  /// Dot-separated pre-release identifiers; empty for a release.
  final String preRelease;

  /// SemVer precedence: core numbers, then a pre-release before its release,
  /// then pre-release identifiers left to right (numeric below alphanumeric).
  @override
  int compareTo(SemVer other) {
    for (final (a, b) in [
      (major, other.major),
      (minor, other.minor),
      (patch, other.patch),
    ]) {
      if (a != b) return a.compareTo(b);
    }
    if (preRelease == other.preRelease) return 0;
    if (preRelease.isEmpty) return 1;
    if (other.preRelease.isEmpty) return -1;
    final mine = preRelease.split('.');
    final theirs = other.preRelease.split('.');
    for (var i = 0; i < mine.length && i < theirs.length; i++) {
      final order = _compareIdentifier(mine[i], theirs[i]);
      if (order != 0) return order;
    }
    return mine.length.compareTo(theirs.length);
  }

  static int _compareIdentifier(String a, String b) {
    final x = int.tryParse(a);
    final y = int.tryParse(b);
    if (x != null && y != null) return x.compareTo(y);
    if (x != null) return -1;
    if (y != null) return 1;
    return a.compareTo(b);
  }

  bool operator <(SemVer other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) => other is SemVer && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch, preRelease);

  @override
  String toString() =>
      '$major.$minor.$patch${preRelease.isEmpty ? '' : '-$preRelease'}';
}

/// How this client's contract relates to the server's (API-12).
enum ContractCompatibility {
  /// Same major, not below the minimum, server minor at least the client's.
  compatible,

  /// Another major or below the server's minimum: the app must be updated.
  clientOutdated,

  /// Same major but the server's minor is older: a rollback or a deploy is in
  /// progress; the app must wait, never ask for an update.
  serverBehind,
}

/// Decides compatibility from the versions of the API's meta route (API-12):
/// [client] is the version this app was built against, [server] is
/// `contract_version`, [minimum] is `min_contract_version`.
///
/// Throws [ContractVersionException] when a server version is not SemVer;
/// that is an error to report, not a reason to block the app.
ContractCompatibility checkCompatibility({
  required String client,
  required String server,
  required String minimum,
}) {
  final own = SemVer.parse(client);
  final served = _serverVersion(server);
  final lowest = _serverVersion(minimum);
  if (own.major != served.major || own < lowest) {
    return ContractCompatibility.clientOutdated;
  }
  if (served.minor < own.minor) return ContractCompatibility.serverBehind;
  return ContractCompatibility.compatible;
}

/// The versions an API's meta route serves (API-12).
typedef ContractMeta = ({String server, String minimum});

/// Reads the API's meta route with [readMeta] and decides whether contract
/// [client] works with the server (API-12). `404` or `410` on that route and
/// a `426` with code `api_version_unsupported` mean the client is outdated.
/// Other failures throw their [ApiException]; a server version that is not
/// SemVer throws [ContractVersionException]. [readMeta] reports failures as
/// [ApiException]s, e.g. by running through `HttpTransport.call`.
Future<ContractCompatibility> checkContract(
  Future<ContractMeta> Function() readMeta, {
  required String client,
}) async {
  try {
    final meta = await readMeta();
    return checkCompatibility(
      client: client,
      server: meta.server,
      minimum: meta.minimum,
    );
  } on UpgradeRequiredException catch (error) {
    if (error.code == apiVersionUnsupportedCode) {
      return ContractCompatibility.clientOutdated;
    }
    rethrow;
  } on ApiException catch (error) {
    final status = statusOf(error);
    if (status == 404 || status == 410) {
      return ContractCompatibility.clientOutdated;
    }
    rethrow;
  }
}

SemVer _serverVersion(String text) {
  try {
    return SemVer.parse(text);
  } on FormatException {
    throw ContractVersionException(text);
  }
}
