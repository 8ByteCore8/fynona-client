import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'gen/fynona_api.dart';
import 'transport.dart';

/// A resource as read and its `ETag`, the version to send back in
/// `If-Match` (API-23).
final class Versioned<T> {
  const Versioned(this.value, this.etag);

  final T value;

  /// The `ETag` header of the answer; null when the server sent none.
  final String? etag;
}

/// Account calls that need the `ETag` of `/v1/me` (API-23) or the raw bytes
/// of an export, which the generated client does not expose.
extension AccountCalls on ApiTransport {
  /// `GET /v1/me` with its version.
  Future<Versioned<Profile>> getProfile() =>
      _profile((dio) => dio.get<Object?>('/v1/me'));

  /// `PATCH /v1/me` against the version [etag] (`412 precondition.failed`
  /// when the account changed since).
  Future<Versioned<Profile>> updateProfile(
    ProfileUpdate update, {
    required String? etag,
  }) => _profile(
    (dio) => dio.patch<Object?>(
      '/v1/me',
      data: update.toJson(),
      options: Options(headers: {'If-Match': ?etag}),
    ),
  );

  /// `POST /v1/me/email`: the new address becomes `pending_email` until its
  /// link is followed (SEC-3). Needs re-authentication in [request].
  Future<Versioned<Profile>> changeEmail(
    EmailChangeRequest request, {
    required String? etag,
  }) => _profile(
    (dio) => dio.post<Object?>(
      '/v1/me/email',
      data: request.toJson(),
      options: Options(headers: {'If-Match': ?etag}),
    ),
  );

  /// The JSON archive of a ready export, as the server sent it (SEC-60).
  Future<Uint8List> downloadExportArchive(String id) => call((_) async {
    final response = await dio.get<List<int>>(
      '/v1/me/export/${Uri.encodeComponent(id)}/archive',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const []);
  });

  Future<Versioned<Profile>> _profile(
    Future<Response<Object?>> Function(Dio dio) request,
  ) => call((_) async {
    final response = await request(dio);
    return Versioned(
      Profile.fromJson(response.data! as Map<String, Object?>),
      response.headers.value('etag'),
    );
  });
}
