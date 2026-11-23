import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'auth_gate.dart';
import '../widgets/custom_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      "image": "assets/images/onboarding1.png",
      "title": "Everything your business needs to get done",
      "description":
          "Orders, suppliers, marketing and money tasks in one clear list, "
          "so nothing slips through the cracks.",
    },
    {
      "image": "assets/images/onboarding2.png",
      "title": "Plan the day and the week ahead",
      "description":
          "Set due dates and priorities, see what is due today, and plan "
          "ahead on the calendar.",
    },
    {
      "image": "assets/images/onboarding3.png",
      "title": "See how the work is going",
      "description":
          "Search and filter in seconds, and track what gets finished with "
          "simple, honest insights.",
    },
  ];

  bool get _isLast => _currentPage == _onboardingData.length - 1;

  Future<void> _finishOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboardingComplete', true);
    } catch (_) {}

    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthGate()));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.xl,
                AppSpace.md,
                AppSpace.md,
                0,
              ),
              child: Row(
                children: [
                  const AppLogoMark(size: 32),
                  const SizedBox(width: AppSpace.sm),
                  const AppWordmark(fontSize: 22),
                  const Spacer(),
                  AnimatedOpacity(
                    opacity: _isLast ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: TextButton(
                      onPressed: _isLast ? null : _finishOnboarding,
                      child: const Text('Skip'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingData.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (_, i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.xl,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.xl,
                            vertical: AppSpace.xxl,
                          ),
                          decoration: BoxDecoration(
                            // The illustrations have a white backdrop baked in.
                            color: Colors.white,
                            border: Border.all(color: context.palette.border),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Image.asset(
                            _onboardingData[i]['image']!,
                            height: MediaQuery.of(context).size.height * 0.27,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _onboardingData[i]['title']!,
                          textAlign: TextAlign.center,
                          style: context.text.headlineMedium,
                        ),
                        const SizedBox(height: AppSpace.lg),
                        Text(
                          _onboardingData[i]['description']!,
                          textAlign: TextAlign.center,
                          style: context.text.bodyLarge?.copyWith(
                            color: context.palette.muted,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_onboardingData.length, buildDot),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.xl),
              child: CustomButton(
                text: _isLast ? "Get started" : "Next",
                icon: Icons.arrow_forward,
                onPressed: () {
                  if (_isLast) {
                    _finishOnboarding();
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDot(int index) {
    final active = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 8,
      width: active ? 26 : 8,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color:
            active ? context.colors.primary : context.colors.outlineVariant,
      ),
    );
  }
}
