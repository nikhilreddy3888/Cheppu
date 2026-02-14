# Cheppu — Fork Guide

> A rebranded, fully free fork of [VoiceInk](https://github.com/Beingpax/VoiceInk).

---

## 1. Security & Network Audit

### ✅ No hidden telemetry — all network calls are user-initiated

| Service | What it does | Sends data? | Your data leaves the device? |
|---|---|---|---|
| **Local Whisper** | On-device transcription | ❌ No | ❌ Never — runs 100% locally |
| **Whisper Model Downloads** | Downloads `.bin` models from huggingface.co | ❌ No user data | Only downloads model files |
| **Ollama** | Local AI enhancement | ❌ No | ❌ Connects to `localhost:11434` only |
| **Cloud AI APIs** (OpenAI, Groq, Gemini, etc.) | Cloud transcription & AI enhancement | ⚠️ Sends audio/text | Only if **you** add API keys and choose cloud mode |
| **Streaming providers** (Deepgram, ElevenLabs, Soniox, Mistral) | Real-time cloud transcription | ⚠️ Sends audio | Only if **you** configure and enable them |
| **Sparkle (Update checker)** | Checks for app updates | ❌ No user data | Fetches `appcast.xml` — currently points to a non-existent Cheppu URL |
| **AnnouncementsService** | Fetches in-app banners | ❌ No user data | Fetches `announcements.json` from GitHub Pages (read-only) |
| **PolarService** (License validation) | Was used for license keys | 🔒 **Dead code** | LicenseViewModel bypasses it — never called |

### Summary
- **Default mode (local Whisper) = zero network calls**. Your voice never leaves your Mac.
- Cloud APIs only activate when you explicitly provide API keys in Settings.
- PolarService (license server at `api.polar.sh`) is now dead code — `LicenseViewModel` always returns `.licensed`.
- No analytics, no tracking, no crash reporting to external services.

---

## 2. All Changes Made (95 files, ~1050 lines changed)

### Category 1: Rebranding (VoiceInk → Cheppu)

**~85 files** had string replacements:
- User-facing text: `"VoiceInk"` → `"Cheppu"` in UI strings, descriptions, error messages
- Bundle ID: `com.prakashjoshipax.VoiceInk` → `com.prakashjoshipax.cheppu`
- Subsystem/logger IDs: `com.prakashjoshipax.voiceink` → `com.prakashjoshipax.cheppu`
- iCloud container: updated in `VoiceInk.entitlements`
- Keychain groups: updated in `VoiceInk.entitlements`
- Struct/class names: `VoiceInkApp` → `CheppuApp`, `VoiceInkButton` → `CheppuButton`, `VoiceInkExportedSettings` → `CheppuExportedSettings`

**Documentation files:**
- `README.md`, `BUILDING.md`, `CONTRIBUTING.md` — all rebranded
- `.github/ISSUE_TEMPLATE/bug_report.md`, `.github/PULL_REQUEST_TEMPLATE.md` — rebranded
- `announcements.json`, `appcast.xml` — titles and URLs updated

**Build configuration:**
- `Makefile` — dependency dir → `Cheppu-Dependencies`, app name → `Cheppu.app`
- `project.pbxproj` — display name → `Cheppu`, bundle ID updated, whisper framework path → `Cheppu-Dependencies`, KeyboardShortcuts pinned to 2.2.1
- `LocalBuild.xcconfig` — excludes `ENABLE_NATIVE_SPEECH_ANALYZER` flag

### Category 2: Making the App Free

**Key files modified:**
| File | What changed |
|---|---|
| `LicenseViewModel.swift` | Always returns `.licensed`, removed all trial/validation logic (~150 lines removed) |
| `LicenseManagementView.swift` | Converted from license purchase page → simple "About" page (~240 lines removed) |
| `DashboardPromotionsSection.swift` | Returns `EmptyView()` — removed upgrade/affiliate promos (~70 lines removed) |
| `ContentView.swift` | Removed "PRO" badge, renamed sidebar "VoiceInk Pro" → "About" |

**Dead code (still present but never called):**
- `PolarService.swift` — license validation API client
- `LicenseManager.swift` — keychain license storage (now stores updated key names but never used)

### Category 3: Build Fixes

| File | Fix |
|---|---|
| `NativeAppleTranscriptionService.swift` | Moved `#if ENABLE_NATIVE_SPEECH_ANALYZER` to wrap entire `ensureModelIsAvailable` function (was only guarding the body, not the signature) |
| `PlaybackController.swift` | Added optional chaining for `trackInfo?.payload` (MediaRemoteAdapter API change) |
| `project.pbxproj` | Pinned KeyboardShortcuts to 2.2.1 (v2.4.0 requires Swift 6.1, Xcode 16.2 has Swift 6.0) |

### What was NOT renamed (intentional)
- **Physical directories**: `VoiceInk/`, `VoiceInkTests/`, `VoiceInkUITests/` — renaming breaks Xcode project
- **Xcode project file**: `VoiceInk.xcodeproj/` — must be renamed through Xcode UI
- **Xcode target/scheme**: still `VoiceInk` — Makefile uses `-scheme VoiceInk`
- **`@testable import VoiceInk`** in test files — must match Xcode module name
- **GitHub URLs**: `github.com/Beingpax/VoiceInk` — left as-is (upstream repo reference)

---

## 3. Build Commands

### Prerequisites
- macOS 14.4+
- Xcode 16.x (with Swift 6.0)
- ~2GB free disk space (for whisper.cpp framework)

### First-time build (includes building whisper.cpp — takes 10-15 min)
```bash
cd /path/to/VoiceInk
make local
```

This will:
1. Clone & build `whisper.cpp` xcframework into `~/Cheppu-Dependencies/`
2. Build the Cheppu app with ad-hoc signing (no Apple Developer account needed)
3. Copy the `.app` to `~/Downloads/Cheppu.app`

### Subsequent builds (fast — whisper.cpp is cached)
```bash
make local
```

### Create a DMG
After `make local` succeeds:
```bash
# Copy the built app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "VoiceInk.app" -path "*/Debug/*" -type d | head -1)
rm -rf ~/Downloads/Cheppu.app
ditto "$APP_PATH" ~/Downloads/Cheppu.app
xattr -cr ~/Downloads/Cheppu.app

# Create DMG
rm -f ~/Downloads/Cheppu.dmg
hdiutil create -volname "Cheppu" -srcfolder ~/Downloads/Cheppu.app -ov -format UDZO ~/Downloads/Cheppu.dmg
```

The DMG will be at: `~/Downloads/Cheppu.dmg`

### Clean everything
```bash
make clean          # Removes build artifacts
make clean-deps     # Also removes ~/Cheppu-Dependencies/
```

---

## 4. Installing on Other Macs

Since the DMG is ad-hoc signed (no Apple Developer ID certificate), macOS Gatekeeper will block it on other machines. The user must do **one** of:

### Option A: Right-click → Open (easiest)
1. Mount the DMG (double-click `Cheppu.dmg`)
2. Drag `Cheppu.app` to `/Applications`
3. **Right-click** (Control-click) on `Cheppu.app` → select **"Open"**
4. Click **"Open"** in the confirmation dialog
5. App works normally from now on

### Option B: Terminal command
```bash
xattr -cr /Applications/Cheppu.app
open /Applications/Cheppu.app
```

### Option C: System Settings
Go to **System Settings → Privacy & Security**, scroll down, click **"Open Anyway"** next to the Cheppu warning.

### For fully transparent installs (no warnings)
You would need:
1. Active Apple Developer Program ($99/year)
2. A **"Developer ID Application"** certificate
3. Code sign with: `codesign --deep --force --options runtime --sign "Developer ID Application: Your Name (TEAMID)" Cheppu.app`
4. Notarize with: `xcrun notarytool submit Cheppu.dmg --apple-id YOU@EMAIL --password APP_SPECIFIC_PASSWORD --team-id TEAMID --wait`
5. Staple: `xcrun stapler staple Cheppu.dmg`

---

## 5. Pulling Upstream VoiceInk Changes

### Setup (one time)
```bash
cd /path/to/VoiceInk

# Add upstream remote (if not already added)
git remote add upstream https://github.com/Beingpax/VoiceInk.git

# Verify
git remote -v
# origin    https://github.com/YOUR_USER/YOUR_REPO.git (your fork)
# upstream  https://github.com/Beingpax/VoiceInk.git   (original)
```

### Pulling new features from VoiceInk
```bash
# 1. Save your current work
git add -A && git commit -m "WIP: save before merge"

# 2. Fetch upstream changes
git fetch upstream

# 3. Merge upstream into your branch
git merge upstream/main

# 4. Resolve conflicts (if any)
# Most conflicts will be in files where we changed "VoiceInk" to "Cheppu".
# For each conflict:
#   - Keep the NEW logic/features from upstream
#   - Re-apply the "Cheppu" branding to the new code
#   - Keep LicenseViewModel always returning .licensed

# 5. After resolving conflicts, rebuild
make local
```

### Expected merge conflicts
These files will almost always conflict when upstream updates them:
- `VoiceInk/VoiceInk.swift` — main app struct (renamed to CheppuApp)
- `VoiceInk/Views/ContentView.swift` — sidebar branding
- `VoiceInk/Views/LicenseManagementView.swift` — we gutted this
- `VoiceInk/Models/LicenseViewModel.swift` — we gutted this
- `README.md`, `BUILDING.md` — documentation changes

### Quick re-brand after merge
If upstream adds new files with "VoiceInk" references:
```bash
# Find new VoiceInk references in Swift files
grep -rn "VoiceInk" --include="*.swift" VoiceInk/ | grep -v ".build/" | grep -v "import VoiceInk"

# Bulk replace in a specific file
sed -i '' 's/VoiceInk/Cheppu/g' <filename>
```

### Strategy: Keep merge-friendly changes
Our changes are designed to minimize conflicts:
- Most changes are simple string replacements (`VoiceInk` → `Cheppu`)
- License removal is isolated to 3-4 files
- No structural changes to the codebase
- All upstream features (AI, streaming, models) remain fully functional

---

## 6. Quick Reference

| What | Command |
|---|---|
| Build the app | `make local` |
| Find the built .app | `~/Downloads/Cheppu.app` |
| Create DMG | See Section 3 above |
| Clean build | `make clean` |
| Pull upstream changes | `git fetch upstream && git merge upstream/main` |
| Check for VoiceInk remnants | `grep -rn "VoiceInk" --include="*.swift" VoiceInk/` |
