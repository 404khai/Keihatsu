import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  bool _restoreFailed = false;

  @override
  void initState() {
    super.initState();
    _checkRouting();
  }

  Future<void> _checkRouting() async {
    final auth = context.read<AuthProvider>();
    await auth.initialized;
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    if (auth.restoreFailed) {
      setState(() => _restoreFailed = true);
      return;
    }
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (auth.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/library');
    } else {
      if (hasSeenOnboarding) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        Navigator.pushReplacementNamed(context, '/onboardingFlow');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('images/keihatsu.png', height: 300),
            Text(
              'Keihatsu',
              style: GoogleFonts.unbounded(
                textStyle: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
            ),
            if (_restoreFailed) ...[
              const Text(
                'Unable to restore your session. Your login is saved.',
                style: TextStyle(color: Colors.white),
              ),
              FilledButton(
                onPressed: () async {
                  setState(() => _restoreFailed = false);
                  await context.read<AuthProvider>().retrySessionRestore();
                  if (mounted) await _checkRouting();
                },
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/library'),
                child: const Text('Continue offline'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
