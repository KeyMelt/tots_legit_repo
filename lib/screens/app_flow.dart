part of '../main.dart';

class AppFlow extends StatefulWidget {
  const AppFlow({super.key});

  @override
  State<AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<AppFlow> {
  final AttendeeRepository _repository = FastApiAttendeeRepository();
  AppPhase _phase = AppPhase.splash;

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      AppPhase.splash => SplashScreen(
        onCompleted: () => setState(() => _phase = AppPhase.onboarding),
      ),
      AppPhase.onboarding => OnboardingScreen(
        onLogin: () => setState(() => _phase = AppPhase.login),
        onSignUp: () => setState(() => _phase = AppPhase.signup),
      ),
      AppPhase.login => LoginScreen(
        onBack: () => setState(() => _phase = AppPhase.onboarding),
        onAuthenticated: () => setState(() => _phase = AppPhase.shell),
        onOpenSignUp: () => setState(() => _phase = AppPhase.signup),
      ),
      AppPhase.signup => SignUpScreen(
        onBack: () => setState(() => _phase = AppPhase.onboarding),
        onAuthenticated: () => setState(() => _phase = AppPhase.shell),
        onOpenLogin: () => setState(() => _phase = AppPhase.login),
      ),
      AppPhase.shell => MainShell(
        repository: _repository,
        onLogout: () => setState(() => _phase = AppPhase.onboarding),
      ),
    };
  }
}

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.repository,
    required this.onLogout,
  });

  final AttendeeRepository repository;
  final VoidCallback onLogout;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late final PageController _pageController;
  int _selectedIndex = 0;

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

  void _selectTab(int index) {
    if (index == _selectedIndex) {
      return;
    }
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _openResult(ScanResult result) {
    Navigator.of(context).push(
      buildFadeRoute(
        IdentityFoundScreen(
          result: result,
          repository: widget.repository,
          onSelectTab: (index) {
            _selectTab(index);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: [
          ScanScreen(
            repository: widget.repository,
            onLogout: widget.onLogout,
            onOpenResult: _openResult,
          ),
          HistoryScreen(repository: widget.repository),
          SettingsScreen(
            repository: widget.repository,
            onLogout: widget.onLogout,
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: _selectedIndex,
        onSelected: _selectTab,
      ),
    );
  }
}
