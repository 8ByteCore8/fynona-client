import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the SIL Open Font License of the bundled Inter to the app's licence
/// page. Call once at start-up.
void registerFynonaLicenses() {
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString(
      'packages/fynona_ui/fonts/OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(const ['Inter'], text);
  });
}
