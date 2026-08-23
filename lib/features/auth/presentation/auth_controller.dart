import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';
import '../domain/current_profile.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  static const _autoLoginKey = 'student_auto_login';

  final AuthRepository _repository;

  bool _isInitializing = true;
  bool _isLoading = false;
  String? _errorMessage;
  CurrentProfile? _profile;

  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  CurrentProfile? get profile => _profile;
  Session? get session => _repository.currentSession;
  bool get isSignedIn => session != null && _profile != null;

  Future<void> initialize() async {
    _isInitializing = true;
    _errorMessage = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final autoLogin = prefs.getBool(_autoLoginKey) ?? false;

      if (!autoLogin && _repository.currentSession != null) {
        await _repository.signOut();
      }

      if (_repository.currentSession == null) {
        _profile = null;
        return;
      }

      _profile = await _repository.fetchCurrentProfile();
    } on AuthFailure catch (error) {
      _profile = null;
      await _repository.signOut();
      _errorMessage = error.message;
    } catch (_) {
      _profile = null;
      await _repository.signOut();
      _errorMessage = '로그인 정보를 확인하지 못했습니다.';
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({
    required String name,
    required String pin,
    bool rememberSession = false,
  }) async {
    if (_isLoading) {
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.signInWithNameAndPin(
        name: name,
        pin: pin,
      );

      _profile = await _repository.fetchCurrentProfile();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoLoginKey, rememberSession);

      return true;
    } on AuthFailure catch (error) {
      _profile = null;
      if (_repository.currentSession != null) {
        await _repository.signOut();
      }
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _profile = null;
      if (_repository.currentSession != null) {
        await _repository.signOut();
      }
      _errorMessage = '로그인 중 알 수 없는 오류가 발생했습니다.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoLoginKey, false);

    _profile = null;
    _errorMessage = null;
    notifyListeners();
  }
}
