# VoiceForge Build Guide

## Prerequisites

1. **Xcode 15.0+** - Download from the Mac App Store
2. **Command Line Tools** - Run `xcode-select --install`
3. **Homebrew** - https://brew.sh

## Quick Build

```bash
cd VoiceForge
make setup
make build
```

## Manual Build

### 1. Clone whisper.cpp and Build Framework

```bash
# Clone whisper.cpp
git clone https://github.com/ggerganov/whisper.cpp.git
cd whisper.cpp

# Build the XCFramework
./prepare-xcframework.sh
cd ..
```

### 2. Copy Framework to Project

```bash
mkdir -p VoiceForge/Frameworks
cp -r whisper.cpp/build/xcframeworks/whisper.xcframework VoiceForge/Frameworks/
```

### 3. Open and Build in Xcode

```bash
open VoiceForge.xcodeproj
```

1. Select the VoiceForge scheme
2. Select "My Mac" as the destination
3. Press ⌘B to build

## Project Configuration

### Signing & Capabilities

For development:
- Select "Automatically manage signing"
- Choose your development team

For distribution:
- Use a valid Developer ID certificate
- Enable notarization

### Required Entitlements

The app requires these entitlements:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Audio Input -->
    <key>com.apple.security.device.audio-input</key>
    <true/>
    
    <!-- Network (for cloud transcription) -->
    <key>com.apple.security.network.client</key>
    <true/>
    
    <!-- Keychain Access -->
    <key>com.apple.security.keychain-access-groups</key>
    <array>
        <string>$(AppIdentifierPrefix)com.voiceforge.app</string>
    </array>
</dict>
</plist>
```

### Info.plist Keys

```xml
<!-- Microphone Usage Description -->
<key>NSMicrophoneUsageDescription</key>
<string>VoiceForge needs microphone access to record your voice for transcription.</string>

<!-- Accessibility Description -->
<key>NSAppleEventsUsageDescription</key>
<string>VoiceForge needs accessibility access for global keyboard shortcuts.</string>
```

## Dependencies

Dependencies are managed via Swift Package Manager:

| Package | Version | Purpose |
|---------|---------|---------|
| KeyboardShortcuts | 2.0+ | Custom keyboard shortcuts |
| Sparkle | 2.5+ | Auto-updates |

### Adding whisper.cpp Framework

1. In Xcode, go to Project Settings > Targets > VoiceForge
2. Under "Frameworks, Libraries, and Embedded Content"
3. Click "+" and add `whisper.xcframework`
4. Set "Embed & Sign"

## Build Configurations

### Debug
- Full debug symbols
- Disabled optimization
- Verbose logging

### Release
- Optimized for speed
- Stripped symbols
- Minimal logging

### Distribution
- Code signed with Developer ID
- Notarized for Gatekeeper
- Hardened runtime

## Creating a Release

### 1. Archive

```bash
xcodebuild archive \
    -scheme VoiceForge \
    -configuration Release \
    -archivePath ./build/VoiceForge.xcarchive
```

### 2. Export

```bash
xcodebuild -exportArchive \
    -archivePath ./build/VoiceForge.xcarchive \
    -exportPath ./build \
    -exportOptionsPlist ExportOptions.plist
```

### 3. Create DMG

```bash
create-dmg \
    --volname "VoiceForge" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "VoiceForge.app" 175 190 \
    --app-drop-link 425 190 \
    "VoiceForge.dmg" \
    "./build/VoiceForge.app"
```

### 4. Notarize

```bash
xcrun notarytool submit VoiceForge.dmg \
    --keychain-profile "VoiceForge" \
    --wait
```

## Troubleshooting

### Build Errors

**"whisper.xcframework not found"**
- Run `make setup` to download and build the framework
- Ensure the framework is in `VoiceForge/Frameworks/`

**"Signing issues"**
- Check your provisioning profile in Xcode
- Ensure your Apple Developer account is active

**"Module not found"**
- Run `File > Packages > Reset Package Caches` in Xcode
- Clean the build folder (⌘⇧K)

### Runtime Errors

**"Microphone access denied"**
- Grant access in System Settings > Privacy > Microphone

**"Accessibility access denied"**
- Grant access in System Settings > Privacy > Accessibility

**"Model loading failed"**
- Ensure sufficient disk space
- Check that the model file is not corrupted

## Performance Optimization

### Memory Usage

For optimal performance:
- Use quantized models (Q5_0) on systems with <16GB RAM
- Close other memory-intensive applications
- Pre-warm models on launch

### CPU Usage

The app uses Metal acceleration when available. For best results:
- Ensure your Mac supports Metal
- Use the latest macOS version
- Close background applications during transcription
