import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  const AuthRepository();
  static const _storage = FlutterSecureStorage();

  Future<bool> hasSession() async =>
      await _storage.read(key: 'session') == 'active';

  Future<void> register(String email, String password) async {
    await _storage.write(key: 'email', value: email.trim().toLowerCase());
    await _storage.write(key: 'password', value: password);
    await _storage.write(key: 'session', value: 'active');
  }

  Future<bool> signIn(String email, String password) async {
    final storedEmail = await _storage.read(key: 'email');
    final storedPassword = await _storage.read(key: 'password');
    final success =
        storedEmail == email.trim().toLowerCase() && storedPassword == password;
    if (success) await _storage.write(key: 'session', value: 'active');
    return success;
  }

  Future<void> signOut() => _storage.delete(key: 'session');
  Future<void> deleteAccount() => _storage.deleteAll();
}
