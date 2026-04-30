import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

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
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailCtrl.text.trim();

    if (!EmailValidator.validate(email)) {
      _showSnack('Please enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if email exists first
      final methods = await FirebaseAuth.instance
          .fetchSignInMethodsForEmail(email);

      if (methods.isEmpty) {
        setState(() => _isLoading = false);
        _showSnack('No account found with this email address');
        return;
      }

      // Send reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
        _animController.reset();
        _animController.forward();
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      switch (e.code) {
        case 'user-not-found':
          _showSnack('No account found with this email address');
          break;
        case 'invalid-email':
          _showSnack('Please enter a valid email address');
          break;
        case 'too-many-requests':
          _showSnack('Too many attempts. Please try again later');
          break;
        default:
          _showSnack('Something went wrong. Please try again');
      }
    } catch (_) {
      setState(() => _isLoading = false);
      _showSnack('Something went wrong. Please try again');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.splashGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.divider, width: 0.5),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppTheme.textPrimary, size: 16),
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (!_emailSent) ...[
                      // Lock icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppTheme.accent.withOpacity(0.3),
                              width: 1),
                        ),
                        child: const Center(
                          child: Icon(Icons.lock_reset_rounded,
                              color: AppTheme.accent, size: 34),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Forgot Password?',
                          style: AppTheme.headingLarge),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your email address and we\'ll send you a link to reset your password.',
                        style: AppTheme.bodyText,
                      ),
                      const SizedBox(height: 32),

                      // Email field
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppTheme.divider, width: 0.8),
                        ),
                        child: TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.poppins(
                              color: AppTheme.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Email address',
                            hintStyle: GoogleFonts.poppins(
                                color: AppTheme.textMuted, fontSize: 14),
                            prefixIcon: const Icon(
                                Icons.mail_outline_rounded,
                                color: AppTheme.textMuted,
                                size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Send button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sendResetEmail,
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
                                      'Send Reset Link',
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
                    ] else ...[
                      // Success state
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            // Success icon
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: AppTheme.success.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppTheme.success.withOpacity(0.4),
                                    width: 1.5),
                              ),
                              child: const Center(
                                child: Icon(Icons.mark_email_read_rounded,
                                    color: AppTheme.success, size: 44),
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text('Check Your Email',
                                style: AppTheme.headingLarge,
                                textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            Text(
                              'We\'ve sent a password reset link to',
                              style: AppTheme.bodyText,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _emailCtrl.text.trim(),
                              style: GoogleFonts.poppins(
                                color: AppTheme.accent,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Click the link in the email to reset your password. Check your spam folder if you don\'t see it.',
                              style: AppTheme.caption,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 40),

                            // Back to login button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
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
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Back to Login',
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
                            const SizedBox(height: 16),

                            // Resend option
                            GestureDetector(
                              onTap: () {
                                setState(() => _emailSent = false);
                                _animController.reset();
                                _animController.forward();
                              },
                              child: Text(
                                'Didn\'t receive the email? Resend',
                                style: GoogleFonts.poppins(
                                  color: AppTheme.accent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
