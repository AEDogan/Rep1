// login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'providers.dart';
import 'services/auth_service.dart';
import 'services/supabase_config.dart';
import 'admin_screens.dart';
import 'operator_screens.dart';
import 'screens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 0: Giriş & Yöntem Seçimi, 1: E-posta / Şifre ile Giriş
  int _currentStep = 0;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _companyCodeController = TextEditingController();
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _companyCodeController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handlePostLoginNavigation(UserProfile user) async {
    // AppProvider'ı senkronize et
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    appProvider.updateUserProfile(
      name: user.name,
      email: user.email,
      photoUrl: user.photoUrl,
    );

    // Eğer kullanıcının henüz bir firması atanmamışsa firma kodu sor
    if (user.companyId == null) {
      final attached = await _showCompanyCodeDialog();
      if (!attached) {
        // İptal edildiyse yine de müşteri ekranına devam edebilir
      }
    }

    if (!mounted) return;

    // Role göre yönlendir
    Widget targetScreen;
    switch (user.role) {
      case UserRole.kitchen:
        targetScreen = const OperatorDashboardScreen();
        break;
      case UserRole.admin:
        targetScreen = const AdminLoginScreen();
        break;
      case UserRole.customer:
        targetScreen = const HomeScreen();
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
    );
  }

  Future<bool> _showCompanyCodeDialog() async {
    final codeCtrl = TextEditingController();
    bool joined = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.business_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text("Firma Eşleme", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Şirketinizin kahve menüsüne bağlanmak için firmanızın kodunu girin (Örn: CMP-34):",
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: "CMP-34",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Daha Sonra", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeCtrl.text.trim();
              if (code.isEmpty) return;
              final success = await AuthService().joinCompanyByCode(code);
              if (success) {
                joined = true;
                if (ctx.mounted) Navigator.pop(ctx);
              } else {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(AuthService().errorMessage ?? "Firma bulunamadı."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Bağlan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    return joined;
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final authService = AuthService();
    final success = await authService.signInWithGoogle();
    setState(() => _isLoading = false);

    if (success && authService.currentUser != null) {
      await _handlePostLoginNavigation(authService.currentUser!);
    } else if (authService.errorMessage != null) {
      _showError(authService.errorMessage!);
    }
  }

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final code = _companyCodeController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Lütfen e-posta ve şifrenizi girin.");
      return;
    }

    setState(() => _isLoading = true);
    final authService = AuthService();
    bool success;

    if (_isSignUp) {
      if (name.isEmpty) {
        setState(() => _isLoading = false);
        _showError("Lütfen adınızı ve soyadınızı girin.");
        return;
      }
      success = await authService.signUpWithEmail(
        email: email,
        password: password,
        fullName: name,
        companyCode: code.isNotEmpty ? code : null,
      );
    } else {
      success = await authService.signInWithEmail(email, password);
    }

    setState(() => _isLoading = false);

    if (success && authService.currentUser != null) {
      await _handlePostLoginNavigation(authService.currentUser!);
    } else if (authService.errorMessage != null) {
      _showError(authService.errorMessage!);
    }
  }

  void _handleDemoLogin(UserRole role) {
    final authService = AuthService();
    authService.setDemoUser(role);
    _handlePostLoginNavigation(authService.currentUser!);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep == 1) {
      return _buildEmailAuthView();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.coffee_rounded, size: 64, color: Colors.orange),
              ),
              const SizedBox(height: 24),
              const Text(
                "COMPOUND COFFEE",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
              const SizedBox(height: 6),
              Text(
                "Kurumsal & Güvenli Kahve Platformu",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 36),

              // Ana Google Giriş Butonu
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 2,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                        )
                      : const Icon(Icons.g_mobiledata, size: 34, color: Colors.blue),
                  label: Text(
                    _isLoading ? "Giriş Yapılıyor..." : "Google ile Devam Et",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // E-posta ile Giriş Butonu
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _currentStep = 1;
                    _isSignUp = false;
                  }),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.mail_outline, color: Colors.black87),
                  label: const Text(
                    "E-posta ile Giriş Yap",
                    style: TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "HIZLI TEST / ROL SEÇİMİ",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 18),

              // Demo Rol Butonları (Test Kolaylığı)
              Row(
                children: [
                  Expanded(
                    child: _QuickRoleCard(
                      icon: Icons.person_rounded,
                      title: "Müşteri",
                      subtitle: "Sipariş Ver",
                      color: Colors.orange,
                      onTap: () => _handleDemoLogin(UserRole.customer),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickRoleCard(
                      icon: Icons.soup_kitchen_rounded,
                      title: "Mutfak",
                      subtitle: "KDS Paneli",
                      color: Colors.blueGrey,
                      onTap: () => _handleDemoLogin(UserRole.kitchen),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickRoleCard(
                      icon: Icons.admin_panel_settings_rounded,
                      title: "Yönetici",
                      subtitle: "Admin",
                      color: Colors.purple.shade700,
                      onTap: () => _handleDemoLogin(UserRole.admin),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (!SupabaseConfig.isConfigured)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Geliştirici Modu Aktif: Supabase API anahtarları girilene kadar otomatik demo modunda çalışır.",
                          style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailAuthView() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _currentStep = 0),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(
          _isSignUp ? "Hesap Oluştur" : "E-posta ile Giriş",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSignUp ? "Şirketinize Katılın" : "Hoş Geldiniz",
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                _isSignUp
                    ? "Bilgilerinizi girerek şirketinize özel kahve deneyimini başlatın."
                    : "Lütfen kayıtlı e-posta ve şifrenizi girin.",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 28),

              if (_isSignUp) ...[
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Ad Soyad",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _companyCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: "Firma Kodu (İsteğe bağlı)",
                    hintText: "Örn: CMP-34",
                    prefixIcon: const Icon(Icons.business_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "E-posta Adresi",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Şifre",
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleEmailAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          _isSignUp ? "Kayıt Ol ve Giriş Yap" : "Giriş Yap",
                          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              Center(
                child: TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp
                        ? "Zaten hesabınız var mı? Giriş Yapın"
                        : "Hesabınız yok mu? Yeni Hesap Oluşturun",
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickRoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickRoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
