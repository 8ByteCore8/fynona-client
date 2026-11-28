/// RFC 9457 problem details as every Fynona API sends them (API-30).
library;

/// One field of a request that failed validation: an element of `errors`.
final class ProblemFieldError {
  const ProblemFieldError({
    required this.field,
    required this.code,
    required this.detail,
  });

  /// Throws a [FormatException] when a member is missing or of another type.
  factory ProblemFieldError.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw FormatException('A field error must be an object', json);
    }
    return ProblemFieldError(
      field: _string(json, 'field'),
      code: _string(json, 'code'),
      detail: _string(json, 'detail'),
    );
  }

  /// Parameter name or JSON Pointer into the request body.
  final String field;
  final String code;
  final String detail;
}

/// An `application/problem+json` body: `type`, `title`, `status`, `detail`,
/// the stable machine `code`, `request_id` and `errors` (API-30), plus
/// `update_url` of a `426` (API-12). Every other member stays in
/// [extensions]. Branch on [code], never on [title].
final class ProblemDetails {
  const ProblemDetails({
    required this.type,
    required this.title,
    required this.status,
    this.detail,
    required this.code,
    required this.requestId,
    this.errors,
    this.updateUrl,
    this.extensions = const {},
  });

  /// Throws a [FormatException] when a required member is missing or a
  /// member is of another type.
  factory ProblemDetails.fromJson(Map<String, Object?> json) {
    final errors = json['errors'];
    if (errors != null && errors is! List<Object?>) {
      throw FormatException('errors must be an array', errors);
    }
    return ProblemDetails(
      type: _string(json, 'type'),
      title: _string(json, 'title'),
      status: _int(json, 'status'),
      detail: _optionalString(json, 'detail'),
      code: _string(json, 'code'),
      requestId: _string(json, 'request_id'),
      errors: errors == null
          ? null
          : [
              for (final item in errors as List<Object?>)
                ProblemFieldError.fromJson(item),
            ],
      updateUrl: _optionalString(json, 'update_url'),
      extensions: {
        for (final entry in json.entries)
          if (!_knownKeys.contains(entry.key)) entry.key: entry.value,
      },
    );
  }

  static const _knownKeys = {
    'type',
    'title',
    'status',
    'detail',
    'code',
    'request_id',
    'errors',
    'update_url',
  };

  /// `urn:fynona:problem:<code>`.
  final String type;

  /// Localized text for people; never branched on.
  final String title;
  final int status;
  final String? detail;

  /// Stable machine code, e.g. `rate_limited`.
  final String code;

  /// Server trace id of the failed request (API-21).
  final String requestId;
  final List<ProblemFieldError>? errors;

  /// Where to get a supported client; set on `api_version_unsupported`.
  final String? updateUrl;

  /// Members this type does not name, e.g. an API's own extension.
  final Map<String, Object?> extensions;
}

String _string(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('$key must be a string', value);
  return value;
}

String? _optionalString(Map<String, Object?> json, String key) =>
    json[key] == null ? null : _string(json, key);

int _int(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('$key must be an integer', value);
  return value;
}
