import 'package:flutter/material.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../client.dart';
import '../theme.dart';
import '../widgets/fx.dart';
import 'lobby_screen.dart' show CoachHero;

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
      duration: const Duration(milliseconds: 700),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(
          scale: Tween(begin: 1.06, end: 1.0).animate(a),
          child: child,
        ),
      ),
      child: _isSignedIn
          ? KeyedSubtree(key: const ValueKey('in'), child: widget.child)
          : KeyedSubtree(key: const ValueKey('out'), child: _signInPage()),
    );
  }

  Widget _signInPage() {
    // Email sign-in with a one-time code; the widget picks the flow from the
    // server's email endpoint.
    final signIn = Panel(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
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

    final title = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIcon(size: 44),
              const SizedBox(width: 12),
              Shine(
                period: const Duration(milliseconds: 4600),
                child: GoldText(
                  'Mr. Chess Coach',
                  style: Typo.display(44),
                  align: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your friendly opponent and coach in one.',
          textAlign: TextAlign.center,
          style: Typo.body(14),
        ),
      ],
    );

    return Scaffold(
      body: FxScope(
        child: AmbientBackground(
          spotlight: const Alignment(0, -0.7),
          intensity: 0.6,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= Breakpoints.desktop;
                if (wide) {
                  return Row(
                    children: [
                      const Expanded(
                        flex: 6,
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CoachHero(big: true),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(32),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Entrance(child: title),
                                  const SizedBox(height: 28),
                                  Entrance(
                                    delay: const Duration(milliseconds: 200),
                                    child: signIn,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                // Phones and tablets: the coach on top, the form below. It
                // only scrolls when the keyboard takes the space.
                return CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                            child: Column(
                              children: [
                                const Expanded(
                                  child: SizedBox(
                                    height: 170,
                                    child: CoachHero(),
                                  ),
                                ),
                                Entrance(child: title),
                                const SizedBox(height: 14),
                                Entrance(
                                  delay: const Duration(milliseconds: 200),
                                  child: signIn,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
