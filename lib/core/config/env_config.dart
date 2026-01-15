/// Environment Configuration
///
/// This class reads secrets from environment variables passed at build time.
/// Secrets are injected using --dart-define flags during compilation.
///
/// Usage:
/// ```bash
/// flutter run --dart-define=R2_ACCOUNT_ID=xxx --dart-define=R2_SECRET_KEY=xxx
/// flutter build apk --dart-define=R2_ACCOUNT_ID=xxx --dart-define=R2_SECRET_KEY=xxx
/// ```
///
/// For local development, create a `.env.local` file (gitignored) and use
/// the run configuration scripts.
class EnvConfig {
  // Private constructor - this is a utility class
  EnvConfig._();

  // ══════════════════════════════════════════════════════════════════════════
  // Cloudflare R2 Configuration
  // ══════════════════════════════════════════════════════════════════════════

  /// R2 Account ID
  static const String r2AccountId = String.fromEnvironment(
    'R2_ACCOUNT_ID',
    defaultValue: '',
  );

  /// R2 Bucket Name
  static const String r2BucketName = String.fromEnvironment(
    'R2_BUCKET_NAME',
    defaultValue: 'marketplace-social',
  );

  /// R2 Public URL for serving files
  static const String r2PublicUrl = String.fromEnvironment(
    'R2_PUBLIC_URL',
    defaultValue: '',
  );

  /// R2 Access Key ID
  static const String r2AccessKeyId = String.fromEnvironment(
    'R2_ACCESS_KEY_ID',
    defaultValue: '',
  );

  /// R2 Secret Access Key - NEVER commit this!
  static const String r2SecretAccessKey = String.fromEnvironment(
    'R2_SECRET_ACCESS_KEY',
    defaultValue: '',
  );

  // ══════════════════════════════════════════════════════════════════════════
  // Validation
  // ══════════════════════════════════════════════════════════════════════════

  /// Check if R2 configuration is complete
  static bool get isR2Configured =>
      r2AccountId.isNotEmpty &&
      r2AccessKeyId.isNotEmpty &&
      r2SecretAccessKey.isNotEmpty &&
      r2PublicUrl.isNotEmpty;

  /// Get missing R2 configuration keys (for debugging)
  static List<String> get missingR2Config {
    final missing = <String>[];
    if (r2AccountId.isEmpty) missing.add('R2_ACCOUNT_ID');
    if (r2AccessKeyId.isEmpty) missing.add('R2_ACCESS_KEY_ID');
    if (r2SecretAccessKey.isEmpty) missing.add('R2_SECRET_ACCESS_KEY');
    if (r2PublicUrl.isEmpty) missing.add('R2_PUBLIC_URL');
    return missing;
  }

  /// R2 S3-compatible endpoint (derived from account ID)
  static String get r2Endpoint => r2AccountId.isNotEmpty
      ? 'https://$r2AccountId.r2.cloudflarestorage.com'
      : '';

  // ══════════════════════════════════════════════════════════════════════════
  // Environment Detection
  // ══════════════════════════════════════════════════════════════════════════

  /// Whether we're in production mode
  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );

  /// Whether we're in debug/development mode
  static const bool isDebug = !isProduction;

  /// Print configuration status (for debugging only - never in production!)
  static void printConfigStatus() {
    if (isProduction) {
      // Never print secrets in production
      return;
    }

    print('═══════════════════════════════════════════════════════════');
    print('Environment Configuration Status');
    print('═══════════════════════════════════════════════════════════');
    print('R2 Configured: $isR2Configured');
    if (!isR2Configured) {
      print('Missing R2 keys: ${missingR2Config.join(', ')}');
    }
    print('═══════════════════════════════════════════════════════════');
  }
}
