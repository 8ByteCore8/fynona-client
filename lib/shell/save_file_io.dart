import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'file_name.dart';

/// Writes [bytes] to [name] in the Downloads folder, or the app's documents
/// folder where the platform has none; returns the file's path. [name] must
/// be a plain file name ([isSafeFileName]).
Future<String> saveFile(String name, Uint8List bytes, String mimeType) async {
  if (!isSafeFileName(name)) {
    throw ArgumentError.value(name, 'name', 'not a plain file name');
  }
  final directory =
      await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
  final file = File('${directory.path}${Platform.pathSeparator}$name');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
