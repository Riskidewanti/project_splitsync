import 'dart:async';
import 'dart:typed_data';

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

class ProfileDetails {
  const ProfileDetails({
    required this.id,
    required this.userName,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.pinCreated,
    required this.createdAt,
    required this.updatedAt,
    required this.groupCount,
    required this.totalSharedExpense,
  });

  final String id;
  final String userName;
  final String email;
  final String phone;
  final String avatarUrl;
  final bool pinCreated;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int groupCount;
  final num totalSharedExpense;

  factory ProfileDetails.fromMap(
    Map<String, dynamic> data, {
    int groupCount = 0,
    num totalSharedExpense = 0,
  }) {
    final email = (data['email'] ?? '').toString();
    return ProfileDetails(
      id: (data['id'] ?? '').toString(),
      userName: (data['user_name'] ?? SessionProfile._nameFromEmail(email))
          .toString(),
      email: email,
      phone: (data['phone'] ?? '').toString(),
      avatarUrl: (data['avatar_url'] ?? '').toString(),
      pinCreated: data['pin_created'] == true,
      createdAt: DateTime.tryParse((data['created_at'] ?? '').toString()),
      updatedAt: DateTime.tryParse((data['updated_at'] ?? '').toString()),
      groupCount: groupCount,
      totalSharedExpense: totalSharedExpense,
    );
  }
}

class AuthService {
  AuthService._();

  static const _avatarBucket = 'avatars';
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
    try {
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
    } catch (e, stackTrace) {
      debugPrint('Failed to restore current session: $e');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
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
    if (profile == null) {
      throw const AuthException(
        'Session tidak ditemukan. Silakan login ulang.',
      );
    }

    final updated = await _client
        .from('profiles')
        .update({'pin_created': true, 'pin_hash': pin})
        .eq('email', profile.email)
        .select('id,email,user_name,pin_created')
        .maybeSingle();

    if (updated == null) {
      throw const AuthException(
        'PIN belum tersimpan ke database. Periksa policy UPDATE tabel profiles.',
      );
    }

    await _saveSession(
      SessionProfile(
        id: (updated['id'] ?? profile.id).toString(),
        email: (updated['email'] ?? profile.email).toString(),
        username: (updated['user_name'] ?? profile.username).toString(),
        pinCreated: updated['pin_created'] == true,
      ),
    );
  }

  static Future<ProfileDetails> fetchCurrentProfile() async {
    _guardConfiguration();
    final session = await currentSession();
    if (session == null) {
      throw const AuthException(
        'Session tidak ditemukan. Silakan login ulang.',
      );
    }

    final row = await _client
        .from('profiles')
        .select(
          'id,user_name,email,avatar_url,phone,pin_created,created_at,updated_at',
        )
        .eq('email', session.email)
        .maybeSingle();

    if (row == null) {
      throw const AuthException('Data profil tidak ditemukan.');
    }

    final groupIds = await _fetchJoinedGroupIds((row['id'] ?? '').toString());
    final details = ProfileDetails.fromMap(
      row,
      groupCount: groupIds.length,
      totalSharedExpense: await _fetchTotalSharedExpense(groupIds),
    );
    await _saveSession(
      SessionProfile(
        id: details.id,
        email: details.email,
        username: details.userName,
        pinCreated: details.pinCreated,
      ),
    );
    return details;
  }

  static Future<ProfileDetails> updateCurrentProfile({
    required String userName,
    required String email,
    required String phone,
  }) async {
    _guardConfiguration();
    final session = await currentSession();
    if (session == null) {
      throw const AuthException(
        'Session tidak ditemukan. Silakan login ulang.',
      );
    }

    final normalizedEmail = email.trim().toLowerCase();
    final normalizedUserName = userName.trim();
    final normalizedPhone = phone.trim();
    if (normalizedUserName.isEmpty || normalizedEmail.isEmpty) {
      throw const AuthException('Nama dan email wajib diisi.');
    }

    var row = await _client
        .from('profiles')
        .update({
          'user_name': normalizedUserName,
          'email': normalizedEmail,
          'phone': normalizedPhone,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', session.id)
        .select(
          'id,user_name,email,avatar_url,phone,pin_created,created_at,updated_at',
        )
        .maybeSingle();

    row ??= await _client
        .from('profiles')
        .update({
          'user_name': normalizedUserName,
          'email': normalizedEmail,
          'phone': normalizedPhone,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('email', session.email)
        .select(
          'id,user_name,email,avatar_url,phone,pin_created,created_at,updated_at',
        )
        .maybeSingle();

    if (row == null) {
      throw const AuthException(
        'Profil belum tersimpan. Periksa policy UPDATE tabel profiles.',
      );
    }

    final groupIds = await _fetchJoinedGroupIds((row['id'] ?? '').toString());
    final details = ProfileDetails.fromMap(
      row,
      groupCount: groupIds.length,
      totalSharedExpense: await _fetchTotalSharedExpense(groupIds),
    );
    await _saveSession(
      SessionProfile(
        id: details.id,
        email: details.email,
        username: details.userName,
        pinCreated: details.pinCreated,
      ),
    );
    return details;
  }

  static Future<ProfileDetails> updateCurrentProfilePhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    _guardConfiguration();
    final session = await currentSession();
    if (session == null) {
      throw const AuthException(
        'Session tidak ditemukan. Silakan login ulang.',
      );
    }
    if (bytes.isEmpty) {
      throw const AuthException('File foto tidak boleh kosong.');
    }

    final extension = _fileExtension(fileName);
    final path =
        '${session.id}/profile_${DateTime.now().millisecondsSinceEpoch}.$extension';
    try {
      await _client.storage
          .from(_avatarBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              cacheControl: '3600',
              contentType: _contentType(extension),
            ),
          );
    } on StorageException catch (error) {
      final isMissingBucket =
          error.statusCode == '404' ||
          error.message.toLowerCase().contains('bucket not found');
      if (isMissingBucket) {
        throw const AuthException(
          'Bucket Storage "avatars" belum ada di Supabase. Buat bucket avatars terlebih dahulu.',
        );
      }
      final isUnauthorized =
          error.statusCode == '403' ||
          error.message.toLowerCase().contains('row-level security') ||
          error.error?.toLowerCase().contains('unauthorized') == true;
      if (isUnauthorized) {
        throw const AuthException(
          'Upload foto ditolak oleh policy Storage. Izinkan INSERT/SELECT/UPDATE untuk bucket avatars di Supabase.',
        );
      }
      rethrow;
    }

    final avatarUrl = _client.storage.from(_avatarBucket).getPublicUrl(path);
    var row = await _client
        .from('profiles')
        .update({
          'avatar_url': avatarUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', session.id)
        .select(
          'id,user_name,email,avatar_url,phone,pin_created,created_at,updated_at',
        )
        .maybeSingle();

    row ??= await _client
        .from('profiles')
        .update({
          'avatar_url': avatarUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('email', session.email)
        .select(
          'id,user_name,email,avatar_url,phone,pin_created,created_at,updated_at',
        )
        .maybeSingle();

    if (row == null) {
      throw const AuthException(
        'Foto profil belum tersimpan. Periksa policy UPDATE tabel profiles.',
      );
    }

    final groupIds = await _fetchJoinedGroupIds((row['id'] ?? '').toString());
    final details = ProfileDetails.fromMap(
      row,
      groupCount: groupIds.length,
      totalSharedExpense: await _fetchTotalSharedExpense(groupIds),
    );
    await _saveSession(
      SessionProfile(
        id: details.id,
        email: details.email,
        username: details.userName,
        pinCreated: details.pinCreated,
      ),
    );
    return details;
  }

  static Future<List<String>> _fetchJoinedGroupIds(String profileId) async {
    if (profileId.isEmpty) return const [];

    try {
      final rows = await _client
          .from('group_members')
          .select('group_id')
          .eq('user_id', profileId);

      final ids = <String>{};
      for (final row in rows) {
        final id = row['group_id'];
        if (id != null && id.toString().isNotEmpty) {
          ids.add(id.toString());
        }
      }
      return ids.toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<num> _fetchTotalSharedExpense(List<String> groupIds) async {
    if (groupIds.isEmpty) return 0;

    try {
      final rows = await _client
          .from('expenses')
          .select('total_amount')
          .inFilter('group_id', groupIds);

      num total = 0;
      for (final row in rows) {
        final amount = row['total_amount'];
        if (amount is num) {
          total += amount;
        } else if (amount != null) {
          total += num.tryParse(amount.toString()) ?? 0;
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> _saveSession(SessionProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionId, profile.id);
    await prefs.setString(_sessionEmail, profile.email);
    await prefs.setString(_sessionUsername, profile.username);
    await prefs.setBool(_sessionPinCreated, profile.pinCreated);
  }

  static String _fileExtension(String fileName) {
    final lower = fileName.toLowerCase();
    final parts = lower.split('.');
    final extension = parts.length > 1 ? parts.last : 'jpg';
    if (extension == 'jpeg' || extension == 'jpg' || extension == 'png') {
      return extension;
    }
    return 'jpg';
  }

  static String _contentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'jpeg':
      case 'jpg':
      default:
        return 'image/jpeg';
    }
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
      _fcmTokenRefreshSubscription ??= FirebaseMessaging
          .instance
          .onTokenRefresh
          .listen(
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
    await _client.from('profiles').update({'fcm_token': token}).eq(
      'email',
      email,
    );
  }

  static void _guardConfiguration() {
    if (!isConfigured) {
      throw const AuthException(
        'Supabase belum dikonfigurasi. Tambahkan SUPABASE_URL dan SUPABASE_PUBLISHABLE_KEY.',
      );
    }
  }
}
