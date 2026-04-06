part of '../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onLogin,
    required this.onSignUp,
  });

  final VoidCallback onLogin;
  final VoidCallback onSignUp;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = [
    OnboardingPageData(
      title: 'Precision Identity Redefined',
      body:
          'Experience the next generation of biometric security with fast guest recognition and clear status checks.',
      signalLabel: 'SIGNAL STRENGTH',
      signalValue: '98.4%',
      matchLabel: 'NEURAL MATCH',
      matchValue: 'READY',
      imageUrl: onboardingPortalUrl,
      accent: AppPalette.primary,
    ),
    OnboardingPageData(
      title: 'Capture Every Guest In Seconds',
      body:
          'Use the live camera or upload from the device to verify accepted, rejected, and unknown attendees instantly.',
      signalLabel: 'ENTRY FLOW',
      signalValue: 'SYNCED',
      matchLabel: 'CHECK-IN RATE',
      matchValue: 'FAST',
      imageUrl: eventPortalUrl,
      accent: AppPalette.primaryContainer,
    ),
    OnboardingPageData(
      title: 'Know Who Is On The List',
      body:
          'Review scan history, filter by attendee status, and pull up details whenever the team needs a quick answer.',
      signalLabel: 'EVENT STATUS',
      signalValue: 'LIVE',
      matchLabel: 'GUEST ACCESS',
      matchValue: 'TRACKED',
      imageUrl: crowdPortalUrl,
      accent: AppPalette.tertiary,
    ),
  ];

  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D121B), AppPalette.background],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: GridBackground()),
            Positioned(
              top: -120,
              right: -120,
              child: GlowOrb(size: 320, color: page.accent, opacity: 0.11),
            ),
            Positioned(
              bottom: -80,
              left: -100,
              child: GlowOrb(size: 280, color: page.accent, opacity: 0.12),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Column(
                  children: [
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              color: AppPalette.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'SYNTHETIC EYE',
                              style: headlineStyle(
                                18,
                                color: AppPalette.primary,
                                weight: FontWeight.w700,
                                letterSpacing: 3.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'BIOMETRIC AUTHORITY V2.0',
                          style: labelStyle(
                            color: AppPalette.onSurfaceVariant,
                            letterSpacing: 1.7,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _pages.length,
                        onPageChanged: (index) =>
                            setState(() => _currentPage = index),
                        itemBuilder: (context, index) {
                          final slide = _pages[index];
                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                const SizedBox(height: 12),
                                OnboardingPortal(page: slide),
                                const SizedBox(height: 36),
                                Text(
                                  slide.title,
                                  textAlign: TextAlign.center,
                                  style: headlineStyle(
                                    29,
                                    color: AppPalette.onSurface,
                                    weight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                  child: Text(
                                    slide.body,
                                    textAlign: TextAlign.center,
                                    style: bodyStyle(
                                      17,
                                      color: AppPalette.onSurfaceVariant,
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (index) {
                        final active = index == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 24 : 8,
                          height: 4,
                          decoration: BoxDecoration(
                            color: active
                                ? page.accent
                                : AppPalette.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 22),
                    PrimaryPillButton(
                      label: 'GET STARTED',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: widget.onSignUp,
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: widget.onLogin,
                      child: Text(
                        'EXISTING ACCOUNT LOGIN',
                        style: labelStyle(
                          color: AppPalette.onSurfaceVariant.withValues(
                            alpha: 0.45,
                          ),
                          letterSpacing: 2.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
