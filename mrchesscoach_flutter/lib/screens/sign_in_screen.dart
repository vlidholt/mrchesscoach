import '../game/chess_model.dart';
import 'package:flutter/material.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../client.dart';
import '../theme.dart';
import '../widgets/chess_board.dart';

/// Shows [child] when the user is signed in, and the sign-in page otherwise.
class SignInScreen extends StatefulWidget {
  final Widget child;
  const SignInScreen({super.key, required this.child});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isSignedIn = false;

  @override
  void initState() {
    super.initState();
    client.auth.authInfoListenable.addListener(_updateSignedInState);
    _isSignedIn = client.auth.isAuthenticated;
  }

  @override
  void dispose() {
    client.auth.authInfoListenable.removeListener(_updateSignedInState);
    super.dispose();
  }

  void _updateSignedInState() {
    setState(() {
      _isSignedIn = client.auth.isAuthenticated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: _isSignedIn
          ? KeyedSubtree(key: const ValueKey('in'), child: widget.child)
          : KeyedSubtree(key: const ValueKey('out'), child: _signInPage()),
    );
  }

  Widget _signInPage() {
    final signIn = Panel(
      padding: const EdgeInsets.all(8),
      child: SignInWidget(
        client: client,
        onAuthenticated: () {},
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign-in failed: $error')),
          );
        },
      ),
    );

    return Scaffold(
      body: AmbientBackground(
        spotlight: const Alignment(0, -0.7),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final intro = Column(
                crossAxisAlignment: wide
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Image.asset(
                        pieceAsset(Side.white, Role.king),
                        height: wide ? 150 : 90,
                      ),
                      Transform.translate(
                        offset: const Offset(-18, 0),
                        child: Image.asset(
                          pieceAsset(Side.black, Role.queen),
                          height: wide ? 130 : 78,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('Mr. Chess', style: Typo.display(wide ? 88 : 56)),
                  Text(
                    'Coach',
                    style: Typo.display(wide ? 88 : 56, color: Palette.gold),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Text(
                      'Sit down at the board with Stockfish, at a level that suits you. Your games are kept for you.',
                      textAlign: wide ? TextAlign.start : TextAlign.center,
                      style: Typo.body(15),
                    ),
                  ),
                ],
              );
              final form = ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: signIn,
              );
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 64,
                  ),
                  child: Center(
                    child: wide
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              intro,
                              const SizedBox(width: 80),
                              form,
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [intro, const SizedBox(height: 32), form],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
