part of '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onBack,
    required this.onAuthenticated,
    required this.onOpenSignUp,
  });

  final VoidCallback onBack;
  final VoidCallback onAuthenticated;
  final VoidCallback onOpenSignUp;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: 'Welcome Back',
      subtitle: 'Sign in to continue checking attendee status in real time.',
      onBack: widget.onBack,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: bodyStyle(15, color: AppPalette.onSurface),
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty ||
                    !value.contains('@')) {
                  return 'Enter a valid email address.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              style: bodyStyle(15, color: AppPalette.onSurface),
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Password must be at least 6 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            PrimaryPillButton(
              label: 'LOGIN',
              icon: Icons.login_rounded,
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  widget.onAuthenticated();
                }
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: widget.onOpenSignUp,
              child: Text(
                'Need an account? Sign up',
                style: bodyStyle(
                  14,
                  color: AppPalette.primary,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({
    super.key,
    required this.onBack,
    required this.onAuthenticated,
    required this.onOpenLogin,
  });

  final VoidCallback onBack;
  final VoidCallback onAuthenticated;
  final VoidCallback onOpenLogin;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: 'Create Your Access',
      subtitle:
          'Set up a new operator profile for scanning and attendee review.',
      onBack: widget.onBack,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              style: bodyStyle(15, color: AppPalette.onSurface),
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter your name.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: bodyStyle(15, color: AppPalette.onSurface),
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty ||
                    !value.contains('@')) {
                  return 'Enter a valid email address.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              style: bodyStyle(15, color: AppPalette.onSurface),
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Password must be at least 6 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            PrimaryPillButton(
              label: 'SIGN UP',
              icon: Icons.person_add_alt_1_rounded,
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  widget.onAuthenticated();
                }
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: widget.onOpenLogin,
              child: Text(
                'Already have an account? Login',
                style: bodyStyle(
                  14,
                  color: AppPalette.primary,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.child,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final Widget child;

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
                size: 280,
                color: AppPalette.primary,
                opacity: 0.11,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                child: ListView(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      style: headlineStyle(
                        34,
                        color: AppPalette.onSurface,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: bodyStyle(
                        16,
                        color: AppPalette.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppPalette.surfaceContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: child,
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
