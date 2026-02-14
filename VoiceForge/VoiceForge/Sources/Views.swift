import SwiftUI
import AppKit

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Status
            VStack(spacing: 8) {
                Text(appState.statusMessage)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                if let error = appState.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                
                Text(appState.transcriptionStatus)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            // Record button
            RecordButton(
                isRecording: appState.isRecording,
                isTranscribing: appState.isTranscribing,
                audioLevel: appState.audioLevel
            ) {
                Task {
                    await appState.toggleRecording()
                }
            }
            
            // Last transcription
            if !appState.lastTranscription.isEmpty {
                TranscriptionCard(text: appState.lastTranscription)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            // Hotkey hint
            HStack {
                Image(systemName: "command")
                Text("Hold Right Command to record")
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
            .padding(.bottom, 20)
        }
        .frame(minWidth: 500, minHeight: 400)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Record Button

struct RecordButton: View {
    let isRecording: Bool
    let isTranscribing: Bool
    let audioLevel: Float
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Glow
                Circle()
                    .fill(glowColor.opacity(0.3))
                    .frame(width: 130, height: 130)
                    .blur(radius: 20)
                    .scaleEffect(isRecording ? 1.0 + CGFloat(audioLevel) * 0.5 : 1.0)
                    .animation(.easeOut(duration: 0.1), value: audioLevel)
                
                // Main button
                Circle()
                    .fill(buttonGradient)
                    .frame(width: 90, height: 90)
                    .shadow(color: glowColor.opacity(0.5), radius: 10)
                
                // Icon
                if isTranscribing {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                } else {
                    Image(systemName: iconName)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovering ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .disabled(isTranscribing)
    }
    
    private var iconName: String {
        if isRecording { return "stop.fill" }
        return "mic.fill"
    }
    
    private var glowColor: Color {
        if isTranscribing { return .purple }
        if isRecording { return .red }
        return .blue
    }
    
    private var buttonGradient: LinearGradient {
        let colors: [Color] = if isTranscribing {
            [.purple, .pink]
        } else if isRecording {
            [.red, .orange]
        } else {
            [.blue, .cyan]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Transcription Card

struct TranscriptionCard: View {
    let text: String
    @State private var copied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Last Transcription", systemImage: "text.bubble")
                    .font(.headline)
                Spacer()
                
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copied = false
                    }
                } label: {
                    Label(copied ? "Copied!" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.bordered)
            }
            
            Text(text)
                .font(.body)
                .textSelection(.enabled)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Menu Bar View

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                Task { await appState.toggleRecording() }
            } label: {
                Label(
                    appState.isRecording ? "Stop Recording" : "Start Recording",
                    systemImage: appState.isRecording ? "stop.fill" : "mic.fill"
                )
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
            .disabled(appState.isTranscribing)
            
            Divider()
            
            Text(appState.statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(appState.transcriptionStatus)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            
            Divider()
            
            SettingsLink {
                Label("Settings...", systemImage: "gearshape")
            }
            .keyboardShortcut(",", modifiers: .command)
            
            Divider()
            
            Button("Quit VoiceForge") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView {
            GeneralSettings()
                .environmentObject(appState)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            TranscriptionSettingsView()
                .environmentObject(appState)
                .tabItem {
                    Label("Transcription", systemImage: "waveform")
                }
            
            ShortcutsSettings()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
        }
        .frame(width: 500, height: 350)
        .padding()
    }
}

struct GeneralSettings: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    
    var body: some View {
        Form {
            Toggle("Launch at login", isOn: $launchAtLogin)
            Toggle("Play sounds", isOn: $appState.playSound)
            Toggle("Auto-paste after transcription", isOn: $appState.autoPaste)
        }
        .formStyle(.grouped)
    }
}

struct TranscriptionSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0
    
    private let transcriber = WhisperTranscriber()
    
    var body: some View {
        Form {
            Section("Cloud Transcription (Recommended)") {
                SecureField("Groq API Key", text: $appState.groqAPIKey)
                    .textFieldStyle(.roundedBorder)
                
                Text("Get free API key at [console.groq.com](https://console.groq.com)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Local Model") {
                Picker("Model", selection: $appState.selectedModel) {
                    Text("Base (142MB) - Fast").tag("base")
                    Text("Small (466MB) - Balanced").tag("small")
                    Text("Large v3 Turbo (1.5GB) - Best").tag("large-v3-turbo")
                }
                
                if transcriber.hasModel(appState.selectedModel) {
                    Label("Model available", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    HStack {
                        Label("Model not downloaded", systemImage: "exclamationmark.circle")
                            .foregroundStyle(.orange)
                        
                        Spacer()
                        
                        if isDownloading {
                            ProgressView(value: downloadProgress)
                                .frame(width: 100)
                        } else {
                            Button("Download") {
                                downloadModel()
                            }
                        }
                    }
                }
                
                Text("Local models work offline. Cloud is faster but requires internet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
    
    private func downloadModel() {
        isDownloading = true
        Task {
            do {
                try await transcriber.downloadModel(appState.selectedModel) { progress in
                    Task { @MainActor in
                        downloadProgress = progress
                    }
                }
            } catch {
                print("Download failed: \(error)")
            }
            await MainActor.run {
                isDownloading = false
                downloadProgress = 0
            }
        }
    }
}

struct ShortcutsSettings: View {
    @AppStorage("hotkeyOption") private var hotkeyOption = "rightCommand"
    
    var body: some View {
        Form {
            Picker("Recording Hotkey", selection: $hotkeyOption) {
                ForEach(HotkeyManager.HotkeyType.allCases, id: \.rawValue) { type in
                    Text(type.displayName).tag(type.rawValue)
                }
            }
            .onChange(of: hotkeyOption) { _, newValue in
                if let type = HotkeyManager.HotkeyType(rawValue: newValue) {
                    HotkeyManager.shared.selectedHotkey = type
                }
            }
            
            Text("Hold the key to record, release to transcribe")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Accessibility Permission Required")
                    .font(.headline)
                
                Text("VoiceForge needs Accessibility access for global hotkeys.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Button("Open Accessibility Settings") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                }
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
