import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Hands [bytes] to the browser as a download named [name]; returns [name].
Future<String> saveFile(String name, Uint8List bytes, String mimeType) async {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  try {
    (web.HTMLAnchorElement()
          ..href = url
          ..download = name)
        .click();
  } finally {
    web.URL.revokeObjectURL(url);
  }
  return name;
}
