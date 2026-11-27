import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynona/api/api.dart';
import 'package:fynona/shell/connection_banner.dart';
import 'package:fynona_api/fynona_api.dart' hide Locale, Theme;

import 'support/harness.dart';

/// Refuses every connection.
final class _DownAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => throw DioException.connectionError(
    requestOptions: options,
    reason: 'test: server down',
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  testWidgets('the shell shows «no connection» once a breaker opens', (
    tester,
  ) async {
    final transport = ApiTransport(
      baseUrl: 'https://api.test',
      clientVersion: clientVersion,
      platform: 'linux',
      adapter: _DownAdapter(),
      sleep: (_) async {},
    );
    await pumpApp(tester, transport: transport);
    expect(find.byKey(connectionBannerKey), findsNothing);

    await tester.runAsync(() async {
      while (!transport.isOffline) {
        await expectLater(
          transport.call((api) => api.meta.getMeta()),
          throwsA(isA<ApiNetworkException>()),
        );
      }
    });
    await tester.pumpAndSettle();

    expect(find.byKey(connectionBannerKey), findsOneWidget);
    expect(find.text('Немає звʼязку з сервером'), findsOneWidget);
  });

  test('clientVersion equals the pubspec version', () {
    final version = RegExp(
      r'^version: ([^+\s]+)',
      multiLine: true,
    ).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1);
    expect(clientVersion, version);
  });
}
