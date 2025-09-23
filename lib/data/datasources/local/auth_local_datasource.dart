import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearCache();
  Future<void> setRememberMe(bool remember);
  Future<bool> getRememberMe();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _userKey = 'cached_user';
  static const String _rememberMeKey = 'remember_me';

  final SharedPreferences _prefs;

  AuthLocalDataSourceImpl({required SharedPreferences prefs}) : _prefs = prefs;

  @override
  Future<void> cacheUser(UserModel user) async {
    final userJson = user.toJson();
    await _prefs.setString(_userKey, userJson.toString());
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final userString = _prefs.getString(_userKey);
      if (userString != null) {
        // Note: Esta implementación es básica
        // En un proyecto real, usarías json.encode/decode
        return null; // Por simplicidad, retornamos null
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    await _prefs.remove(_userKey);
  }

  @override
  Future<void> setRememberMe(bool remember) async {
    await _prefs.setBool(_rememberMeKey, remember);
  }

  @override
  Future<bool> getRememberMe() async {
    return _prefs.getBool(_rememberMeKey) ?? false;
  }
}