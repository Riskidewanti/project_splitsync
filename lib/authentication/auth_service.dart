import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_config.dart';

class SessionProfile {
  const SessionProfile({
    required this.id,
    required this.email,
    required this.username,
    required this.pinCreated,
  });

  final String id;
  final String email;
  final String username;
  final bool pinCreated;

  factory SessionProfile.fromMap(Map<String, dynamic> data) {
    final email = (data['email'] ?? '').toString();
    return SessionProfile(
      id: (data['id'] ?? data['profile_id'] ?? data['email']).toString(),
      email: email,
      username:
          (data['user_name'] ??
                  data['nama_pengguna'] ??
                  data['name'] ??
                  _nameFromEmail(email))
              .toString(),
      pinCreated: data['pin_created'] == true,
    );
  }

  static String _nameFromEmail(String email) {
    if (!email.contains('@')) return email;
    return email.split('@').first;
  }
}

class AuthService {
  AuthService._();

  static const _sessionId = 'splitsync_session_id';
  static const _sessionEmail = 'splitsync_session_email';
  static const _sessionUsername = 'splitsync_session_username';
  static const _sessionPinCreated = 'splitsync_session_pin_created';

  static StreamSubscription<String>? _fcmTokenRefreshSubscription;
  static Future<void>? _fcmInitialization;
  static bool _fcmReady = false;

  static bool get isConfigured => SupabaseConfig.isConfigured;

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<void> initialize() async {
    if (!isConfigured) return;
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
    unawaited(_initializeFcmTokenPersistence());
  }

  static Future<SessionProfile?> currentSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_sessionId);
    final email = prefs.getString(_sessionEmail);
    final username = prefs.getString(_sessionUsername);
    final pinCreated = prefs.getBool(_sessionPinCreated) ?? false;
    if (id == null || email == null || username == null) return null;
    return SessionProfile(
      id: id,
      email: email,
      username: username,
      pinCreated: pinCreated,
    );
  }

  static Future<SessionProfile> login({
    required String email,
    required String password,
  }) async {
    _guardConfiguration();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();
    if (normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
      throw const AuthException('Email dan password wajib diisi.');
    }

    final row = await _client
        .from('profiles')
        .select()
        .eq('email', normalizedEmail)
        .eq('password', normalizedPassword)
        .maybeSingle();

    if (row == null) {
      throw const AuthException('Email atau password salah.');
    }

    final profile = SessionProfile.fromMap(row);
    await _saveSession(profile);
    unawaited(_persistCurrentFcmToken(profile.email));
    return profile;
  }

  static Future<SessionProfile> register({
    required String email,
    required String username,
    required String password,
  }) async {
    _guardConfiguration();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedUsername = username.trim();
    final normalizedPassword = password.trim();
    if (normalizedEmail.isEmpty ||
        normalizedUsername.isEmpty ||
        normalizedPassword.isEmpty) {
      throw const AuthException(
        'Email, nama pengguna, dan password wajib diisi.',
      );
    }

    final existing = await _client
        .from('profiles')
        .select('email')
        .eq('email', normalizedEmail)
        .maybeSingle();

    if (existing != null) {
      throw const AuthException('Email sudah terdaftar.');
    }

    final row = await _client
        .from('profiles')
        .insert({
          'email': normalizedEmail,
          'user_name': normalizedUsername,
          'password': normalizedPassword,
        })
        .select()
        .single();

    final profile = SessionProfile(
      id: (row['id'] ?? row['email']).toString(),
      email: (row['email'] ?? normalizedEmail).toString(),
      username: (row['user_name'] ?? normalizedUsername).toString(),
      pinCreated: row['pin_created'] == true,
    );
    await _saveSession(profile);
    unawaited(_persistCurrentFcmToken(profile.email));
    return profile;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionId);
    await prefs.remove(_sessionEmail);
    await prefs.remove(_sessionUsername);
    await prefs.remove(_sessionPinCreated);
  }

  static Future<void> markPinCreated(String pin) async {
    _guardConfiguration();
    final profile = await currentSession();
    if (profile == null) return;

    await _client
        .from('profiles')
        .update({'pin_created': true, 'pin_hash': pin})
        .eq('email', profile.email);

    await _saveSession(
      SessionProfile(
        id: profile.id,
        email: profile.email,
        username: profile.username,
        pinCreated: true,
      ),
    );
  }

  static Future<void> _saveSession(SessionProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionId, profile.id);
    await prefs.setString(_sessionEmail, profile.email);
    await prefs.setString(_sessionUsername, profile.username);
    await prefs.setBool(_sessionPinCreated, profile.pinCreated);
  }

  static Future<void> _initializeFcmTokenPersistence() {
    return _fcmInitialization ??= _doInitializeFcmTokenPersistence();
  }

  static Future<void> _doInitializeFcmTokenPersistence() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _fcmReady = true;
      _fcmTokenRefreshSubscription ??=
          FirebaseMessaging.instance.onTokenRefresh.listen(
        (token) async {
          final profile = await currentSession();
          if (profile == null) return;
          await _saveFcmToken(email: profile.email, token: token);
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('FCM token refresh listener failed: $error');
        },
      );
    } catch (error, stackTrace) {
      _fcmReady = false;
      debugPrint('FCM token persistence unavailable: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> _persistCurrentFcmToken(String email) async {
    try {
      await _initializeFcmTokenPersistence();
      if (!_fcmReady) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      await _saveFcmToken(email: email, token: token);
    } catch (error, stackTrace) {
      debugPrint('Failed to persist FCM token: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> _saveFcmToken({
    required String email,
    required String token,
  }) async {
    await _client
        .from('profiles')
        .update({'fcm_token': token})
        .eq('email', email);
  }

  static void _guardConfiguration() {
    if (!isConfigured) {
      throw const AuthException(
        'Supabase belum dikonfigurasi. Tambahkan SUPABASE_URL dan SUPABASE_PUBLISHABLE_KEY.',
      );
    }
  }
}
