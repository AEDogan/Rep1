// login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'providers.dart';
import 'services/auth_service.dart';
import 'admin_screens.dart';
import 'operator_screens.dart';
import 'screens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 0: Müşteri Girişi, 1: Müşteri Kayıt Ol
  int _activeTab = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _companyCodeController = TextEditingController();

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
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: "TAMAM",
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handlePostLoginNavigation(UserProfile user) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    appProvider.updateUserProfile(
      name: user.name,
      email: user.email,
      photoUrl: user.photoUrl,
    );

    // Eğer kullanıcının firması eşleşmemişse firma kodu sor
    if (user.companyId == null && user.role == UserRole.customer) {
      await _showCompanyCodeDialog();
    }

    if (!mounted) return;

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

  /// Firma Kodu Sorma Penceresi
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

  /// Google ile Giriş / Kayıt
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

  /// E-posta ile Giriş veya Kayıt
  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final companyCode = _companyCodeController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Lütfen e-posta ve şifrenizi girin.");
      return;
    }

    if (_activeTab == 1 && name.isEmpty) {
      _showError("Lütfen adınızı ve soyadınızı girin.");
      return;
    }

    setState(() => _isLoading = true);
    final authService = AuthService();
    bool success;

    if (_activeTab == 1) {
      // Kayıt Ol
      success = await authService.signUpWithEmail(
        email: email,
        password: password,
        fullName: name,
        companyCode: companyCode.isNotEmpty ? companyCode : null,
      );
      if (success) {
        _showSuccess("Hesabınız oluşturuldu!");
      }
    } else {
      // Giriş Yap
      success = await authService.signInWithEmail(email, password);
    }

    setState(() => _isLoading = false);

    if (success && authService.currentUser != null) {
      await _handlePostLoginNavigation(authService.currentUser!);
    } else if (authService.errorMessage != null) {
      _showError(authService.errorMessage!);
    }
  }

  /// Şifremi Unuttum Modalı (E-posta ile Sıfırlama)
  void _showForgotPasswordSheet() {
    final resetEmailCtrl = TextEditingController(text: _emailController.text.trim());
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 28,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_reset_rounded, color: Colors.orange, size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Şifremi Unuttum",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Hesabınıza bağlı e-posta adresinizi girin. Size tek tıkla şifrenizi yenileyebileceğiniz güvenli bir sıfırlama bağlantısı göndereceğiz.",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: resetEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "E-posta Adresi",
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSending
                          ? null
                          : () async {
                              final email = resetEmailCtrl.text.trim();
                              if (email.isEmpty) {
                                _showError("Lütfen e-posta adresinizi girin.");
                                return;
                              }
                              setSheetState(() => isSending = true);
                              final success = await AuthService().sendPasswordResetEmail(email);
                              setSheetState(() => isSending = false);

                              if (ctx.mounted) Navigator.pop(ctx);

                              if (success) {
                                _showSuccess("Şifre sıfırlama bağlantısı $email adresine gönderildi! ✉️");
                              } else {
                                _showError(AuthService().errorMessage ?? "Sıfırlama e-postası gönderilemedi.");
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              "Sıfırlama Bağlantısı Gönder",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Dükkan Sahibi / Personel / Yönetici Girişi Penceresi
  void _showStaffLoginDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Colors.blueGrey),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "İşletme & Personel",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "Mutfak KDS ekranı ve mağaza yönetim paneli için giriş yapın:",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),

              // Mutfak / KDS Butonu
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                leading: const Icon(Icons.soup_kitchen_rounded, color: Colors.blueGrey, size: 30),
                title: const Text("Mutfak / KDS Ekranı", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: const Text("Canlı sipariş takibi & hazırlama", style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  AuthService().setDemoUser(UserRole.kitchen);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OperatorDashboardScreen()));
                },
              ),
              const SizedBox(height: 12),

              // Yönetici Paneli Butonu
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                leading: Icon(Icons.admin_panel_settings_rounded, color: Colors.purple.shade700, size: 30),
                title: const Text("Yönetici (Admin) Paneli", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: const Text("Menü, stok, fiyat ve raporlar", style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLoginScreen()));
                },
              ),
              const SizedBox(height: 12),

              // Yeni İşletme / Şube Kaydı Butonu
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.orange.shade300),
                ),
                tileColor: Colors.orange.shade50.withValues(alpha: 0.5),
                leading: const Icon(Icons.add_business_rounded, color: Colors.orange, size: 30),
                title: const Text("Yeni İşletme / Şube Kaydı", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.deepOrange)),
                subtitle: const Text("Yeni kafe / ofis açın ve yönetici olun", style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.deepOrange),
                onTap: () {
                  Navigator.pop(ctx);
                  _showNewCompanyRegistrationDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Yeni İşletme ve Yönetici Kayıt Formu
  void _showNewCompanyRegistrationDialog() {
    final compNameCtrl = TextEditingController();
    final compCodeCtrl = TextEditingController();
    final adminNameCtrl = TextEditingController();
    final adminEmailCtrl = TextEditingController();
    final adminPassCtrl = TextEditingController();
    final domainsCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                          child: const Icon(Icons.add_business_rounded, color: Colors.orange, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Yeni İşletme Kaydı", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text("Şirketinizi ekleyin ve anında yönetici olun", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // İşletme Bilgileri
                    TextField(
                      controller: compNameCtrl,
                      decoration: InputDecoration(
                        labelText: "İşletme / Şirket Adı *",
                        hintText: "Örn: Kolektif House Maslak",
                        prefixIcon: const Icon(Icons.business_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: compCodeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: "Firma Kodu * (Müşteri Giriş Kodu)",
                        hintText: "Örn: KLK-34",
                        prefixIcon: const Icon(Icons.qr_code_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: domainsCtrl,
                      decoration: InputDecoration(
                        labelText: "Şirket E-posta Uzantısı (İsteğe bağlı)",
                        hintText: "Örn: @kolektif.com",
                        prefixIcon: const Icon(Icons.alternate_email_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const Divider(height: 28),

                    const Text("Yönetici (Admin) Hesabı", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),

                    TextField(
                      controller: adminNameCtrl,
                      decoration: InputDecoration(
                        labelText: "Yetkili Ad Soyad *",
                        hintText: "Örn: Ahmet Yılmaz",
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: adminEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Yetkili E-posta *",
                        hintText: "admin@sirket.com",
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: adminPassCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Şifre (En az 6 karakter) *",
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final compName = compNameCtrl.text.trim();
                                final compCode = compCodeCtrl.text.trim();
                                final adminName = adminNameCtrl.text.trim();
                                final adminEmail = adminEmailCtrl.text.trim();
                                final adminPass = adminPassCtrl.text.trim();
                                final rawDomains = domainsCtrl.text.trim();

                                if (compName.isEmpty || compCode.isEmpty || adminName.isEmpty || adminEmail.isEmpty || adminPass.isEmpty) {
                                  _showError("Lütfen tüm zorunlu (*) alanları doldurun.");
                                  return;
                                }

                                if (adminPass.length < 6) {
                                  _showError("Şifre en az 6 karakter olmalıdır.");
                                  return;
                                }

                                final allowedDomains = rawDomains.isNotEmpty
                                    ? rawDomains.split(',').map((d) => d.trim()).where((d) => d.isNotEmpty).toList()
                                    : <String>[];

                                setSheetState(() => isSubmitting = true);

                                final success = await AuthService().registerNewCompanyWithAdmin(
                                  companyName: compName,
                                  companyCode: compCode,
                                  adminEmail: adminEmail,
                                  adminPassword: adminPass,
                                  adminName: adminName,
                                  allowedDomains: allowedDomains,
                                );

                                setSheetState(() => isSubmitting = false);

                                if (success) {
                                  if (ctx.mounted) Navigator.pop(ctx);

                                  final auth = AuthService();
                                  final companyId = auth.currentCompany?.id ?? auth.currentUser?.companyId;
                                  if (companyId != null && mounted) {
                                    Provider.of<AppProvider>(context, listen: false).loadCompanyData(companyId);
                                  }

                                  _showSuccess("🎉 $compName işletmeniz başarıyla oluşturuldu! Yönetici paneline yönlendiriliyorsunuz...");
                                  if (mounted) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                                    );
                                  }
                                } else {
                                  final err = AuthService().errorMessage ?? "İşletme kaydı oluşturulamadı.";
                                  if (ctx.mounted) {
                                    showDialog(
                                      context: ctx,
                                      builder: (errCtx) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        title: Row(
                                          children: const [
                                            Icon(Icons.error_outline, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text("Kayıt Başarısız", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        content: Text(
                                          err,
                                          style: const TextStyle(fontSize: 14, height: 1.4),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(errCtx),
                                            child: const Text("TAMAM", style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  _showError(err);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                "İŞLETMEYİ OLUŞTUR VE YÖNETİCİ GİRİŞİ YAP",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Sağ Üst Köşedeki Zarif Personel / İşletme Butonu
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: TextButton.icon(
              onPressed: _showStaffLoginDialog,
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueGrey.shade800,
                backgroundColor: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.storefront_outlined, size: 18, color: Colors.blueGrey),
              label: const Text(
                "İşletme Girişi",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo & Karşılama
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.coffee_rounded, size: 52, color: Colors.orange),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "COMPOUND COFFEE",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Şirketinize Özel Hızlı Kahve Deneyimi",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Sekme Değiştirici (Giriş Yap / Kayıt Ol)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _activeTab == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _activeTab == 0
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              "Giriş Yap",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _activeTab == 0 ? Colors.orange : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _activeTab == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _activeTab == 1
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              "Yeni Kayıt",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _activeTab == 1 ? Colors.orange : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Google ile Giriş Butonu
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 1.5,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                        )
                      : const GoogleLogo(size: 24),
                  label: Text(
                    _activeTab == 0 ? "Google ile Giriş Yap" : "Google ile Kayıt Ol",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Ayırıcı Çizgi
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "veya e-posta ile",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 20),

              // Kayıt Formu Ek Alanları
              if (_activeTab == 1) ...[
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
                const SizedBox(height: 14),
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
                const SizedBox(height: 14),
              ],

              // E-posta Alanı
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
              const SizedBox(height: 14),

              // Şifre Alanı
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Şifre",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),

              // Şifremi Unuttum Butonu (Sadece Giriş Yap sekmesinde)
              if (_activeTab == 0)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordSheet,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      "Şifremi Unuttum?",
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Ana Gönder Butonu
              SizedBox(
                width: double.infinity,
                height: 54,
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
                          _activeTab == 0 ? "Giriş Yap" : "Hesap Oluştur",
                          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 18),

              // Alt Bilgi / Geçiş
              Center(
                child: GestureDetector(
                  onTap: () => setState(() => _activeTab = _activeTab == 0 ? 1 : 0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        children: [
                          TextSpan(
                            text: _activeTab == 0
                                ? "Hesabınız yok mu? "
                                : "Zaten hesabınız var mı? ",
                          ),
                          TextSpan(
                            text: _activeTab == 0 ? "Hemen Kayıt Olun" : "Giriş Yapın",
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class GoogleLogo extends StatelessWidget {
  final double size;
  const GoogleLogo({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png',
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) => CustomPaint(
        size: Size(size, size),
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;
    final strokeWidth = w * 0.20;

    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Top arc (Red)
    canvas.drawArc(rect, -3.14159 * 0.75, 3.14159 * 0.55, false, redPaint);
    // Right arc (Blue)
    canvas.drawArc(rect, -3.14159 * 0.20, 3.14159 * 0.35, false, bluePaint);
    // Bottom arc (Green)
    canvas.drawArc(rect, 3.14159 * 0.15, 3.14159 * 0.55, false, greenPaint);
    // Left arc (Yellow)
    canvas.drawArc(rect, 3.14159 * 0.70, 3.14159 * 0.55, false, yellowPaint);

    // Horizontal blue bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(center.dx - strokeWidth * 0.1, center.dy - strokeWidth / 2, radius * 0.95, strokeWidth),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
