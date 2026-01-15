import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../config/env_config.dart';

/// Configuration for Cloudflare R2
///
/// All values are read from environment variables passed at build time.
/// This ensures no secrets are stored in the codebase.
///
/// Build with:
/// ```bash
/// flutter build apk --dart-define=R2_ACCOUNT_ID=xxx \
///   --dart-define=R2_ACCESS_KEY_ID=xxx \
///   --dart-define=R2_SECRET_ACCESS_KEY=xxx \
///   --dart-define=R2_PUBLIC_URL=xxx
/// ```
class R2Config {
  // All values come from environment configuration
  static String get accountId => EnvConfig.r2AccountId;
  static String get bucketName => EnvConfig.r2BucketName;
  static String get publicUrl => EnvConfig.r2PublicUrl;
  static String get accessKeyId => EnvConfig.r2AccessKeyId;
  static String get secretAccessKey => EnvConfig.r2SecretAccessKey;
  static String get endpoint => EnvConfig.r2Endpoint;

  /// Check if R2 is properly configured
  static bool get isConfigured => EnvConfig.isR2Configured;
}

/// Upload progress callback
typedef UploadProgressCallback =
    void Function(double progress, int sent, int total);

/// Result of an upload operation
class UploadResult {
  final bool success;
  final String? url;
  final String? error;
  final String? key;

  const UploadResult({required this.success, this.url, this.error, this.key});
}

/// Cloudflare R2 Storage Service
///
/// Handles file uploads to R2 with progress tracking.
/// Uses S3-compatible API with presigned URLs for security.
class R2StorageService {
  final String _bucketName;
  final String _endpoint;
  final String _publicUrl;
  final String _accessKeyId;
  final String _secretAccessKey;
  final _uuid = const Uuid();

  R2StorageService({
    String? bucketName,
    String? endpoint,
    String? publicUrl,
    String? accessKeyId,
    String? secretAccessKey,
  }) : _bucketName = bucketName ?? R2Config.bucketName,
       _endpoint = endpoint ?? R2Config.endpoint,
       _publicUrl = publicUrl ?? R2Config.publicUrl,
       _accessKeyId = accessKeyId ?? R2Config.accessKeyId,
       _secretAccessKey = secretAccessKey ?? R2Config.secretAccessKey;

  /// Upload a file to R2 with progress tracking
  ///
  /// [fileBytes] - The file content as bytes
  /// [fileName] - Original filename (used for extension)
  /// [folder] - Folder path in bucket (e.g., 'videos', 'photos')
  /// [contentType] - MIME type of the file
  /// [onProgress] - Progress callback
  Future<UploadResult> uploadFile({
    required Uint8List fileBytes,
    required String fileName,
    required String folder,
    required String contentType,
    UploadProgressCallback? onProgress,
  }) async {
    try {
      // Generate unique key
      final extension = fileName.split('.').last;
      final uniqueKey = '$folder/${_uuid.v4()}.$extension';

      // Generate presigned URL for PUT
      final presignedUrl = _generatePresignedUrl(
        method: 'PUT',
        key: uniqueKey,
        contentType: contentType,
        expiresIn: const Duration(minutes: 15),
      );

      // Upload with progress tracking
      final success = await _uploadWithProgress(
        url: presignedUrl,
        bytes: fileBytes,
        contentType: contentType,
        onProgress: onProgress,
      );

      if (success) {
        // Construct public URL
        final publicUrl = '$_publicUrl/$uniqueKey';

        return UploadResult(success: true, url: publicUrl, key: uniqueKey);
      } else {
        return const UploadResult(success: false, error: 'Upload failed');
      }
    } catch (e) {
      debugPrint('R2 Upload Error: $e');
      return UploadResult(success: false, error: e.toString());
    }
  }

  /// Upload file from File path (for mobile)
  Future<UploadResult> uploadFromFile({
    required File file,
    required String folder,
    required String contentType,
    UploadProgressCallback? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    final fileName = file.path.split('/').last;

    return uploadFile(
      fileBytes: bytes,
      fileName: fileName,
      folder: folder,
      contentType: contentType,
      onProgress: onProgress,
    );
  }

  /// Upload with progress tracking using streamed request
  Future<bool> _uploadWithProgress({
    required String url,
    required Uint8List bytes,
    required String contentType,
    UploadProgressCallback? onProgress,
  }) async {
    try {
      final request = http.Request('PUT', Uri.parse(url));
      request.headers['Content-Type'] = contentType;
      request.headers['Content-Length'] = bytes.length.toString();

      // For progress tracking, we need to send in chunks
      final client = http.Client();

      try {
        // Simple approach - send all bytes at once
        // For very large files, consider chunked upload
        request.bodyBytes = bytes;

        // Report initial progress
        onProgress?.call(0.0, 0, bytes.length);

        final streamedResponse = await client.send(request);

        // Report completion
        onProgress?.call(1.0, bytes.length, bytes.length);

        final response = await http.Response.fromStream(streamedResponse);

        return response.statusCode == 200 || response.statusCode == 201;
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      return false;
    }
  }

  /// Generate AWS Signature V4 presigned URL
  /// This is compatible with Cloudflare R2's S3 API
  String _generatePresignedUrl({
    required String method,
    required String key,
    required String contentType,
    required Duration expiresIn,
  }) {
    final now = DateTime.now().toUtc();
    final dateStamp = _formatDateStamp(now);
    final amzDate = _formatAmzDate(now);
    final expiresSeconds = expiresIn.inSeconds;

    final host = Uri.parse(_endpoint).host;
    final region = 'auto'; // R2 uses 'auto' region
    const service = 's3';

    // Canonical request components
    final canonicalUri = '/$_bucketName/$key';
    final canonicalQueryString = _buildCanonicalQueryString(
      amzDate: amzDate,
      dateStamp: dateStamp,
      expiresSeconds: expiresSeconds,
      region: region,
    );

    final canonicalHeaders = 'host:$host\n';
    const signedHeaders = 'host';

    final canonicalRequest = [
      method,
      canonicalUri,
      canonicalQueryString,
      canonicalHeaders,
      signedHeaders,
      'UNSIGNED-PAYLOAD',
    ].join('\n');

    // String to sign
    final credentialScope = '$dateStamp/$region/$service/aws4_request';
    final stringToSign = [
      'AWS4-HMAC-SHA256',
      amzDate,
      credentialScope,
      sha256.convert(utf8.encode(canonicalRequest)).toString(),
    ].join('\n');

    // Calculate signature
    final signature = _calculateSignature(
      stringToSign: stringToSign,
      secretKey: _secretAccessKey,
      dateStamp: dateStamp,
      region: region,
      service: service,
    );

    // Build final URL
    return '$_endpoint/$_bucketName/$key?$canonicalQueryString&X-Amz-Signature=$signature';
  }

  String _buildCanonicalQueryString({
    required String amzDate,
    required String dateStamp,
    required int expiresSeconds,
    required String region,
  }) {
    final params = {
      'X-Amz-Algorithm': 'AWS4-HMAC-SHA256',
      'X-Amz-Credential': Uri.encodeComponent(
        '$_accessKeyId/$dateStamp/$region/s3/aws4_request',
      ),
      'X-Amz-Date': amzDate,
      'X-Amz-Expires': expiresSeconds.toString(),
      'X-Amz-SignedHeaders': 'host',
    };

    final sortedKeys = params.keys.toList()..sort();
    return sortedKeys.map((k) => '$k=${params[k]}').join('&');
  }

  String _calculateSignature({
    required String stringToSign,
    required String secretKey,
    required String dateStamp,
    required String region,
    required String service,
  }) {
    final kDate = _hmacSha256(utf8.encode('AWS4$secretKey'), dateStamp);
    final kRegion = _hmacSha256(kDate, region);
    final kService = _hmacSha256(kRegion, service);
    final kSigning = _hmacSha256(kService, 'aws4_request');

    return _hmacSha256Hex(kSigning, stringToSign);
  }

  List<int> _hmacSha256(List<int> key, String data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(data)).bytes;
  }

  String _hmacSha256Hex(List<int> key, String data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(data)).toString();
  }

  String _formatDateStamp(DateTime date) {
    return '${date.year}${_pad(date.month)}${_pad(date.day)}';
  }

  String _formatAmzDate(DateTime date) {
    return '${_formatDateStamp(date)}T${_pad(date.hour)}${_pad(date.minute)}${_pad(date.second)}Z';
  }

  String _pad(int value) => value.toString().padLeft(2, '0');

  /// Delete a file from R2
  Future<bool> deleteFile(String key) async {
    try {
      final presignedUrl = _generatePresignedUrl(
        method: 'DELETE',
        key: key,
        contentType: '',
        expiresIn: const Duration(minutes: 5),
      );

      final response = await http.delete(Uri.parse(presignedUrl));
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      debugPrint('R2 Delete Error: $e');
      return false;
    }
  }

  /// Get public URL for a file
  String getPublicUrl(String key) {
    return '$_publicUrl/$key';
  }
}

/// Helper class for tracking upload state
class UploadState {
  final double progress;
  final int bytesSent;
  final int totalBytes;
  final bool isComplete;
  final bool hasError;
  final String? errorMessage;
  final String? resultUrl;

  const UploadState({
    this.progress = 0.0,
    this.bytesSent = 0,
    this.totalBytes = 0,
    this.isComplete = false,
    this.hasError = false,
    this.errorMessage,
    this.resultUrl,
  });

  UploadState copyWith({
    double? progress,
    int? bytesSent,
    int? totalBytes,
    bool? isComplete,
    bool? hasError,
    String? errorMessage,
    String? resultUrl,
  }) {
    return UploadState(
      progress: progress ?? this.progress,
      bytesSent: bytesSent ?? this.bytesSent,
      totalBytes: totalBytes ?? this.totalBytes,
      isComplete: isComplete ?? this.isComplete,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      resultUrl: resultUrl ?? this.resultUrl,
    );
  }

  String get progressText {
    if (totalBytes == 0) return '0%';
    return '${(progress * 100).toStringAsFixed(0)}%';
  }

  String get bytesText {
    if (totalBytes == 0) return '0 KB';
    final sentMB = bytesSent / (1024 * 1024);
    final totalMB = totalBytes / (1024 * 1024);
    return '${sentMB.toStringAsFixed(1)} / ${totalMB.toStringAsFixed(1)} MB';
  }
}
