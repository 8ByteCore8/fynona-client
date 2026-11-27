import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fynona_api/fynona_api.dart' hide Locale, Theme;

import 'api.dart';

/// Whether this build's API contract works with the server (API-12).
///
/// Starts optimistic as [ContractCompatibility.compatible] and checks
/// `GET /v1/meta` right away; the app checks again on every resume
/// ([ContractStatus.check]). Any `426 api_version_unsupported` from the
/// transport turns it into [ContractCompatibility.clientOutdated]. A failed
/// check (no connection, server error, a version that is not SemVer) keeps
/// the last verdict: it is not a reason to block the app.
final contractStatusProvider =
    NotifierProvider<ContractStatus, ContractCompatibility>(ContractStatus.new);

class ContractStatus extends Notifier<ContractCompatibility> {
  @override
  ContractCompatibility build() {
    final transport = ref.watch(apiTransportProvider);
    final rejections = transport.contractRejections.listen(
      (_) => state = ContractCompatibility.clientOutdated,
    );
    ref.onDispose(rejections.cancel);
    scheduleMicrotask(check);
    return ContractCompatibility.compatible;
  }

  /// Reads the server's contract versions and updates the verdict.
  Future<void> check() async {
    final transport = ref.read(apiTransportProvider);
    try {
      final verdict = await transport.checkContract();
      if (ref.mounted) state = verdict;
    } on ApiException {
      // No verdict: keep the last one (see contractStatusProvider).
    }
  }
}
