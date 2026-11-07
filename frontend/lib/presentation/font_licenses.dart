// Licencia de la tipografía Poppins (tarea T407; spec 005, SC-503; research.md de 005,
// R5).
//
// Flutter ya conoce las licencias de sus librerías. La de Poppins (SIL Open Font
// License) va en assets/fonts/OFL-Poppins.txt y se agrega aquí, para que aparezca en
// «Licencias» junto con las demás.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Ruta de la licencia dentro de la app (declarada en pubspec.yaml).
const poppinsLicenseAsset = 'assets/fonts/OFL-Poppins.txt';

/// Agrega la licencia de Poppins a «Licencias», junto a las de las bibliotecas. Se
/// llama una sola vez, al abrir la app (main.dart).
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString(poppinsLicenseAsset);
    yield LicenseEntryWithLineBreaks(const ['Poppins'], text);
  });
}
