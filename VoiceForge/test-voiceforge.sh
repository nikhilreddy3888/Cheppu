#!/bin/bash

# VoiceForge Testing Script
# Comprehensive testing guide for VoiceForge

set -e

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════╗"
echo "║                                               ║"
echo "║         VoiceForge Testing Guide              ║"
echo "║                                               ║"
echo "╚═══════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Test 1: Check installation
echo -e "${YELLOW}[Test 1/10] Checking installation...${NC}"
if [ -d "/Applications/VoiceForge.app" ]; then
    echo -e "${GREEN}✓ VoiceForge is installed${NC}"
    APP_VERSION=$(defaults read /Applications/VoiceForge.app/Contents/Info.plist CFBundleShortVersionString 2>/dev/null || echo "Unknown")
    echo -e "  Version: ${APP_VERSION}"
else
    echo -e "${RED}✗ VoiceForge not found in /Applications${NC}"
    echo -e "${YELLOW}  Run ./build-and-install.sh first${NC}"
    exit 1
fi

# Test 2: Check models
echo -e "\n${YELLOW}[Test 2/10] Checking Whisper models...${NC}"
MODELS_DIR="$HOME/Library/Application Support/VoiceForge/Models"
if [ -d "$MODELS_DIR" ]; then
    MODEL_COUNT=$(ls -1 "$MODELS_DIR"/*.bin 2>/dev/null | wc -l | tr -d ' ')
    if [ "$MODEL_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ Found $MODEL_COUNT model(s)${NC}"
        ls -lh "$MODELS_DIR"/*.bin 2>/dev/null | awk '{print "  - " $9 " (" $5 ")"}'
    else
        echo -e "${YELLOW}⚠ No models found${NC}"
        echo -e "  Run: make download-models"
    fi
else
    echo -e "${YELLOW}⚠ Models directory not found${NC}"
    mkdir -p "$MODELS_DIR"
fi

# Test 3: Check permissions
echo -e "\n${YELLOW}[Test 3/10] Checking permissions...${NC}"

# Microphone
MIC_STATUS=$(sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db "SELECT allowed FROM access WHERE service='kTCCServiceMicrophone' AND client='com.voiceforge.app';" 2>/dev/null || echo "0")
if [ "$MIC_STATUS" = "1" ]; then
    echo -e "${GREEN}✓ Microphone permission granted${NC}"
else
    echo -e "${YELLOW}⚠ Microphone permission not granted${NC}"
    echo -e "  Grant in: System Settings > Privacy & Security > Microphone"
fi

# Accessibility
if ioreg -l | grep -q "VoiceForge"; then
    echo -e "${GREEN}✓ Accessibility permission granted${NC}"
else
    echo -e "${YELLOW}⚠ Accessibility permission not granted${NC}"
    echo -e "  Grant in: System Settings > Privacy & Security > Accessibility"
fi

# Test 4: Launch app
echo -e "\n${YELLOW}[Test 4/10] Launching VoiceForge...${NC}"
open -a VoiceForge
sleep 3

if pgrep -x "VoiceForge" > /dev/null; then
    echo -e "${GREEN}✓ VoiceForge is running${NC}"
    PID=$(pgrep -x "VoiceForge")
    echo -e "  Process ID: $PID"
else
    echo -e "${RED}✗ VoiceForge failed to launch${NC}"
    echo -e "  Check Console.app for crash logs"
fi

# Test 5: Menu bar icon
echo -e "\n${YELLOW}[Test 5/10] Checking menu bar...${NC}"
sleep 2
echo -e "${BLUE}→ Look for the VoiceForge icon in your menu bar${NC}"
echo -e "  It should show a waveform icon"
read -p "  Can you see the menu bar icon? (y/n): " MENU_BAR
if [ "$MENU_BAR" = "y" ]; then
    echo -e "${GREEN}✓ Menu bar icon visible${NC}"
else
    echo -e "${YELLOW}⚠ Menu bar icon not visible${NC}"
fi

# Test 6: Hotkey test
echo -e "\n${YELLOW}[Test 6/10] Testing hotkey...${NC}"
echo -e "${BLUE}→ Press and hold Right Command key${NC}"
echo -e "  You should see a recording indicator"
read -p "  Did the recording start? (y/n): " HOTKEY
if [ "$HOTKEY" = "y" ]; then
    echo -e "${GREEN}✓ Hotkey working${NC}"
else
    echo -e "${YELLOW}⚠ Hotkey not working${NC}"
    echo -e "  Check accessibility permissions"
fi

# Test 7: Recording test
echo -e "\n${YELLOW}[Test 7/10] Recording test...${NC}"
echo -e "${BLUE}→ Speak a test phrase:${NC}"
echo -e "  'This is a test of VoiceForge transcription'"
echo -e "${BLUE}→ Hold Right Command and speak, then release${NC}"
read -p "  Press Enter when done..."
read -p "  Was the text transcribed correctly? (y/n): " RECORDING
if [ "$RECORDING" = "y" ]; then
    echo -e "${GREEN}✓ Recording and transcription working${NC}"
else
    echo -e "${YELLOW}⚠ Transcription issue${NC}"
    echo -e "  Check that a model is loaded in settings"
fi

# Test 8: Clipboard test
echo -e "\n${YELLOW}[Test 8/10] Clipboard test...${NC}"
echo -e "${BLUE}→ The transcribed text should be in your clipboard${NC}"
CLIPBOARD=$(pbpaste)
if [ -n "$CLIPBOARD" ]; then
    echo -e "${GREEN}✓ Clipboard contains: ${CLIPBOARD:0:50}...${NC}"
else
    echo -e "${YELLOW}⚠ Clipboard is empty${NC}"
fi

# Test 9: Settings access
echo -e "\n${YELLOW}[Test 9/10] Testing settings...${NC}"
echo -e "${BLUE}→ Open VoiceForge settings (⌘,)${NC}"
read -p "  Can you access settings? (y/n): " SETTINGS
if [ "$SETTINGS" = "y" ]; then
    echo -e "${GREEN}✓ Settings accessible${NC}"
else
    echo -e "${YELLOW}⚠ Settings not accessible${NC}"
fi

# Test 10: Performance
echo -e "\n${YELLOW}[Test 10/10] Checking performance...${NC}"
if pgrep -x "VoiceForge" > /dev/null; then
    PID=$(pgrep -x "VoiceForge")
    CPU=$(ps -p $PID -o %cpu | tail -1 | tr -d ' ')
    MEM=$(ps -p $PID -o rss | tail -1 | tr -d ' ')
    MEM_MB=$((MEM / 1024))
    
    echo -e "  CPU Usage: ${CPU}%"
    echo -e "  Memory: ${MEM_MB}MB"
    
    if (( $(echo "$CPU < 10" | bc -l) )); then
        echo -e "${GREEN}✓ CPU usage normal${NC}"
    else
        echo -e "${YELLOW}⚠ High CPU usage${NC}"
    fi
    
    if [ $MEM_MB -lt 500 ]; then
        echo -e "${GREEN}✓ Memory usage normal${NC}"
    else
        echo -e "${YELLOW}⚠ High memory usage${NC}"
    fi
fi

# Summary
echo ""
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════╗"
echo "║                                               ║"
echo "║         Testing Complete!                     ║"
echo "║                                               ║"
echo "╚═══════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Try different recording modes in Settings"
echo "  2. Test AI enhancement with an API key"
echo "  3. Create custom context rules"
echo "  4. Add custom vocabulary words"
echo ""
echo -e "${YELLOW}Troubleshooting:${NC}"
echo "  • Check Console.app for errors"
echo "  • Verify all permissions are granted"
echo "  • Ensure models are downloaded"
echo "  • Restart VoiceForge if issues persist"
echo ""
echo -e "${GREEN}Enjoy using VoiceForge! 🎉${NC}"
echo ""
