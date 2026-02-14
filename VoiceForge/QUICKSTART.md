# 🚀 VoiceForge - Quick Start Guide

## One-Command Installation

```bash
cd /Users/nikhilreddy/Documents/Voice2Txt/VoiceInk/VoiceForge
./build-and-install.sh
```

This single command will:
1. ✅ Check and install dependencies (Homebrew, XcodeGen, etc.)
2. ✅ Clone and build whisper.cpp
3. ✅ Generate Xcode project
4. ✅ Build VoiceForge
5. ✅ Download AI models (base + large-v3-turbo)
6. ✅ Install to /Applications

**Time:** ~10-15 minutes (depending on internet speed)

---

## Testing Your Installation

After installation completes, run the test script:

```bash
./test-voiceforge.sh
```

This will verify:
- ✓ App installation
- ✓ Models downloaded
- ✓ Permissions granted
- ✓ Recording works
- ✓ Transcription works
- ✓ Clipboard integration
- ✓ Performance metrics

---

## First-Time Setup

### 1. Launch VoiceForge

```bash
open /Applications/VoiceForge.app
```

Or press `⌘+Space` and type "VoiceForge"

### 2. Grant Permissions

When prompted, grant:

**Microphone Access**
- Required for recording
- System Settings > Privacy & Security > Microphone

**Accessibility Access**
- Required for global hotkeys
- System Settings > Privacy & Security > Accessibility

### 3. Complete Onboarding

The app will guide you through:
1. Permission setup
2. Model selection (base model is pre-downloaded)
3. Hotkey configuration (default: Right Command)
4. Quick test recording

### 4. Start Using!

**Basic Usage:**
1. Hold **Right Command** key
2. Speak your text
3. Release key
4. Text is automatically copied to clipboard and pasted

---

## Quick Reference

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Right Command (hold) | Record audio |
| ⌘⇧R | Toggle recording |
| ⌘, | Open settings |
| Esc | Cancel recording |

### Recording Modes

**Toggle Mode**
- Press once to start, press again to stop

**Hold-to-Talk** (Default)
- Hold key to record, release to transcribe

**Push-to-Talk**
- Quick tap toggles, hold for continuous

Change in: Settings > Shortcuts > Recording Mode

---

## Configuration

### Transcription Models

Models are stored in: `~/Library/Application Support/VoiceForge/Models`

| Model | Size | Speed | Accuracy | Best For |
|-------|------|-------|----------|----------|
| ggml-base.bin | 142MB | ★★★★☆ | ★★★☆☆ | General use (pre-installed) |
| ggml-large-v3-turbo-q5_0.bin | 547MB | ★★★★☆ | ★★★★★ | Best quality (pre-installed) |

Download more models:
```bash
make download-models
```

### AI Enhancement (Optional)

To enable AI enhancement:

1. Open Settings > AI Enhancement
2. Select provider (Groq recommended)
3. Add API key
4. Choose enhancement prompt

**Free Options:**
- **Groq** - Fast, generous free tier
- **Ollama** - Completely local, no API key needed

---

## Troubleshooting

### App Won't Launch

```bash
# Check if app exists
ls -la /Applications/VoiceForge.app

# Check Console for errors
open /Applications/Utilities/Console.app
```

### Recording Not Working

1. Check microphone permission:
   - System Settings > Privacy & Security > Microphone
   - Enable for VoiceForge

2. Check accessibility permission:
   - System Settings > Privacy & Security > Accessibility
   - Enable for VoiceForge

3. Test microphone:
   ```bash
   # Record a test
   rec -r 16000 -c 1 test.wav
   ```

### No Transcription Output

1. Verify model is loaded:
   - Open Settings > Transcription
   - Check selected model

2. Check model files:
   ```bash
   ls -lh ~/Library/Application\ Support/VoiceForge/Models/
   ```

3. Re-download models:
   ```bash
   cd /Users/nikhilreddy/Documents/Voice2Txt/VoiceInk/VoiceForge
   make download-models
   ```

### High CPU/Memory Usage

1. Use a smaller model (base instead of large)
2. Disable AI enhancement if not needed
3. Close other applications during transcription

### Hotkey Not Working

1. Check accessibility permission
2. Try a different modifier key in Settings
3. Restart VoiceForge

---

## Advanced Usage

### Custom Vocabulary

Add technical terms, names, or acronyms:

1. Settings > Dictionary
2. Add custom words
3. They'll be recognized in transcriptions

### Context Rules (Power Mode)

Auto-switch settings based on app:

1. Settings > Context
2. Create new rule
3. Set conditions (app, URL, time)
4. Configure settings for that context

### Cloud Transcription

For faster/more accurate transcription:

1. Settings > Transcription
2. Select "Cloud" or "Hybrid" mode
3. Add API key for provider (Groq, Deepgram, OpenAI)

---

## Building from Source

If you want to modify the code:

```bash
# Edit source files in VoiceForge/VoiceForge/

# Rebuild
make clean
make build

# Or use Xcode
open VoiceForge.xcodeproj
```

---

## Uninstallation

```bash
# Remove app
sudo rm -rf /Applications/VoiceForge.app

# Remove data (optional)
rm -rf ~/Library/Application\ Support/VoiceForge
rm -rf ~/Library/Preferences/com.voiceforge.app.plist
```

---

## Support

- **Issues**: Check Console.app for error logs
- **Performance**: Use Activity Monitor to check resource usage
- **Updates**: Check for updates in app menu

---

## What's Next?

1. **Try AI Enhancement** - Add a Groq API key for smart text processing
2. **Create Context Rules** - Auto-switch settings per app
3. **Customize Hotkeys** - Find your perfect recording trigger
4. **Add Vocabulary** - Improve accuracy for your domain

Enjoy VoiceForge! 🎉
