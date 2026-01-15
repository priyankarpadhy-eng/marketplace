# 🔐 Secrets Management Guide

This document explains how secrets are managed in the Marketplace app to keep them secure.

## Overview

**NEVER commit secrets to Git!** All sensitive credentials are:
1. Stored in gitignored files locally
2. Passed at build time via `--dart-define` flags
3. Read from environment variables in the code

## Quick Setup

### 1. Create your local environment file

```bash
# Copy the example file
copy .env.example .env.local

# Edit .env.local with your actual secrets
notepad .env.local
```

### 2. Fill in your secrets in `.env.local`:

```properties
# Cloudflare R2 Configuration
R2_ACCOUNT_ID=your_account_id_here
R2_BUCKET_NAME=marketplace-social
R2_PUBLIC_URL=https://your-public-url.r2.dev
R2_ACCESS_KEY_ID=your_access_key_id_here
R2_SECRET_ACCESS_KEY=your_secret_access_key_here

# Production Flag
PRODUCTION=false
```

### 3. Create keystore credentials

Create `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

## Running the App

### Option 1: VS Code (Recommended)
1. Open VS Code
2. Press `F5` or go to Run → Start Debugging
3. Select "marketplace (debug)" configuration
4. Environment variables are loaded automatically from `.env.local`

### Option 2: Command Line Scripts

```bash
# Run in debug mode
scripts\run_dev.bat

# Build release APK
scripts\build_apk.bat

# Build App Bundle for Play Store
scripts\build_aab.bat
```

### Option 3: Manual Flutter Commands

```bash
# Run with environment variables
flutter run --dart-define-from-file=.env.local

# Build APK with environment variables
flutter build apk --release --dart-define-from-file=.env.local --dart-define=PRODUCTION=true

# Build App Bundle
flutter build appbundle --release --dart-define-from-file=.env.local --dart-define=PRODUCTION=true
```

## Files Structure

```
marketplace/
├── .env.example          # Template (committed to Git)
├── .env.local            # Your secrets (GITIGNORED)
├── .gitignore            # Protects secret files
├── android/
│   ├── key.properties    # Signing secrets (GITIGNORED)
│   └── app/
│       └── upload-keystore.jks  # Keystore (GITIGNORED)
├── lib/
│   └── core/
│       └── config/
│           └── env_config.dart  # Reads environment variables
└── scripts/
    ├── run_dev.bat       # Run with secrets
    ├── build_apk.bat     # Build APK with secrets
    └── build_aab.bat     # Build AAB with secrets
```

## Security Checklist

✅ `.env.local` is in `.gitignore`  
✅ `key.properties` is in `.gitignore`  
✅ `*.jks` and `*.keystore` are in `.gitignore`  
✅ No hardcoded secrets in Dart code  
✅ Firebase service account keys are gitignored  

## CI/CD Setup

For GitHub Actions or other CI/CD, use repository secrets:

```yaml
# .github/workflows/build.yml
jobs:
  build:
    steps:
      - name: Build APK
        run: |
          flutter build apk --release \
            --dart-define=R2_ACCOUNT_ID=${{ secrets.R2_ACCOUNT_ID }} \
            --dart-define=R2_ACCESS_KEY_ID=${{ secrets.R2_ACCESS_KEY_ID }} \
            --dart-define=R2_SECRET_ACCESS_KEY=${{ secrets.R2_SECRET_ACCESS_KEY }} \
            --dart-define=R2_PUBLIC_URL=${{ secrets.R2_PUBLIC_URL }} \
            --dart-define=PRODUCTION=true
```

## Rotating Secrets

If you suspect a secret has been exposed:

1. **R2 Credentials**: Generate new API tokens in Cloudflare Dashboard
2. **Keystore**: You cannot change the keystore for existing Play Store apps
3. Update `.env.local` with new values
4. Update CI/CD secrets

## Troubleshooting

### "R2 not configured" error
- Make sure `.env.local` exists with valid values
- Run `EnvConfig.printConfigStatus()` in debug mode to see what's missing

### Build failing with secret errors
- Ensure you're using a run script or VS Code launch config
- Check that `.env.local` has no syntax errors (no spaces around `=`)

---

⚠️ **Remember**: If you accidentally commit secrets, they're exposed FOREVER in Git history. Always double-check before pushing!
