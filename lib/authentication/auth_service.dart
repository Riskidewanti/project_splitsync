import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionProfile {
  const SessionProfile({
    required this.id,
    required this.email,
    required this.username,
  });

  final String id;
  final String email;
  final String username;

  factory SessionProfile.fromMap(Map<String, dynamic> data) {
    return SessionProfile(
      id: (data['id'] ?? data['profile_id'] ?? data['email']).toString(),
      email: (data['email'] ?? '').toString(),
      username: (data['username'] ?? data['nama_pengguna'] ?? '').toString(),
    );
  }
}

class AuthService {
  AuthService._();

  static const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _sessionId = 'splitsync_session_id';
  static const _sessionEmail = 'splitsync_session_email';
  static const _sessionUsername = 'splitsync_session_username';

  static bool get isConfigured =>
      _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<void> initialize() async {
    if (!isConfigured) return;
    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabaseAnonKey,
    );
  }

  static Future<SessionProfile?> currentSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_sessionId);
    final email = prefs.getString(_sessionEmail);
    final username = prefs.getString(_sessionUsername);
    if (id == null || email == null || username == null) return null;
    return SessionProfile(id: id, email: email, username: username);
  }

  static Future<SessionProfile> login({
    required String email,
    required String password,
  }) async {
    _guardConfiguration();
    final row = await _client
        .from('profiles')
        .select()
        .eq('email', email.trim())
        .eq('password', password)
        .maybeSingle();

    if (row == null) {
      throw const AuthException('Email atau password salah.');
    }

    final profile = SessionProfile.fromMap(row);
    await _saveSession(profile);
    return profile;
  }

  static Future<SessionProfile> register({
    required String email,
    required String username,
    required String password,
  }) async {
    _guardConfiguration();
    final existing = await _client
        .from('profiles')
        .select('email')
        .eq('email', email.trim())
        .maybeSingle();

    if (existing != null) {
      throw const AuthException('Email sudah terdaftar.');
    }

    final row = await _client
        .from('profiles')
        .insert({
          'email': email.trim(),
          'username': username.trim(),
          'password': password,
        })
        .select()
        .single();

    final profile = SessionProfile.fromMap(row);
    await _saveSession(profile);
    return profile;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionId);
    await prefs.remove(_sessionEmail);
    await prefs.remove(_sessionUsername);
  }

  static Future<void> _saveSession(SessionProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionId, profile.id);
    await prefs.setString(_sessionEmail, profile.email);
    await prefs.setString(_sessionUsername, profile.username);
  }

  static void _guardConfiguration() {
    if (!isConfigured) {
      throw const AuthException(
        'Supabase belum dikonfigurasi. Tambahkan SUPABASE_URL dan SUPABASE_ANON_KEY.',
      );
    }
  }
}
