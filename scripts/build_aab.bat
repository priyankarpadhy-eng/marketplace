@echo off
REM ================================================
REM Flutter Build App Bundle with Environment Variables
REM ================================================
REM This script reads .env.local and passes 
REM secrets to Flutter via --dart-define
REM For Google Play Store uploads
REM ================================================

REM Load environment variables from .env.local
if not exist ".env.local" (
    echo ERROR: .env.local not found!
    echo Please copy .env.example to .env.local and fill in your secrets.
    exit /b 1
)

REM Read .env.local and build dart-define args
setlocal enabledelayedexpansion
set DART_DEFINES=

for /f "usebackq tokens=1,* delims==" %%a in (".env.local") do (
    REM Skip comments (lines starting with #)
    set "line=%%a"
    if not "!line:~0,1!"=="#" (
        if not "%%a"=="" (
            set "DART_DEFINES=!DART_DEFINES! --dart-define=%%a=%%b"
        )
    )
)

echo Building Release App Bundle with environment variables...
echo.

REM Add production flag
set DART_DEFINES=%DART_DEFINES% --dart-define=PRODUCTION=true

REM Build App Bundle with the dart-define arguments
flutter build appbundle --release %DART_DEFINES% %*

echo.
echo Build complete! AAB location: build\app\outputs\bundle\release\app-release.aab
