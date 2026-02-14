import Foundation
import AVFoundation

/// Local Whisper transcription using the bundled whisper-cli
class WhisperTranscriber {
    
    private let modelsDirectory: URL
    private let bundledCLI: URL?
    
    init() {
        // Models stored in Application Support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        modelsDirectory = appSupport.appendingPathComponent("VoiceForge/Models")
        
        // Get bundled whisper-cli from app resources
        bundledCLI = Bundle.main.url(forResource: "whisper-cli", withExtension: nil)
        
        // Ensure models directory exists
        try? FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
    }
    
    /// Get the whisper-cli path (bundled or system)
    private var whisperCLI: URL? {
        // First try bundled
        if let bundled = bundledCLI, FileManager.default.fileExists(atPath: bundled.path) {
            return bundled
        }
        
        // Fall back to system paths
        let searchPaths = [
            "/usr/local/bin/whisper-cli",
            "/opt/homebrew/bin/whisper-cli",
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".local/bin/whisper-cli").path
        ]
        
        for path in searchPaths {
            if FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }
    
    /// Get available models
    func availableModels() -> [String] {
        guard FileManager.default.fileExists(atPath: modelsDirectory.path) else { return [] }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: modelsDirectory, includingPropertiesForKeys: nil)
            return files
                .filter { $0.pathExtension == "bin" }
                .map { $0.deletingPathExtension().lastPathComponent }
                .map { $0.replacingOccurrences(of: "ggml-", with: "") }
        } catch {
            return []
        }
    }
    
    /// Check if a specific model is available
    func hasModel(_ model: String) -> Bool {
        let modelPath = modelsDirectory.appendingPathComponent("ggml-\(model).bin")
        return FileManager.default.fileExists(atPath: modelPath.path)
    }
    
    /// Get model file path
    func modelPath(for model: String) -> URL {
        return modelsDirectory.appendingPathComponent("ggml-\(model).bin")
    }
    
    /// Check if whisper-cli is available
    var hasWhisperCLI: Bool {
        return whisperCLI != nil
    }
    
    /// Transcribe audio file using whisper-cli
    func transcribe(audioURL: URL, model: String = "base", language: String = "en") async throws -> String {
        guard let cli = whisperCLI else {
            throw TranscriptionError.noWhisperCLI
        }
        
        // Check if model exists
        let modelFile = modelPath(for: model)
        guard FileManager.default.fileExists(atPath: modelFile.path) else {
            throw TranscriptionError.modelNotFound(model)
        }
        
        // Make cli executable if needed
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: cli.path)
        
        // Create output file path
        let outputBase = audioURL.deletingPathExtension()
        
        // Run whisper-cli
        let process = Process()
        process.executableURL = cli
        process.arguments = [
            "-m", modelFile.path,
            "-f", audioURL.path,
            "-l", language,
            "--no-timestamps",
            "-otxt"
        ]
        
        // Set environment for Metal support
        var env = ProcessInfo.processInfo.environment
        env["GGML_METAL_PATH_RESOURCES"] = Bundle.main.resourcePath
        process.environment = env
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw TranscriptionError.processError(error.localizedDescription)
        }
        
        // Check exit status
        guard process.terminationStatus == 0 else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorStr = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw TranscriptionError.whisperError(errorStr)
        }
        
        // Read output - whisper creates a .txt file next to the input
        let txtFile = outputBase.appendingPathExtension("txt")
        if FileManager.default.fileExists(atPath: txtFile.path) {
            let content = try String(contentsOf: txtFile, encoding: .utf8)
            try? FileManager.default.removeItem(at: txtFile)
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Fall back to stdout
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8) ?? ""
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Download a model from Hugging Face
    func downloadModel(_ model: String, progress: @escaping (Double) -> Void) async throws {
        let modelName = "ggml-\(model).bin"
        let modelURL = URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/\(modelName)")!
        let destination = modelsDirectory.appendingPathComponent(modelName)
        
        // Delete existing partial download
        try? FileManager.default.removeItem(at: destination)
        
        let (tempURL, response) = try await URLSession.shared.download(for: URLRequest(url: modelURL))
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw TranscriptionError.downloadFailed
        }
        
        try FileManager.default.moveItem(at: tempURL, to: destination)
    }
}

// MARK: - Errors

enum TranscriptionError: LocalizedError {
    case modelNotFound(String)
    case noWhisperCLI
    case processError(String)
    case whisperError(String)
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound(let model):
            return "Model '\(model)' not found. Download it in Settings > Transcription."
        case .noWhisperCLI:
            return "whisper-cli not found. The app may be corrupted - please reinstall."
        case .processError(let msg):
            return "Failed to run whisper: \(msg)"
        case .whisperError(let msg):
            return "Whisper error: \(msg)"
        case .downloadFailed:
            return "Failed to download model. Check your internet connection."
        }
    }
}
