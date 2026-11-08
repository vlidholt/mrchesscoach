import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'client.dart';
import 'screens/lobby_screen.dart';
import 'screens/sign_in_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(_fontLicenses);
  await initializeClient();
  runApp(const ChessCoachApp());
}

/// The OFL licenses of the bundled fonts, read only when the licenses page
/// is opened.
Stream<LicenseEntry> _fontLicenses() async* {
  const fonts = {
    'Manrope': 'Manrope',
    'Cormorant Garamond': 'CormorantGaramond',
    'IBM Plex Mono': 'IBMPlexMono',
  };
  for (final MapEntry(key: family, value: file) in fonts.entries) {
    final text = await rootBundle.loadString(
      'assets/fonts/licenses/$file-OFL.txt',
    );
    yield LicenseEntryWithLineBreaks([family], text);
  }
}

class ChessCoachApp extends StatelessWidget {
  const ChessCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mr. Chess Coach',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Carousels and strips can be swiped with a mouse or trackpad too,
      // not only by touch (the web default).
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: PointerDeviceKind.values.toSet(),
      ),
      home: const SignInScreen(child: LobbyScreen()),
    );
  }
}
