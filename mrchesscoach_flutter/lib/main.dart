import 'package:flutter/material.dart';

import 'client.dart';
import 'screens/lobby_screen.dart';
import 'screens/sign_in_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeClient();
  runApp(const ChessCoachApp());
}

class ChessCoachApp extends StatelessWidget {
  const ChessCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mr. Chess Coach',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const SignInScreen(child: LobbyScreen()),
    );
  }
}
