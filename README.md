<div align="center">
  <img src="VoiceInk/Assets.xcassets/AppIcon.appiconset/256-mac.png" width="180" height="180" />
  <h1>Cheppu</h1>
  <p>Free, open-source, privacy-focused voice-to-text for macOS.</p>
  <p><em>Check out the full guide for building and using Cheppu: <a href="CHEPPU_GUIDE.md">CHEPPU_GUIDE.md</a></em></p>

  [![License](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
  ![Platform](https://img.shields.io/badge/platform-macOS%2014.0%2B-brightgreen)
</div>

---

**Cheppu** is a native macOS application that transcribes what you say to text almost instantly. It is a fork of [VoiceInk](https://github.com/Beingpax/VoiceInk), rebranded and modified to be completely free and open-source.

## Features

- 🎙️ **Accurate Transcription**: Local AI models that transcribe your voice to text with 99% accuracy, almost instantly
- 🔒 **Privacy First**: 100% offline processing ensures your data never leaves your device (unless you explicitly enable optional cloud features)
- ⚡ **Power Mode**: Intelligent app detection automatically applies your perfect pre-configured settings based on the app/ URL you're on
- 🧠 **Context Aware**: Smart AI that understands your screen content and adapts to the context
- 🎯 **Global Shortcuts**: Configurable keyboard shortcuts for quick recording and push-to-talk functionality
- 📝 **Personal Dictionary**: Train the AI to understand your unique terminology with custom words, industry terms, and smart text replacements
- 🔄 **Smart Modes**: Instantly switch between AI-powered modes optimized for different writing styles and contexts
- 🤖 **AI Assistant**: Built-in voice assistant mode for a quick chatGPT like conversational assistant
- 💸 **Completely Free**: No licensing system, no paywalls, no trial restrictions.

## Installation

### Method 1: Build from Source (Recommended)

Since Cheppu is not yet notarized by Apple, the best way to get it is to build it yourself (it takes < 15 mins).

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/nikhilreddy3888/Cheppu.git
    cd Cheppu
    ```

2.  **Build the app:**
    ```bash
    make local
    ```
    This will compile `whisper.cpp` and build `Cheppu.app` into your `~/Downloads` folder.

3.  **Install:**
    - Open `~/Downloads`
    - Drag `Cheppu.app` to `/Applications`
    - **Right-click** on the app and select **Open** (required because it's ad-hoc signed)

For detailed build instructions, see [CHEPPU_GUIDE.md](CHEPPU_GUIDE.md).

## Usage

1.  Launch **Cheppu** from your Applications folder.
2.  Grant the necessary permissions (Microphone, Accessibility, Screen Recording).
3.  Use the global shortcut (default: `Option + Space` or configured in settings) to start recording.
4.  Speak! Your text will be typed into the active window.

## Contributing

Contributions are welcome! If you'd like to improve Cheppu:

1.  Fork the repository.
2.  Create a feature branch (`git checkout -b feature/amazing-feature`).
3.  Commit your changes (`git commit -m 'Add some amazing feature'`).
4.  Push to the branch (`git push origin feature/amazing-feature`).
5.  Open a Pull Request.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

-   **Original Project**: [VoiceInk](https://github.com/Beingpax/VoiceInk) by Beingpax.
-   [whisper.cpp](https://github.com/ggerganov/whisper.cpp) - High-performance inference of OpenAI's Whisper model
-   [FluidAudio](https://github.com/FluidInference/FluidAudio) - Used for Parakeet model implementation
-   [Sparkle](https://github.com/sparkle-project/Sparkle) - Keeping extensions up to date
-   [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) - User-customizable keyboard shortcuts
