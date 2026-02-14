# VoiceForge

The most powerful voice-to-text application for macOS.

## Features

### 🎤 Intelligent Transcription
- **Local Processing**: Fast, private transcription using whisper.cpp
- **Cloud Enhancement**: Optional cloud transcription with 8+ providers
- **Hybrid Mode**: Best of both worlds - local speed with cloud accuracy
- **Adaptive Routing**: Automatically chooses the best engine based on context

### 🧠 AI Enhancement
- **Multi-Provider Support**: Groq, OpenAI, Anthropic, Gemini, Ollama
- **Custom Prompts**: Create and save your own enhancement prompts
- **Context-Aware**: AI adapts based on the active application
- **Vocabulary Integration**: Custom words improve accuracy

### ⌨️ Hotkey System
- **Modifier Keys**: Right Command, Option, Control, Shift, or Fn
- **Multiple Modes**: Toggle, Hold-to-Talk, Push-to-Talk
- **Custom Shortcuts**: Define your own keyboard shortcuts
- **Gaming Mode**: Works even in fullscreen applications

### 🎯 Context Awareness (Power Mode 2.0)
- **App Detection**: Automatically adjust settings per application
- **URL Matching**: Different prompts for different websites
- **Temporal Rules**: Settings that change based on time of day
- **Learning Mode**: Learns your preferences over time

### 🔒 Privacy First
- **Zero Cloud by Default**: All processing happens locally
- **PII Detection**: Automatic redaction of sensitive information
- **Secure Storage**: API keys stored in macOS Keychain
- **Audit Logging**: Track all data access

## Requirements

- macOS 14.0 (Sonoma) or later
- 8GB RAM minimum (16GB recommended for larger models)
- 2GB free disk space for models

## Installation

### Direct Download
Download the latest `.dmg` from the [Releases](https://github.com/voiceforge/voiceforge/releases) page.

### Build from Source

```bash
# Clone the repository
git clone https://github.com/voiceforge/voiceforge.git
cd voiceforge/VoiceForge

# Download whisper.cpp framework
make setup

# Open in Xcode
open VoiceForge.xcodeproj
```

## Quick Start

1. **Launch VoiceForge**
2. **Complete the onboarding** to grant permissions and download a model
3. **Hold Right Command** to record, release to transcribe
4. Text is automatically copied to clipboard and pasted

## Configuration

### Transcription Models

| Model | Size | Speed | Accuracy | Best For |
|-------|------|-------|----------|----------|
| Tiny | 75MB | ★★★★★ | ★★☆☆☆ | Quick notes |
| Base | 142MB | ★★★★☆ | ★★★☆☆ | General use |
| Small | 466MB | ★★★☆☆ | ★★★★☆ | Longer recordings |
| Large v3 Turbo | 1.5GB | ★★★★☆ | ★★★★★ | Best accuracy |

### AI Providers

Configure API keys in Settings > AI Enhancement:

- **Groq** (Recommended): Fast and affordable
- **OpenAI**: GPT-4o series
- **Anthropic**: Claude models
- **Google**: Gemini models
- **Ollama**: Free, local AI

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Right Command (hold) | Record |
| ⌘⇧R | Toggle Recording |
| ⌘, | Open Settings |
| Esc | Cancel Recording |

## Architecture

```
VoiceForge/
├── App/                    # Application entry point
├── Audio/                  # Audio pipeline and VAD
├── Transcription/          # Local and cloud engines
│   ├── Local/              # whisper.cpp integration
│   └── Cloud/              # Multi-provider cloud
├── AI/                     # Enhancement pipeline
├── Context/                # Context detection
├── Dictionary/             # Custom vocabulary
├── History/                # Transcription history
├── Input/                  # Hotkey engine
├── Security/               # Keychain and privacy
├── Views/                  # SwiftUI views
│   ├── Recorder/           # Recording UI
│   ├── Settings/           # Settings panels
│   ├── Onboarding/         # First-run experience
│   └── MenuBar/            # Menu bar UI
└── Notifications/          # In-app notifications
```

## Development

### Prerequisites

- Xcode 15.0+
- Swift 5.9+
- whisper.cpp framework

### Building

```bash
# Build release
xcodebuild -scheme VoiceForge -configuration Release

# Run tests
xcodebuild test -scheme VoiceForge
```

### Testing

```bash
swift test
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- [whisper.cpp](https://github.com/ggerganov/whisper.cpp) - Local transcription
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) - Shortcut handling
- [Sparkle](https://github.com/sparkle-project/Sparkle) - Auto-updates
