import SwiftUI
import AVFoundation
import AppKit

@main
struct VoiceForgeApp: App {
    @StateObject private var appState = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About VoiceForge") {
                    NSApplication.shared.orderFrontStandardAboutPanel()
                }
            }
        }
        
        MenuBarExtra("VoiceForge", systemImage: appState.isRecording ? "waveform" : "mic.fill") {
            MenuBarView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.menu)
        
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Start hotkey monitoring
        HotkeyManager.shared.startMonitoring()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.stopMonitoring()
    }
}

// MARK: - App State

@MainActor
class AppState: ObservableObject {
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var lastTranscription = ""
    @Published var statusMessage = "Ready - Hold Right ⌘ to record"
    @Published var audioLevel: Float = 0
    @Published var errorMessage: String?
    
    @AppStorage("selectedModel") var selectedModel = "base"
    @AppStorage("groqAPIKey") var groqAPIKey = ""
    @AppStorage("autoPaste") var autoPaste = true
    @AppStorage("playSound") var playSound = true
    
    private var audioRecorder: AudioRecorder?
    private let transcriber = WhisperTranscriber()
    
    init() {
        setupAudioRecorder()
        setupHotkeys()
    }
    
    private func setupAudioRecorder() {
        audioRecorder = AudioRecorder()
        audioRecorder?.onLevelUpdate = { [weak self] level in
            Task { @MainActor in
                self?.audioLevel = level
            }
        }
    }
    
    private func setupHotkeys() {
        HotkeyManager.shared.onRecordingStart = { [weak self] in
            Task { @MainActor in
                await self?.startRecording()
            }
        }
        
        HotkeyManager.shared.onRecordingStop = { [weak self] in
            Task { @MainActor in
                await self?.stopRecording()
            }
        }
    }
    
    func toggleRecording() async {
        if isRecording {
            await stopRecording()
        } else {
            await startRecording()
        }
    }
    
    func startRecording() async {
        guard !isRecording else { return }
        
        // Request permission
        let granted = await requestMicrophonePermission()
        guard granted else {
            statusMessage = "Microphone access denied"
            errorMessage = "Please grant microphone access in System Settings > Privacy"
            return
        }
        
        do {
            if playSound {
                NSSound(named: "Morse")?.play()
            }
            
            try await audioRecorder?.startRecording()
            isRecording = true
            statusMessage = "Recording..."
            errorMessage = nil
        } catch {
            statusMessage = "Failed to start recording"
            errorMessage = error.localizedDescription
        }
    }
    
    func stopRecording() async {
        guard isRecording else { return }
        
        isRecording = false
        isTranscribing = true
        statusMessage = "Transcribing..."
        
        do {
            if playSound {
                NSSound(named: "Pop")?.play()
            }
            
            if let audioURL = try await audioRecorder?.stopRecording() {
                let text = try await transcriber.transcribe(audioURL: audioURL, model: selectedModel)
                lastTranscription = text
                statusMessage = "Done!"
                
                // Copy to clipboard
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
                
                // Auto-paste if enabled
                if autoPaste {
                    await pasteToActiveApp()
                }
                
                // Clean up audio file
                try? FileManager.default.removeItem(at: audioURL)
            }
        } catch {
            statusMessage = "Transcription failed"
            errorMessage = error.localizedDescription
            lastTranscription = "Error: \(error.localizedDescription)"
        }
        
        isTranscribing = false
        
        // Reset status after delay
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        if !isRecording && !isTranscribing {
            statusMessage = "Ready - Hold Right ⌘ to record"
        }
    }
    
    private func pasteToActiveApp() async {
        // Small delay to ensure clipboard is ready
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Simulate Cmd+V
        let source = CGEventSource(stateID: .hidSystemState)
        
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) // V key
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)
    }
    
    private func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    /// Check if transcription is available
    var canTranscribe: Bool {
        // Check for whisper-cli or API key
        return !groqAPIKey.isEmpty || transcriber.hasModel(selectedModel)
    }
    
    var transcriptionStatus: String {
        if transcriber.hasModel(selectedModel) {
            return "Using local model: \(selectedModel)"
        } else if !groqAPIKey.isEmpty {
            return "Using Groq cloud API"
        } else {
            return "No transcription method - add API key or download model"
        }
    }
}

// MARK: - Audio Recorder

class AudioRecorder {
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?
    
    var onLevelUpdate: ((Float) -> Void)?
    
    func startRecording() async throws {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        // Create temp file
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "voiceforge_\(Date().timeIntervalSince1970).wav"
        let url = tempDir.appendingPathComponent(fileName)
        recordingURL = url
        
        // 16kHz mono format for Whisper
        guard let recordingFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 16000,
            channels: 1,
            interleaved: true
        ) else {
            throw RecordingError.formatError
        }
        
        // Create converter
        guard let converter = AVAudioConverter(from: inputFormat, to: recordingFormat) else {
            throw RecordingError.converterError
        }
        
        audioFile = try AVAudioFile(forWriting: url, settings: recordingFormat.settings)
        
        // Install tap
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            // Calculate level
            if let channelData = buffer.floatChannelData?[0] {
                var sum: Float = 0
                for i in 0..<Int(buffer.frameLength) {
                    sum += abs(channelData[i])
                }
                let level = sum / Float(buffer.frameLength)
                self?.onLevelUpdate?(min(level * 5, 1.0))
            }
            
            // Convert to 16kHz mono
            let frameCount = AVAudioFrameCount(Double(buffer.frameLength) * 16000.0 / inputFormat.sampleRate)
            guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: recordingFormat, frameCapacity: frameCount) else { return }
            
            var error: NSError?
            var allConsumed = false
            
            converter.convert(to: convertedBuffer, error: &error) { inNumPackets, outStatus in
                if allConsumed {
                    outStatus.pointee = .noDataNow
                    return nil
                }
                allConsumed = true
                outStatus.pointee = .haveData
                return buffer
            }
            
            if error == nil && convertedBuffer.frameLength > 0 {
                try? self?.audioFile?.write(from: convertedBuffer)
            }
        }
        
        engine.prepare()
        try engine.start()
        audioEngine = engine
    }
    
    func stopRecording() async throws -> URL? {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        audioFile = nil
        
        return recordingURL
    }
}

enum RecordingError: LocalizedError {
    case formatError
    case converterError
    
    var errorDescription: String? {
        switch self {
        case .formatError: return "Failed to create audio format"
        case .converterError: return "Failed to create audio converter"
        }
    }
}
