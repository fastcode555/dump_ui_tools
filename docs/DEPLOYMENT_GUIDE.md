# Android UI Analyzer Tool - Deployment Guide

## Overview

This guide covers the deployment process for the Android UI Analyzer Tool, including build configuration, code signing, and distribution for macOS.

## Prerequisites

### Development Environment
- macOS 10.15 or later
- Xcode 12.0 or later
- Flutter SDK 3.7.2 or later
- Valid Apple Developer Account (for distribution)

### Build Tools
- FVM (Flutter Version Management) - recommended
- CocoaPods (for iOS/macOS dependencies)
- Git (for version control)

## Build Configuration

### Debug Build
For development and testing:

```bash
# Clean previous builds
flutter clean
flutter pub get

# Build debug version
flutter build macos --debug

# Output location: build/macos/Build/Products/Debug/
```

### Release Build
For production distribution:

```bash
# Clean and prepare
flutter clean
flutter pub get

# Build release version with optimizations
flutter build macos --release --split-debug-info=debug-symbols

# Output location: build/macos/Build/Products/Release/
```

### Build Options

#### Performance Optimizations
```bash
# Enable tree shaking and minification
flutter build macos --release --tree-shake-icons --split-debug-info=debug-symbols

# Profile build for performance testing
flutter build macos --profile
```

#### Custom Build Configurations
```bash
# Build with custom target
flutter build macos --target=lib/main_production.dart

# Build with specific flavor
flutter build macos --flavor=production
```

## Code Signing (macOS)

### Development Signing
For local development and testing:

1. Open `macos/Runner.xcworkspace` in Xcode
2. Select the Runner project
3. Go to "Signing & Capabilities"
4. Select your development team
5. Choose "Automatically manage signing"

### Distribution Signing
For App Store or direct distribution:

#### App Store Distribution
1. Create App Store Connect record
2. Configure provisioning profiles
3. Set signing identity in Xcode:
   - Team: Your Apple Developer Team
   - Signing Certificate: Apple Distribution
   - Provisioning Profile: App Store

#### Direct Distribution (Outside App Store)
1. Create Developer ID certificate
2. Configure for direct distribution:
   - Team: Your Apple Developer Team  
   - Signing Certificate: Developer ID Application
   - Enable Hardened Runtime
   - Configure entitlements

### Entitlements Configuration
Create `macos/Runner/Release.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
</dict>
</plist>
```

## Notarization (macOS)

### Automatic Notarization
Configure Xcode for automatic notarization:

1. Archive the application in Xcode
2. Select "Distribute App"
3. Choose distribution method
4. Enable "Upload your app's symbols"
5. Enable "Manage Version and Build Number"
6. Submit for notarization

### Manual Notarization
For command-line notarization:

```bash
# Create app bundle
flutter build macos --release

# Create ZIP archive
cd build/macos/Build/Products/Release/
zip -r AndroidUIAnalyzer.zip AndroidUIAnalyzer.app

# Submit for notarization
xcrun notarytool submit AndroidUIAnalyzer.zip \
  --apple-id "your-apple-id@example.com" \
  --password "app-specific-password" \
  --team-id "YOUR_TEAM_ID" \
  --wait

# Staple notarization ticket
xcrun stapler staple AndroidUIAnalyzer.app
```

## Distribution Methods

### App Store Distribution

#### Preparation
1. Create App Store Connect record
2. Configure app metadata and screenshots
3. Set up pricing and availability
4. Configure App Store review information

#### Submission Process
```bash
# Build for App Store
flutter build macos --release

# Archive in Xcode
# 1. Open macos/Runner.xcworkspace
# 2. Product > Archive
# 3. Distribute App > App Store Connect
# 4. Upload and submit for review
```

### Direct Distribution

#### DMG Creation
Create a disk image for distribution:

```bash
# Install create-dmg tool
brew install create-dmg

# Create DMG
create-dmg \
  --volname "Android UI Analyzer" \
  --volicon "assets/app_icon.icns" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "AndroidUIAnalyzer.app" 175 120 \
  --hide-extension "AndroidUIAnalyzer.app" \
  --app-drop-link 425 120 \
  "AndroidUIAnalyzer.dmg" \
  "build/macos/Build/Products/Release/"
```

#### PKG Installer
Create a package installer:

```bash
# Build installer package
pkgbuild \
  --root "build/macos/Build/Products/Release/AndroidUIAnalyzer.app" \
  --identifier "com.example.androiduianalyzer" \
  --version "1.0.0" \
  --install-location "/Applications" \
  "AndroidUIAnalyzer.pkg"

# Sign the package
productsign \
  --sign "Developer ID Installer: Your Name" \
  "AndroidUIAnalyzer.pkg" \
  "AndroidUIAnalyzer-signed.pkg"
```

## Version Management

### Version Configuration
Update version in `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

### Build Number Management
For automated builds:

```bash
# Get current build number
BUILD_NUMBER=$(git rev-list --count HEAD)

# Build with specific build number
flutter build macos --build-number=$BUILD_NUMBER
```

### Release Tagging
```bash
# Create release tag
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

## Automated Deployment

### GitHub Actions Workflow
Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy macOS App

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.7.2'
        
    - name: Install dependencies
      run: flutter pub get
      
    - name: Run tests
      run: flutter test
      
    - name: Build macOS app
      run: flutter build macos --release
      
    - name: Create DMG
      run: |
        brew install create-dmg
        create-dmg \
          --volname "Android UI Analyzer" \
          --window-size 600 400 \
          --app-drop-link 425 120 \
          "AndroidUIAnalyzer.dmg" \
          "build/macos/Build/Products/Release/"
          
    - name: Upload Release Asset
      uses: actions/upload-release-asset@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        upload_url: ${{ github.event.release.upload_url }}
        asset_path: ./AndroidUIAnalyzer.dmg
        asset_name: AndroidUIAnalyzer.dmg
        asset_content_type: application/octet-stream
```

### CI/CD Pipeline
For continuous deployment:

1. **Testing Stage**: Run all tests
2. **Build Stage**: Create release builds
3. **Sign Stage**: Code sign and notarize
4. **Package Stage**: Create distribution packages
5. **Deploy Stage**: Upload to distribution channels

## Quality Assurance

### Pre-Release Checklist
- [ ] All tests passing
- [ ] Performance benchmarks met
- [ ] Security scan completed
- [ ] Code signing verified
- [ ] Notarization successful
- [ ] Installation testing on clean system
- [ ] User acceptance testing completed

### Testing Environments
1. **Development**: Local development machines
2. **Staging**: Clean macOS installations
3. **Production**: End-user environments

### Rollback Procedures
1. Keep previous version available
2. Document rollback steps
3. Monitor deployment metrics
4. Have emergency contact procedures

## Monitoring and Analytics

### Crash Reporting
Integrate crash reporting service:

```dart
// In main.dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'YOUR_SENTRY_DSN';
    },
    appRunner: () => runApp(MyApp()),
  );
}
```

### Usage Analytics
Add analytics tracking:

```dart
// Track feature usage
Analytics.track('ui_dump_captured', {
  'device_type': device.model,
  'elements_count': elementCount,
});
```

### Performance Monitoring
Monitor key metrics:
- App startup time
- UI dump processing time
- Memory usage
- Crash rates

## Security Considerations

### Code Protection
- Enable code obfuscation for release builds
- Remove debug symbols from production
- Implement certificate pinning for network requests

### Data Protection
- Encrypt sensitive data at rest
- Secure temporary file handling
- Implement secure file permissions

### Network Security
- Use HTTPS for all network communications
- Validate all external inputs
- Implement proper error handling

## Troubleshooting

### Common Build Issues

#### Code Signing Errors
```bash
# Clear derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Reset keychain
security delete-keychain login.keychain
security create-keychain -p "" login.keychain
```

#### Flutter Build Issues
```bash
# Clean Flutter cache
flutter clean
flutter pub cache repair

# Reset Flutter
flutter doctor --verbose
```

#### Notarization Failures
- Check entitlements configuration
- Verify code signing certificates
- Review notarization logs

### Support Resources
- Apple Developer Documentation
- Flutter macOS Documentation
- Community Forums and Stack Overflow

## Maintenance

### Regular Updates
- Monitor Flutter SDK updates
- Update dependencies regularly
- Review security advisories
- Test with new macOS versions

### Backup Procedures
- Backup signing certificates
- Store provisioning profiles
- Maintain build environment documentation

---

*This deployment guide provides comprehensive instructions for building, signing, and distributing the Android UI Analyzer Tool on macOS. Follow security best practices and test thoroughly before production deployment.*