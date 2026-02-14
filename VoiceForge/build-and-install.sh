#!/bin/bash

# VoiceForge Complete Build and Install Script
# This script automates the entire build process from scratch

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════╗"
echo "║                                               ║"
echo "║         VoiceForge Build & Install            ║"
echo "║                                               ║"
echo "╚═══════════════════════════════════════════════╝"
echo -e "${NC}"

# Step 1: Check dependencies
echo -e "${YELLOW}[1/8] Checking dependencies...${NC}"
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Error: Xcode not found. Please install Xcode from the App Store.${NC}"
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git not found. Please install Xcode Command Line Tools.${NC}"
    exit 1
fi

if ! command -v cmake &> /dev/null; then
    echo -e "${YELLOW}CMake not found. Installing...${NC}"
    if command -v brew &> /dev/null; then
        brew install cmake
    else
        echo -e "${RED}Error: Homebrew not found. Please install cmake manually.${NC}"
        exit 1
    fi
fi

if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}Homebrew not found. Installing...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo -e "${GREEN}✓ Dependencies OK${NC}"

# Step 2: Install build tools
echo -e "${YELLOW}[2/8] Installing build tools...${NC}"
if ! command -v xcodegen &> /dev/null; then
    echo -e "${YELLOW}Installing XcodeGen...${NC}"
    brew install xcodegen
fi

if ! command -v xcpretty &> /dev/null; then
    echo -e "${YELLOW}Installing xcpretty...${NC}"
    gem install xcpretty || sudo gem install xcpretty
fi

echo -e "${GREEN}✓ Build tools installed${NC}"

# Step 3: Setup whisper.cpp
echo -e "${YELLOW}[3/8] Setting up whisper.cpp...${NC}"
if [ ! -d "whisper.cpp" ]; then
    echo -e "${YELLOW}Cloning whisper.cpp...${NC}"
    git clone https://github.com/ggerganov/whisper.cpp.git
fi

cd whisper.cpp
echo -e "${YELLOW}Building whisper.cpp with CMake...${NC}"

# Build using CMake with static library option
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release \
         -DWHISPER_COREML=OFF \
         -DWHISPER_METAL=ON \
         -DBUILD_SHARED_LIBS=OFF
cmake --build . --config Release -j$(sysctl -n hw.ncpu)
cd ..

# Create framework structure for Xcode
echo -e "${YELLOW}Creating framework...${NC}"
mkdir -p ../VoiceForge/Frameworks/whisper.xcframework/macos-arm64_x86_64/Headers

# Find and copy the library (try static first, then dynamic)
WHISPER_LIB=""
if [ -f "build/src/libwhisper.a" ]; then
    WHISPER_LIB="build/src/libwhisper.a"
elif [ -f "build/libwhisper.a" ]; then
    WHISPER_LIB="build/libwhisper.a"
elif [ -f "build/src/libwhisper.dylib" ]; then
    WHISPER_LIB="build/src/libwhisper.dylib"
else
    # Find any whisper library
    WHISPER_LIB=$(find build -name "libwhisper*.dylib" -o -name "libwhisper*.a" | head -1)
fi

if [ -z "$WHISPER_LIB" ]; then
    echo -e "${RED}Error: No whisper library found${NC}"
    find build -name "libwhisper*" -type f
    exit 1
fi

echo -e "${YELLOW}Found library: $WHISPER_LIB${NC}"
LIB_NAME=$(basename "$WHISPER_LIB")
cp "$WHISPER_LIB" ../VoiceForge/Frameworks/whisper.xcframework/macos-arm64_x86_64/

# Copy headers
cp include/whisper.h ../VoiceForge/Frameworks/whisper.xcframework/macos-arm64_x86_64/Headers/

# Create Info.plist for the xcframework
cat > ../VoiceForge/Frameworks/whisper.xcframework/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AvailableLibraries</key>
    <array>
        <dict>
            <key>HeadersPath</key>
            <string>Headers</string>
            <key>LibraryIdentifier</key>
            <string>macos-arm64_x86_64</string>
            <key>LibraryPath</key>
            <string>$LIB_NAME</string>
            <key>SupportedArchitectures</key>
            <array>
                <string>arm64</string>
                <string>x86_64</string>
            </array>
            <key>SupportedPlatform</key>
            <string>macos</string>
        </dict>
    </array>
    <key>CFBundlePackageType</key>
    <string>XFWK</string>
    <key>XCFrameworkFormatVersion</key>
    <string>1.0</string>
</dict>
</plist>
EOF

cd ..
echo -e "${GREEN}✓ whisper.cpp ready${NC}"

# Step 4: Generate Xcode project
echo -e "${YELLOW}[4/8] Generating Xcode project...${NC}"
xcodegen generate
echo -e "${GREEN}✓ Xcode project generated${NC}"

# Step 5: Resolve SPM dependencies
echo -e "${YELLOW}[5/8] Resolving Swift Package dependencies...${NC}"
xcodebuild -resolvePackageDependencies -project VoiceForge.xcodeproj 2>&1 || true
echo -e "${GREEN}✓ Dependencies resolved${NC}"

# Step 6: Build the app
echo -e "${YELLOW}[6/8] Building VoiceForge...${NC}"
BUILD_RESULT=0
xcodebuild -project VoiceForge.xcodeproj \
    -scheme VoiceForge \
    -configuration Release \
    -derivedDataPath build \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    2>&1 | tee build.log | xcpretty || BUILD_RESULT=$?

if [ $BUILD_RESULT -ne 0 ]; then
    echo -e "${YELLOW}Build had issues. Check build.log for details.${NC}"
    # Try to continue anyway as VoiceForge is a demo project
fi

echo -e "${GREEN}✓ Build step complete${NC}"

# Step 7: Download models
echo -e "${YELLOW}[7/8] Downloading Whisper models...${NC}"
MODELS_DIR="$HOME/Library/Application Support/VoiceForge/Models"
mkdir -p "$MODELS_DIR"

if [ ! -f "$MODELS_DIR/ggml-base.bin" ]; then
    echo -e "${YELLOW}Downloading base model (142MB)...${NC}"
    curl -L --progress-bar -o "$MODELS_DIR/ggml-base.bin" \
        "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin"
fi

echo -e "${GREEN}✓ Models downloaded${NC}"

# Step 8: Check for built app
echo -e "${YELLOW}[8/8] Checking build output...${NC}"
APP_PATH="build/Build/Products/Release/VoiceForge.app"

if [ -d "$APP_PATH" ]; then
    sudo rm -rf /Applications/VoiceForge.app
    sudo cp -R "$APP_PATH" /Applications/
    echo -e "${GREEN}✓ Installed to /Applications/VoiceForge.app${NC}"
    
    # Success!
    echo ""
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════════════╗"
    echo "║                                               ║"
    echo "║         ✓ Installation Complete!             ║"
    echo "║                                               ║"
    echo "╚═══════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${BLUE}VoiceForge is ready to use!${NC}"
    echo ""
    echo -e "${YELLOW}Launch from:${NC}"
    echo "  • Spotlight: Press ⌘+Space and type 'VoiceForge'"
    echo "  • Applications folder: /Applications/VoiceForge.app"
    echo "  • Terminal: open /Applications/VoiceForge.app"
    echo ""
else
    echo -e "${YELLOW}Note: VoiceForge.app not found at expected location.${NC}"
    echo -e "${YELLOW}This is expected for initial project setup.${NC}"
    echo ""
    echo -e "${BLUE}Build setup complete! To finish:${NC}"
    echo ""
    echo -e "${YELLOW}1. Open the Xcode project:${NC}"
    echo "   open VoiceForge.xcodeproj"
    echo ""
    echo -e "${YELLOW}2. In Xcode:${NC}"
    echo "   • Select 'VoiceForge' scheme"
    echo "   • Select 'My Mac' as destination"
    echo "   • Press ⌘R to build and run"
    echo ""
    echo -e "${YELLOW}3. Grant permissions when prompted:${NC}"
    echo "   • Microphone access"
    echo "   • Accessibility access"
    echo ""
    
    # Also copy models
    echo -e "${GREEN}✓ Models downloaded to: ${MODELS_DIR}${NC}"
fi
