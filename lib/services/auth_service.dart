// services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models.dart';
import 'supabase_config.dart';

class AuthService with ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  SupabaseClient? get _client =>
      SupabaseConfig.isConfigured ? Supabase.instance.client : null;

  UserProfile? _currentUser;
  Company? _currentCompany;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? get currentUser => _currentUser;
  Company? get currentCompany => _currentCompany;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  /// Oturum durumunu geri yükler (Splash ekranda çağrılır)
  Future<UserProfile?> restoreSession() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!SupabaseConfig.isConfigured) {
        // Yapılandırma yapılmadıysa oturum yok kabul edilir (Giriş ekranına geçer)
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final session = _client?.auth.currentSession;
      if (session != null) {
        await _fetchProfileAndCompany(session.user.id);
        _isLoading = false;
        notifyListeners();
        return _currentUser;
      }
    } catch (e) {
      debugPrint("restoreSession hatası: $e");
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  /// Google ile Giriş / Kayıt
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!SupabaseConfig.isConfigured) {
        // DEMO / MOCK GİRİŞİ (Supabase anahtarları henüz girilmediğinde geliştirme amaçlı)
        await Future.delayed(const Duration(seconds: 1));
        _currentUser = UserProfile(
          id: 'demo_user_01',
          name: 'Ahmet Yılmaz (Demo)',
          email: 'ahmet@maslakhub.com',
          photoUrl: 'https://ui-avatars.com/api/?name=Ahmet+Yilmaz&background=orange&color=fff',
          companyId: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          companyName: 'Compound Coffee - Maslak Hub',
          role: UserRole.customer,
          loyaltyStamps: 6,
          freeCoffeesAvailable: 1,
        );
        _currentCompany = Company(
          id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          name: 'Compound Coffee - Maslak Hub',
          companyCode: 'CMP-34',
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Web veya Native platformlara göre Google Sign In
      if (kIsWeb) {
        await _client!.auth.signInWithOAuth(OAuthProvider.google);
        return true;
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          _isLoading = false;
          notifyListeners();
          return false; // Kullanıcı iptal etti
        }

        final googleAuth = await googleUser.authentication;
        final accessToken = googleAuth.accessToken;
        final idToken = googleAuth.idToken;

        if (idToken == null) {
          throw 'Google kimlik doğrulama tokenı alınamadı.';
        }

        final response = await _client!.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );

        if (response.user != null) {
          await _fetchProfileAndCompany(response.user!.id);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint("signInWithGoogle hatası: $e");
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// E-posta & Şifre ile Giriş
  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!SupabaseConfig.isConfigured) {
        await Future.delayed(const Duration(seconds: 1));
        _currentUser = UserProfile(
          id: 'demo_user_email',
          name: email.split('@').first,
          email: email,
          companyId: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          companyName: 'Compound Coffee - Maslak Hub',
          role: UserRole.customer,
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }

      final response = await _client!.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _fetchProfileAndCompany(response.user!.id);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("signInWithEmail hatası: $e");
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// E-posta ile Yeni Kayıt
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? companyCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!SupabaseConfig.isConfigured) {
        await Future.delayed(const Duration(seconds: 1));
        _currentUser = UserProfile(
          id: 'demo_registered_user',
          name: fullName,
          email: email,
          role: UserRole.customer,
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }

      final response = await _client!.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user != null) {
        // Eğer kullanıcı bir firma kodu girdiyse, firmayı eşle
        if (companyCode != null && companyCode.trim().isNotEmpty) {
          await joinCompanyByCode(companyCode.trim(), userId: response.user!.id);
        } else {
          await _fetchProfileAndCompany(response.user!.id);
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("signUpWithEmail hatası: $e");
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Kullanıcıyı Firma Kodu ile bir şirkete bağlar (Örn: 'CMP-34')
  Future<bool> joinCompanyByCode(String code, {String? userId}) async {
    final uid = userId ?? _currentUser?.id ?? _client?.auth.currentUser?.id;
    if (uid == null) return false;

    try {
      if (!SupabaseConfig.isConfigured) {
        _currentCompany = Company(
          id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          name: 'Compound Coffee - $code',
          companyCode: code,
        );
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(
            companyId: _currentCompany!.id,
            companyName: _currentCompany!.name,
          );
        }
        notifyListeners();
        return true;
      }

      // 1. Şirketi kod ile bul
      final companyData = await _client!
          .from('companies')
          .select()
          .eq('company_code', code.toUpperCase().trim())
          .maybeSingle();

      if (companyData == null) {
        _errorMessage = 'Geçersiz firma kodu. Lütfen kontrol edip tekrar deneyin.';
        notifyListeners();
        return false;
      }

      final company = Company.fromJson(companyData);

      // 2. Kullanıcı profilini güncelle
      await _client!
          .from('profiles')
          .update({'company_id': company.id})
          .eq('id', uid);

      _currentCompany = company;
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          companyId: company.id,
          companyName: company.name,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("joinCompanyByCode hatası: $e");
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Profil ve Şirket bilgilerini çeker
  Future<void> _fetchProfileAndCompany(String userId) async {
    if (!SupabaseConfig.isConfigured) return;

    try {
      final profileData = await _client!
          .from('profiles')
          .select('*, companies(*)')
          .eq('id', userId)
          .maybeSingle();

      if (profileData != null) {
        String? compName;
        if (profileData['companies'] != null) {
          final comp = Company.fromJson(profileData['companies']);
          _currentCompany = comp;
          compName = comp.name;
        }
        _currentUser = UserProfile.fromJson(profileData, companyName: compName);
      }
    } catch (e) {
      debugPrint("_fetchProfileAndCompany hatası: $e");
    }
  }

  /// Doğrudan belirli bir rol ile demo oturumu açar (Geliştirme & Test Kolaylığı İçin)
  void setDemoUser(UserRole role) {
    if (role == UserRole.kitchen) {
      _currentUser = UserProfile(
        id: 'demo_kitchen_01',
        name: 'Mutfak / Barista Ekibi',
        email: 'kitchen@compound.coffee',
        companyId: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        companyName: 'Compound Coffee - Maslak Hub',
        role: UserRole.kitchen,
      );
    } else if (role == UserRole.admin) {
      _currentUser = UserProfile(
        id: 'demo_admin_01',
        name: 'Şube Yöneticisi',
        email: 'admin@compound.coffee',
        companyId: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        companyName: 'Compound Coffee - Maslak Hub',
        role: UserRole.admin,
      );
    } else {
      _currentUser = UserProfile(
        id: 'demo_customer_01',
        name: 'Ahmet Yılmaz',
        email: 'ahmet@maslakhub.com',
        photoUrl: 'https://ui-avatars.com/api/?name=Ahmet+Yilmaz&background=orange&color=fff',
        companyId: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        companyName: 'Compound Coffee - Maslak Hub',
        role: UserRole.customer,
        loyaltyStamps: 6,
        freeCoffeesAvailable: 1,
      );
    }
    _currentCompany = Company(
      id: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      name: 'Compound Coffee - Maslak Hub',
      companyCode: 'CMP-34',
    );
    notifyListeners();
  }

  /// Çıkış Yap
  Future<void> signOut() async {
    try {
      if (SupabaseConfig.isConfigured) {
        await _client?.auth.signOut();
      }
    } catch (e) {
      debugPrint("signOut hatası: $e");
    }
    _currentUser = null;
    _currentCompany = null;
    notifyListeners();
  }
}
