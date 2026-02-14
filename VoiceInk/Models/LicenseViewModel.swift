import Foundation
import AppKit

@MainActor
class LicenseViewModel: ObservableObject {
    enum LicenseState: Equatable {
        case trial(daysRemaining: Int)
        case trialExpired
        case licensed
    }

    // App is completely free — always licensed
    @Published private(set) var licenseState: LicenseState = .licensed
    @Published var licenseKey: String = ""
    @Published var isValidating = false
    @Published var validationMessage: String?
    @Published private(set) var activationsLimit: Int = 0

    init() {
        // Always free — no trial or license checks needed
        licenseState = .licensed
    }

    var canUseApp: Bool {
        return true
    }

    func validateLicense() async {
        // No-op: app is free
    }

    func removeLicense() {
        // No-op: app is free
    }

    func startTrial() {
        // No-op: app is free, always licensed
        licenseState = .licensed
    }
}

