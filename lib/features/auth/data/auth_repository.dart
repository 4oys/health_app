import 'dart:io';

import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppleLocalAccount {
  const AppleLocalAccount({this.name, this.email});
  final String? name;
  final String? email;
}

class AppleSignInException implements Exception {
  const AppleSignInException(this.message);
  final String message;
}

class AuthRepository {
  const AuthRepository();
  static const _storage = FlutterSecureStorage();

  Future<bool> hasSession() async {
    final session = await _storage.read(key: 'session');
    if (session == 'active') return true;
    if (session != 'apple' || !Platform.isIOS) return false;
    final identifier = await _storage.read(key: 'apple_user_identifier');
    if (identifier == null) return false;
    try {
      final state = await SignInWithApple.getCredentialState(identifier);
      if (state == CredentialState.authorized) return true;
      await _storage.delete(key: 'session');
      return false;
    } catch (_) {
      // Keep local data accessible when Apple's credential check is offline.
      return true;
    }
  }

  Future<AppleLocalAccount> signInWithApple() async {
    if (!Platform.isIOS) {
      throw const AppleSignInException('Вход через Apple доступен на iPhone.');
    }
    if (await _storage.read(key: 'email') != null &&
        await _storage.read(key: 'apple_user_identifier') == null) {
      throw const AppleSignInException(
          'На этом устройстве уже создан аккаунт с почтой. Войдите в него.');
    }
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName
      ],
    );
    final identifier = credential.userIdentifier;
    if (identifier == null ||
        identifier.isEmpty ||
        credential.authorizationCode.isEmpty) {
      throw const AppleSignInException('Apple не вернула данные входа.');
    }
    final existing = await _storage.read(key: 'apple_user_identifier');
    if (existing != null && existing != identifier) {
      throw const AppleSignInException(
          'На этом устройстве уже привязан другой Apple ID.');
    }
    final state = await SignInWithApple.getCredentialState(identifier);
    if (state != CredentialState.authorized) {
      throw const AppleSignInException('Доступ через Apple не подтверждён.');
    }
    await _storage.write(key: 'apple_user_identifier', value: identifier);
    await _storage.write(key: 'session', value: 'apple');
    final name = [credential.givenName, credential.familyName]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .join(' ');
    return AppleLocalAccount(
      name: name.isEmpty ? null : name,
      email: credential.email,
    );
  }

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
