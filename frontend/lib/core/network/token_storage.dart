import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _keyToken = 'asone_access_token';
  static const _keyUser = 'asone_user_json';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  Future<void> saveUserJson(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, json);
  }

  Future<String?> getUserJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUser);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }
}
