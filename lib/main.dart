import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fynona_ui/fynona_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';

void main() {
  registerFynonaLicenses();
  runApp(const ProviderScope(child: FynonaApp()));
}
