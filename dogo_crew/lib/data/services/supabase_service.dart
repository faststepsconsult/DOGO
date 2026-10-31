import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      publishableKey: AppConstants.supabaseAnonKey,
    );
  }

  static Future<String> uploadFile({
    required String bucket,
    required String path,
    required Uint8List fileBytes,
  }) async {
    await client.storage.from(bucket).uploadBinary(
      path,
      fileBytes,
      fileOptions: const FileOptions(upsert: true),
    );
    return path;
  }

  static Future<String?> getSignedUrl({
    required String bucket,
    required String path,
    int expiresIn = 3600,
  }) async {
    try {
      final signedUrl = await client.storage.from(bucket).createSignedUrl(path, expiresIn);
      return signedUrl;
    } catch (_) {
      return null;
    }
  }
}
