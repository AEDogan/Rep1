// reset_password_screen.dart
import 'package:flutter/material.dart';
import 'services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _handleUpdatePassword() async {
    final pass1 = _newPasswordController.text.trim();
    final pass2 = _confirmPasswordController.text.trim();

    if (pass1.isEmpty || pass2.isEmpty) {
      _showError("Lütfen yeni şifrenizi girin.");
      return;
    }

    if (pass1.length < 6) {
      _showError("Şifre en az 6 karakter olmalıdır.");
      return;
    }

    if (pass1 != pass2) {
      _showError("Şifreler birbiriyle uyuşmuyor.");
      return;
    }

    setState(() => _isLoading = true);
    final success = await AuthService().updatePassword(pass1);
    setState(() => _isLoading = false);

    if (success) {
      _showSuccess("Şifreniz başarıyla güncellendi! Giriş yapabilirsiniz.");
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } else {
      _showError(AuthService().errorMessage ?? "Şifre güncellenemedi.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Yeni Şifre Belirleme", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_reset_rounded, size: 48, color: Colors.orange),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Yeni Şifrenizi Oluşturun",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Hesabınız için lütfen en az 6 karakterden oluşan güvenli bir şifre belirleyin.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: _obscure1,
                    decoration: InputDecoration(
                      labelText: "Yeni Şifre",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure1 ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure1 = !_obscure1),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscure2,
                    decoration: InputDecoration(
                      labelText: "Yeni Şifre (Tekrar)",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure2 ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure2 = !_obscure2),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleUpdatePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text("ŞİFREYİ GÜNCELLE VE GİRİŞ YAP", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
