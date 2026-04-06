part of '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onCompleted});

  final VoidCallback onCompleted;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _timer = Timer(const Duration(milliseconds: 1500), widget.onCompleted);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            const Positioned(
              top: -120,
              right: -120,
              child: GlowOrb(
                size: 300,
                color: AppPalette.primary,
                opacity: 0.11,
              ),
            ),
            Center(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeOut,
                ),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 116,
                        height: 116,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppPalette.primary.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppPalette.primary.withValues(alpha: 0.15),
                            ),
                            child: const Icon(
                              Icons.visibility_outlined,
                              color: AppPalette.primary,
                              size: 34,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'SYNTHETIC EYE',
                        style: headlineStyle(
                          22,
                          color: AppPalette.primary,
                          weight: FontWeight.w700,
                          letterSpacing: 3.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'ENTRY CONTROL IN MOTION',
                        style: labelStyle(
                          color: AppPalette.onSurfaceVariant,
                          letterSpacing: 2.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
