import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'auth_screen.dart';

class ManageAccountScreen extends StatefulWidget {
  const ManageAccountScreen({super.key});

  @override
  State<ManageAccountScreen> createState() => _ManageAccountScreenState();
}

class _ManageAccountScreenState extends State<ManageAccountScreen> {
  final _auth = FirebaseAuth.instance;
  String _username = '';
  String _email = '';
  bool _isEditingUsername = false;
  final _usernameCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = _auth.currentUser;
    if (mounted) {
      setState(() {
        _username = prefs.getString('username') ?? user?.displayName ?? '';
        _email = user?.email ?? prefs.getString('email') ?? '';
        _usernameCtrl.text = _username;
      });
    }
  }

  Future<void> _saveUsername() async {
    if (_usernameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await _auth.currentUser?.updateDisplayName(_usernameCtrl.text.trim());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', _usernameCtrl.text.trim());
      if (mounted) {
        setState(() {
          _username = _usernameCtrl.text.trim();
          _isEditingUsername = false;
          _loading = false;
        });
        _showSnack('Username updated!', AppTheme.success);
        // Pass new username back to profile screen
        Navigator.pop(context, _usernameCtrl.text.trim());
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showSnack('Failed to update username', AppTheme.error);
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    try {
      await _auth.sendPasswordResetEmail(email: _email);
      _showSnack('Password reset email sent to $_email', AppTheme.success);
    } catch (e) {
      _showSnack('Failed to send reset email', AppTheme.error);
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Account',
            style: GoogleFonts.poppins(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          'This will permanently delete your account and all your data. This cannot be undone.',
          style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: GoogleFonts.poppins(
                    color: AppTheme.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _auth.currentUser?.delete();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AuthScreen()),
            (_) => false,
          );
        }
      } catch (e) {
        _showSnack('Please re-login and try again', AppTheme.error);
      }
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.divider, width: 0.5),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textPrimary, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text('Manage Account', style: AppTheme.headingMedium),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Center(
                      child: Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.goldGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent.withOpacity(0.3),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _username.isNotEmpty
                                ? _username[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Username section
                    _sectionLabel('Username'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.divider, width: 0.5),
                      ),
                      child: _isEditingUsername
                          ? Column(
                              children: [
                                TextField(
                                  controller: _usernameCtrl,
                                  style: GoogleFonts.poppins(
                                      color: AppTheme.textPrimary, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Enter new username',
                                    hintStyle: GoogleFonts.poppins(
                                        color: AppTheme.textMuted, fontSize: 14),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(
                                            () => _isEditingUsername = false),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: AppTheme.surface,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Center(
                                            child: Text('Cancel',
                                                style: GoogleFonts.poppins(
                                                    color: AppTheme.textMuted,
                                                    fontSize: 13)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: _loading ? null : _saveUsername,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            gradient: AppTheme.goldGradient,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Center(
                                            child: _loading
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: Colors.black))
                                                : Text('Save',
                                                    style: GoogleFonts.poppins(
                                                        color: Colors.black,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w700)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                const Icon(Icons.person_outline_rounded,
                                    color: AppTheme.textMuted, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(_username,
                                      style: GoogleFonts.poppins(
                                          color: AppTheme.textPrimary,
                                          fontSize: 14)),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _isEditingUsername = true),
                                  child: const Icon(Icons.edit_rounded,
                                      color: AppTheme.accent, size: 18),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Email section
                    _sectionLabel('Email'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.divider, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mail_outline_rounded,
                              color: AppTheme.textMuted, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_email,
                                style: GoogleFonts.poppins(
                                    color: AppTheme.textPrimary, fontSize: 14)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Verified',
                                style: GoogleFonts.poppins(
                                    color: AppTheme.success,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Security section
                    _sectionLabel('Security'),
                    const SizedBox(height: 8),
                    _actionItem(
                      icon: Icons.lock_reset_rounded,
                      label: 'Change Password',
                      subtitle: 'Send reset link to your email',
                      color: AppTheme.accent,
                      onTap: _sendPasswordReset,
                    ),
                    const SizedBox(height: 24),

                    // Danger zone
                    _sectionLabel('Danger Zone'),
                    const SizedBox(height: 8),
                    _actionItem(
                      icon: Icons.delete_forever_rounded,
                      label: 'Delete Account',
                      subtitle: 'Permanently delete your account and data',
                      color: AppTheme.error,
                      onTap: _deleteAccount,
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textMuted,
          letterSpacing: 0.5,
        ),
      );

  Widget _actionItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.poppins(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          color: AppTheme.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
