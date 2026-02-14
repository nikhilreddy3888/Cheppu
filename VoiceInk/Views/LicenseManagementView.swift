import SwiftUI

struct LicenseManagementView: View {
    @Environment(\.colorScheme) private var colorScheme
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Section
                heroSection
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var heroSection: some View {
        VStack(spacing: 24) {
            // App Icon
            AppIconView()
            
            // Title Section
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.blue)
                    
                    HStack(alignment: .lastTextBaseline, spacing: 8) { 
                        Text("Cheppu")
                            .font(.system(size: 32, weight: .bold))
                        
                        Text("v\(appVersion)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                    }
                }
                
                Text("Voice to text, powered by AI — completely free")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 40) {
                    Button {
                        if let url = URL(string: "https://github.com/Beingpax/VoiceInk/releases") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        featureItem(icon: "list.bullet.clipboard.fill", title: "Changelog", color: .blue)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        if let url = URL(string: "https://discord.gg/xryDy57nYD") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        featureItem(icon: "bubble.left.and.bubble.right.fill", title: "Discord", color: .purple)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        EmailSupport.openSupportEmail()
                    } label: {
                        featureItem(icon: "envelope.fill", title: "Email Support", color: .orange)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 60)
    }
    
    private func featureItem(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
        }
    }
}
