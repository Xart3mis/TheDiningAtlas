import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/constants/route_names.dart';
import 'login_screen.dart';

/// Entry gate — checks auth state, then onboarding completion.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.user == null && auth.isLoading) {
          return const _SplashView();
        }

        if (auth.isAuthenticated) {
          return _AuthenticatedGate(userId: auth.user!.uid);
        }

        return const LoginScreen();
      },
    );
  }
}

class _AuthenticatedGate extends StatefulWidget {
  final String userId;
  const _AuthenticatedGate({required this.userId});

  @override
  State<_AuthenticatedGate> createState() => _AuthenticatedGateState();
}

class _AuthenticatedGateState extends State<_AuthenticatedGate> {
  _GateState _state = _GateState.loading;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final userProvider = context.read<UserProvider>();
    final notifProvider = context.read<NotificationProvider>();

    await userProvider.loadUser(widget.userId);
    await notifProvider.initialize();
    await notifProvider.getToken();

    if (!mounted) return;

    if (!(userProvider.user?.onboardingComplete ?? true)) {
      setState(() => _state = _GateState.needsOnboarding);
    } else {
      setState(() => _state = _GateState.ready);
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _GateState.loading => const _SplashView(),
      _GateState.needsOnboarding => _OnboardingRedirect(),
      _GateState.ready => _MainRedirect(),
    };
  }
}

enum _GateState { loading, needsOnboarding, ready }

class _OnboardingRedirect extends StatefulWidget {
  @override
  State<_OnboardingRedirect> createState() => _OnboardingRedirectState();
}

class _OnboardingRedirectState extends State<_OnboardingRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, RouteNames.kOnboarding);
      }
    });
  }

  @override
  Widget build(BuildContext context) => const _SplashView();
}

class _MainRedirect extends StatefulWidget {
  @override
  State<_MainRedirect> createState() => _MainRedirectState();
}

class _MainRedirectState extends State<_MainRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, RouteNames.kMain);
      }
    });
  }

  @override
  Widget build(BuildContext context) => const _SplashView();
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'The\nDining Atlas',
              textAlign: TextAlign.center,
              style: GoogleFonts.fraunces(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Experience every city\nthe way locals do.',
              textAlign: TextAlign.center,
              style: GoogleFonts.fraunces(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppColors.terracotta,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.terracotta,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
