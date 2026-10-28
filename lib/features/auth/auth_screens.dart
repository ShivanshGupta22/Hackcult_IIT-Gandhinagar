import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_state.dart';

// ---------------------------------------------------------------------------
// Validators (shared with admin login)
// ---------------------------------------------------------------------------
class Validators {
  Validators._();
  static final _email = RegExp(r'^[\w\.\-+]+@[\w\-]+(\.[\w\-]+)+$');

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!_email.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'Include a letter and a number';
    }
    return null;
  }

  static String? name(String? v) {
    if (v == null || v.trim().length < 2) return 'Enter your full name';
    return null;
  }

  static int strength(String v) {
    var s = 0;
    if (v.length >= 8) s++;
    if (RegExp(r'[A-Za-z]').hasMatch(v) && RegExp(r'\d').hasMatch(v)) s++;
    if (v.length >= 12 || RegExp(r'[^A-Za-z0-9]').hasMatch(v)) s++;
    return s;
  }
}

// ---------------------------------------------------------------------------
// Splash
// ---------------------------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      final s = AppScope.read(context);
      if (!s.isSignedIn) {
        context.go('/login');
      } else if (!s.user!.onboardingComplete) {
        context.go('/onboarding/1');
      } else {
        context.go(s.user!.isAdmin ? '/admin' : '/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final w = MediaQuery.sizeOf(context).width;
    final logoSize = (w * 0.55).clamp(180.0, 300.0);
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutBack,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Image.asset('assets/images/logo.png',
                  width: logoSize,
                  height: logoSize,
                  filterQuality: FilterQuality.high),
            ),
            const Spacer(flex: 3),
            const SizedBox(
                width: 140,
                child: LinearProgressIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.primarySoft,
                    minHeight: 3)),
            const SizedBox(height: 20),
            Text('Powered by GEDA · Government of Gujarat',
                style: t.labelSmall?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared auth shell (gradient header + white sheet)
// ---------------------------------------------------------------------------
class _AuthShell extends StatelessWidget {
  const _AuthShell(
      {required this.child,
      required this.language,
      required this.onLanguage,
      this.showBack = false});
  final Widget child;
  final String language;
  final ValueChanged<String> onLanguage;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: PhoneFrame(
        child: Container(
          decoration: const BoxDecoration(gradient: AppColors.heroGreen),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      if (showBack)
                        Expanded(
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                    onPressed: () => context.safePop('/login'),
                                    icon: const Icon(Icons.arrow_back_rounded,
                                        color: Colors.white))))
                      else
                        Flexible(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                      'assets/images/logo_512.png',
                                      width: 44,
                                      height: 44),
                                ),
                                const SizedBox(width: 10),
                                const Flexible(child: BrandPill(compact: true)),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      LanguageSwitcher(
                          value: language, onChanged: onLanguage, light: true),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mission LiFE Gujarat',
                          style: t.displaySmall?.copyWith(color: Colors.white)),
                      const SizedBox(height: 6),
                      Text(
                          "Small habits. Big impact. Gujarat's Pro-Planet People.",
                          style: t.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85))),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppRadius.sheet)),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(24, 28, 24,
                          24 + MediaQuery.viewInsetsOf(context).bottom),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Login
// ---------------------------------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _googleLoading = false;
  String? _error;
  String _lang = 'en';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final err = await AppScope.read(context)
        .signInWithEmail(_email.text, _password.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    _route();
  }

  Future<void> _google() async {
    setState(() => _googleLoading = true);
    await AppScope.read(context).signInWithGoogle();
    if (!mounted) return;
    setState(() => _googleLoading = false);
    _route();
  }

  void _route() {
    final u = AppScope.read(context).user!;
    if (u.isAdmin) {
      context.go('/admin');
    } else if (!u.onboardingComplete) {
      context.go('/onboarding/1');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final gu = _lang == 'gu';
    return _AuthShell(
      language: _lang,
      onLanguage: (v) => setState(() => _lang = v),
      child: Form(
        key: _form,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(gu ? 'ફરી સ્વાગત છે' : 'Welcome back',
                  style: t.headlineMedium),
              const SizedBox(height: 4),
              Text(
                  gu
                      ? 'તમારી મિશન LiFE યાત્રા ચાલુ રાખવા સાઇન ઇન કરો'
                      : 'Sign in to continue your Mission LiFE journey',
                  style:
                      t.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              if (_error != null) ...[
                InfoBanner(
                    text: _error!,
                    icon: Icons.error_outline_rounded,
                    color: AppColors.error),
                const SizedBox(height: 16),
              ],
              AppTextField(
                label: gu ? 'ઇમેઇલ' : 'Email',
                controller: _email,
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline_rounded,
                validator: Validators.email,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: gu ? 'પાસવર્ડ' : 'Password',
                controller: _password,
                hint: '••••••••',
                obscure: _obscure,
                prefixIcon: Icons.lock_outline_rounded,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Password is required' : null,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                suffix: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20),
                ),
                labelTrailing: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text(gu ? 'પાસવર્ડ ભૂલી ગયા?' : 'Forgot password?',
                      style: t.labelMedium?.copyWith(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                  label: gu ? 'સાઇન ઇન' : 'Sign In',
                  onPressed: _submit,
                  loading: _loading),
              const SizedBox(height: 20),
              const _OrDivider(),
              const SizedBox(height: 20),
              GoogleButton(
                  onPressed: _google,
                  loading: _googleLoading,
                  label: gu ? 'Google સાથે ચાલુ રાખો' : 'Continue with Google'),
              const SizedBox(height: 24),
              Center(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(gu ? 'નવા છો? ' : 'New here? ',
                        style: t.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () => context.push('/signup'),
                      child: Text(gu ? 'એકાઉન્ટ બનાવો' : 'Create account',
                          style:
                              t.labelLarge?.copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text('Demo: nisha@demo.com / Demo@1234',
                    style:
                        t.labelSmall?.copyWith(color: AppColors.textTertiary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: Theme.of(context).textTheme.labelMedium),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sign up
// ---------------------------------------------------------------------------
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _consent = false;
  bool _consentError = false;
  bool _loading = false;
  bool _googleLoading = false;
  String _lang = 'en';
  int _strength = 0;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _form.currentState!.validate();
    setState(() => _consentError = !_consent);
    if (!valid || !_consent) return;
    setState(() => _loading = true);
    final err = await AppScope.read(context).signUpWithEmail(
        name: _name.text, email: _email.text, password: _password.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err == 'email-already-in-use') {
      showAppSnack(context, 'Account exists with this email',
          icon: Icons.info_outline_rounded,
          actionLabel: 'Sign in',
          onAction: () => context.go('/login'));
      return;
    }
    final u = AppScope.read(context).user!;
    context.go(u.isAdmin ? '/admin' : '/onboarding/1');
  }

  Future<void> _google() async {
    setState(() => _googleLoading = true);
    await AppScope.read(context).signInWithGoogle();
    if (!mounted) return;
    final u = AppScope.read(context).user!;
    context.go(u.onboardingComplete ? '/home' : '/onboarding/1');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return _AuthShell(
      language: _lang,
      onLanguage: (v) => setState(() => _lang = v),
      showBack: true,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create your account', style: t.headlineMedium),
            const SizedBox(height: 4),
            Text('Join 2.4 lakh Gujarat households saving energy together',
                style: t.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            AppTextField(
                label: 'Full name',
                controller: _name,
                hint: 'e.g. Nisha Patel',
                prefixIcon: Icons.person_outline_rounded,
                validator: Validators.name,
                textInputAction: TextInputAction.next),
            const SizedBox(height: 16),
            AppTextField(
                label: 'Email',
                controller: _email,
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline_rounded,
                validator: Validators.email,
                textInputAction: TextInputAction.next),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Password',
              controller: _password,
              hint: 'Minimum 8 characters',
              obscure: _obscure,
              prefixIcon: Icons.lock_outline_rounded,
              validator: Validators.password,
              onChanged: (v) =>
                  setState(() => _strength = Validators.strength(v)),
              textInputAction: TextInputAction.next,
              suffix: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20),
              ),
            ),
            const SizedBox(height: 8),
            _StrengthMeter(strength: _strength),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Confirm password',
              controller: _confirm,
              hint: 'Re-enter password',
              obscure: true,
              prefixIcon: Icons.lock_outline_rounded,
              validator: (v) =>
                  v != _password.text ? 'Passwords do not match' : null,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() {
                _consent = !_consent;
                _consentError = false;
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _consent,
                        onChanged: (v) => setState(() {
                          _consent = v ?? false;
                          _consentError = false;
                        }),
                        isError: _consentError,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: t.bodySmall?.copyWith(
                              color: _consentError
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                              height: 1.5),
                          children: const [
                            TextSpan(
                                text:
                                    'I agree to share anonymised data with GEDA for Mission LiFE reporting. '),
                            TextSpan(
                                text: 'Privacy',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_consentError)
              Padding(
                padding: const EdgeInsets.only(left: 34, top: 2),
                child: Text('Please accept to continue',
                    style: t.labelSmall?.copyWith(color: AppColors.error)),
              ),
            const SizedBox(height: 20),
            PrimaryButton(
                label: 'Create account', onPressed: _submit, loading: _loading),
            const SizedBox(height: 20),
            const _OrDivider(),
            const SizedBox(height: 20),
            GoogleButton(onPressed: _google, loading: _googleLoading),
            const SizedBox(height: 24),
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Already have an account? ',
                      style: t.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary)),
                  GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text('Sign in',
                          style: t.labelLarge
                              ?.copyWith(color: AppColors.primary))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.strength});
  final int strength;

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.error, AppColors.warning, AppColors.success];
    final labels = ['8+ chars, a letter & a number', 'Weak', 'Good', 'Strong'];
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 4,
              decoration: BoxDecoration(
                color: i < strength ? colors[strength - 1] : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (i < 2) const SizedBox(width: 4),
        ],
        const SizedBox(width: 10),
        Text(labels[strength], style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Forgot password
// ---------------------------------------------------------------------------
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    await AppScope.read(context).sendPasswordReset(_email.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
          leading: BackButton(onPressed: () => context.safePop('/login'))),
      body: PhoneFrame(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                          color: AppColors.primarySoft, shape: BoxShape.circle),
                      child: const Icon(Icons.mark_email_read_rounded,
                          color: AppColors.primary, size: 40),
                    ),
                    const SizedBox(height: 24),
                    Text('Check your inbox',
                        style: t.headlineMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('We sent a reset link to',
                        style: t.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center),
                    Text(_email.text.trim(),
                        style: t.titleSmall, textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    SecondaryButton(
                        label: 'Back to sign in',
                        onPressed: () => context.go('/login')),
                    const SizedBox(height: 12),
                    TextButton(
                        onPressed: () => setState(() => _sent = false),
                        child: const Text("Didn't get it? Resend")),
                  ],
                )
              : Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reset your password', style: t.headlineMedium),
                      const SizedBox(height: 8),
                      Text("Enter your email and we'll send a reset link.",
                          style: t.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 28),
                      AppTextField(
                          label: 'Email',
                          controller: _email,
                          hint: 'you@example.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.mail_outline_rounded,
                          validator: Validators.email),
                      const SizedBox(height: 24),
                      PrimaryButton(
                          label: 'Send reset link',
                          onPressed: _send,
                          loading: _loading),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
