import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fynona/api/api.dart';
import 'package:fynona_api/fynona_api.dart' hide Locale, Theme;

/// Answers every request with [respond] and counts the requests.
final class ScriptedAdapter implements HttpClientAdapter {
  ScriptedAdapter(this.respond);

  ResponseBody Function(RequestOptions options) respond;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

/// `GET /v1/meta` of a server with contract [server] and [minimum].
ResponseBody Function(RequestOptions) meta({
  String server = contractVersion,
  String minimum = '1.0.0',
}) =>
    (_) => ResponseBody.fromString(
      jsonEncode({
        'server_version': '0.1.0',
        'api_version': 'v1',
        'contract_version': server,
        'min_contract_version': minimum,
        'environment': 'sandbox',
        'features': <String, bool>{},
        'update_url': 'https://fynona.app/download',
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

/// A problem response with [status] and [code].
ResponseBody Function(RequestOptions) problem(int status, String code) =>
    (_) => ResponseBody.fromString(
      jsonEncode({
        'type': 'urn:fynona:problem:$code',
        'title': 'Problem',
        'status': status,
        'code': code,
        'request_id': 'req-$status',
      }),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/problem+json'],
      },
    );

/// The app's transport over [adapter], without real waiting between retries.
/// [declared] stands in for the contract version the build was made against.
ApiTransport fakeApiTransport(
  HttpClientAdapter adapter, {
  String declared = contractVersion,
}) => ApiTransport(
  baseUrl: 'https://api.test',
  clientVersion: clientVersion,
  platform: 'linux',
  declaredContractVersion: declared,
  adapter: adapter,
  sleep: (_) async {},
);
