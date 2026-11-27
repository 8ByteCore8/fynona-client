final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

/// A plain file name: no folder part, no `.`/`..`, no control characters,
/// so a saved file stays in its target folder.
bool isSafeFileName(String name) =>
    name.isNotEmpty &&
    name.length <= 255 &&
    name != '.' &&
    name != '..' &&
    !RegExp(r'[/\\:\x00-\x1f]').hasMatch(name);

/// The file name of the data export [id]; the id is named only when it is a
/// UUID, since it comes from the server.
String exportArchiveFileName(String id) =>
    _uuid.hasMatch(id) ? 'fynona-export-$id.json' : 'fynona-export.json';
