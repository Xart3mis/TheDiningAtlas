import 'package:flutter/material.dart';
import 'vibe_selector_screen.dart';
import 'budget_screen.dart';
import 'atmosphere_screen.dart';
import 'destination_screen.dart';
import 'profile_ready_screen.dart';

class OnboardingShell extends StatefulWidget {
  const OnboardingShell({super.key});

  @override
  State<OnboardingShell> createState() => _OnboardingShellState();
}

class _OnboardingShellState extends State<OnboardingShell> {
  final _controller = PageController();
  int _currentPage = 0;

  void _next() {
    if (_currentPage < 4) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _controller.previousPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: i == _currentPage ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: i == _currentPage
                          ? const Color(0xFFC17B4E)
                          : const Color(0xFFCCC5B9),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  VibeSelectorScreen(onNext: _next, onBack: _back),
                  BudgetScreen(onNext: _next, onBack: _back),
                  AtmosphereScreen(onNext: _next, onBack: _back),
                  DestinationScreen(onNext: _next, onBack: _back),
                  const ProfileReadyScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
