import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'dashboardscreen.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;

  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  final _auth = FirebaseAuth.instance;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _isLogin = !_isLogin;
      _usernameCtrl.clear();
      _passwordCtrl.clear();
      _confirmPasswordCtrl.clear();
    });
    _animController.reset();
    _animController.forward();
  }

  Future<void> _handleAuth() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final username = _isLogin ? '' : _usernameCtrl.text.trim();
    final confirmPassword = _confirmPasswordCtrl.text;

    // Validation
    if (!_isLogin && username.isEmpty) {
      _showSnack('Please enter your username');
      return;
    }
    if (!EmailValidator.validate(email)) {
      _showSnack('Please enter a valid email address');
      return;
    }
    if (password.isEmpty) {
      _showSnack('Please enter your password');
      return;
    }
    if (!_isLogin && password.length <= 8) {
      _showSnack('Password must be more than 8 characters');
      return;
    }
    if (!_isLogin && password != confirmPassword) {
      _showSnack('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // Firebase Login
        final cred = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = cred.user;
        if (user != null) {
          // Save to SharedPreferences for local access
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('email', email);
          await prefs.setString('username',
              user.displayName ?? email.split('@')[0]);
          await prefs.setBool('islogin', true);
          _goToDashboard(user.displayName ?? email.split('@')[0]);
        }
      } else {
        // Firebase Signup
        final cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = cred.user;
        if (user != null) {
          // Set display name
          await user.updateDisplayName(username);
          // Save to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('email', email);
          await prefs.setString('username', username);
          await prefs.setBool('islogin', true);
          _goToDashboard(username);
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _showSnack(_getErrorMessage(e.code));
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Something went wrong. Please try again.');
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email. Please sign up.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Please login.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'invalid-credential':
        return 'Incorrect email or password.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  void _goToDashboard(String username) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => DashboardScreen(username: username),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider, width: 0.8),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 14),
          prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        height: screenH,
        decoration: const BoxDecoration(gradient: AppTheme.splashGradient),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -40,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent.withOpacity(0.04),
                ),
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: screenH - 100),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),
                            // Logo
                            Center(
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.goldGradient,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.accent.withOpacity(0.35),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text('CV',
                                      style: GoogleFonts.poppins(
                                        color: Colors.black,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                      )),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              _isLogin ? 'Welcome Back' : 'Create Account',
                              style: AppTheme.headingLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isLogin
                                  ? 'Sign in to continue watching'
                                  : 'Join CineVerse today',
                              style: AppTheme.bodyText,
                            ),
                            const SizedBox(height: 30),

                            // Username (signup only)
                            if (!_isLogin) ...[
                              _buildField(
                                controller: _usernameCtrl,
                                hint: 'Username',
                                icon: Icons.person_outline_rounded,
                              ),
                              const SizedBox(height: 14),
                            ],

                            // Email
                            _buildField(
                              controller: _emailCtrl,
                              hint: 'Email address',
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),

                            // Password
                            _buildField(
                              controller: _passwordCtrl,
                              hint: 'Password',
                              icon: Icons.lock_outline_rounded,
                              obscure: !_passwordVisible,
                              suffix: IconButton(
                                icon: Icon(
                                  _passwordVisible
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                  color: AppTheme.textMuted,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _passwordVisible = !_passwordVisible),
                              ),
                            ),

                            // Confirm password (signup only)
                            if (!_isLogin) ...[
                              const SizedBox(height: 14),
                              _buildField(
                                controller: _confirmPasswordCtrl,
                                hint: 'Confirm Password',
                                icon: Icons.lock_outline_rounded,
                                obscure: !_confirmPasswordVisible,
                                suffix: IconButton(
                                  icon: Icon(
                                    _confirmPasswordVisible
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    color: AppTheme.textMuted,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() =>
                                      _confirmPasswordVisible =
                                          !_confirmPasswordVisible),
                                ),
                              ),
                            ],

                            const SizedBox(height: 28),

                            // Forgot password (login only)
                            if (_isLogin)
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  ),
                                  child: Text(
                                    'Forgot Password?',
                                    style: GoogleFonts.poppins(
                                      color: AppTheme.accent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                            if (_isLogin) const SizedBox(height: 20),

                            // Action button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleAuth,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.goldGradient,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.accent.withOpacity(0.3),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.black,
                                            ),
                                          )
                                        : Text(
                                            _isLogin ? 'Sign In' : 'Sign Up',
                                            style: GoogleFonts.poppins(
                                              color: Colors.black,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Switch mode
                            Center(
                              child: GestureDetector(
                                onTap: _switchMode,
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary),
                                    children: [
                                      TextSpan(
                                        text: _isLogin
                                            ? "Don't have an account? "
                                            : 'Already have an account? ',
                                      ),
                                      TextSpan(
                                        text: _isLogin ? 'Sign Up' : 'Sign In',
                                        style: GoogleFonts.poppins(
                                          color: AppTheme.accent,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const Spacer(),

                            // Bottom branding
                            Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 30),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                          child: Container(
                                              height: 0.5,
                                              color: AppTheme.divider)),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: Text('CineVerse',
                                            style: GoogleFonts.poppins(
                                              color: AppTheme.textMuted,
                                              fontSize: 11,
                                              letterSpacing: 2,
                                            )),
                                      ),
                                      Expanded(
                                          child: Container(
                                              height: 0.5,
                                              color: AppTheme.divider)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _featurePill(
                                          Icons.movie_creation_rounded,
                                          'Movies'),
                                      const SizedBox(width: 10),
                                      _featurePill(
                                          Icons.live_tv_rounded, 'TV Shows'),
                                      const SizedBox(width: 10),
                                      _featurePill(
                                          Icons.play_circle_rounded,
                                          'Trailers'),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Your ultimate movie companion',
                                    style: GoogleFonts.poppins(
                                      color: AppTheme.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featurePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.accent, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}
