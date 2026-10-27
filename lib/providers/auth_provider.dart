import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String _errorMessage = '';

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isTeacher => _user?.isTeacher ?? false;
  bool get isStudent => _user?.isStudent ?? false;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser == null) {
        _status = AuthStatus.unauthenticated;
        _user = null;
      } else {
        try {
          _user = await _authService.getCurrentUserModel();
          _status = _user != null
              ? AuthStatus.authenticated
              : AuthStatus.unauthenticated;
        } catch (e) {
          _status = AuthStatus.unauthenticated;
          _user = null;
        }
      }
      notifyListeners();
    });
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    required String classId,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = '';
      notifyListeners();

      _user = await _authService.signUp(
        email: email,
        password: password,
        name: name,
        role: role,
        classId: classId,
      );

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = '';
      notifyListeners();

      _user = await _authService.signIn(
        email: email,
        password: password,
      );

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = '';
      notifyListeners();

      await _authService.resetPassword(email);

      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Update teacher's display name and clear needsNameSetup flag
  Future<bool> updateTeacherName(String newName) async {
    if (_user == null) return false;
    try {
      _user = _user!.copyWith(name: newName, needsNameSetup: false);
      await _authService.updateUserProfile(_user!);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
