import Cocoa
import Carbon

/// Global hotkey manager using Carbon events for modifier-only keys
class HotkeyManager {
    
    static let shared = HotkeyManager()
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    var onRecordingStart: (() -> Void)?
    var onRecordingStop: (() -> Void)?
    
    @Published var isRightCommandHeld = false
    @Published var selectedHotkey: HotkeyType = .rightCommand
    
    private var lastKeyDownTime: Date?
    private let minimumHoldDuration: TimeInterval = 0.1 // 100ms to avoid accidental triggers
    
    enum HotkeyType: String, CaseIterable {
        case rightCommand = "rightCommand"
        case rightOption = "rightOption"
        case fn = "fn"
        
        var displayName: String {
            switch self {
            case .rightCommand: return "Right Command ⌘"
            case .rightOption: return "Right Option ⌥"
            case .fn: return "Fn"
            }
        }
    }
    
    private init() {
        // Load saved preference
        if let saved = UserDefaults.standard.string(forKey: "hotkeyOption"),
           let type = HotkeyType(rawValue: saved) {
            selectedHotkey = type
        }
    }
    
    /// Start monitoring for hotkeys
    func startMonitoring() {
        guard eventTap == nil else { return }
        
        // Request accessibility permissions
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
        let trusted = AXIsProcessTrustedWithOptions(options)
        
        guard trusted else {
            print("Accessibility access required for global hotkeys")
            return
        }
        
        // Create event tap for key events
        let eventMask = (1 << CGEventType.flagsChanged.rawValue)
        
        let callback: CGEventTapCallBack = { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
            let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon!).takeUnretainedValue()
            manager.handleFlagsChanged(event: event)
            return Unmanaged.passRetained(event)
        }
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard let eventTap = eventTap else {
            print("Failed to create event tap")
            return
        }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        print("Hotkey monitoring started")
    }
    
    /// Stop monitoring
    func stopMonitoring() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            if let runLoopSource = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            }
            self.eventTap = nil
            self.runLoopSource = nil
        }
    }
    
    /// Handle modifier key changes
    private func handleFlagsChanged(event: CGEvent) {
        let flags = event.flags
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        
        var isHotkeyPressed = false
        
        switch selectedHotkey {
        case .rightCommand:
            // Right Command: keycode 54
            isHotkeyPressed = keyCode == 54 && flags.contains(.maskCommand)
            
        case .rightOption:
            // Right Option: keycode 61
            isHotkeyPressed = keyCode == 61 && flags.contains(.maskAlternate)
            
        case .fn:
            // Fn key: keycode 63
            isHotkeyPressed = keyCode == 63 && flags.contains(.maskSecondaryFn)
        }
        
        // Check if this is key down or key up
        let wasHeld = isRightCommandHeld
        
        // For flags changed, we need to detect if the specific key is now pressed
        if selectedHotkey == .rightCommand {
            isRightCommandHeld = flags.contains(.maskCommand) && keyCode == 54
        } else if selectedHotkey == .rightOption {
            isRightCommandHeld = flags.contains(.maskAlternate) && keyCode == 61  
        } else {
            isRightCommandHeld = flags.contains(.maskSecondaryFn)
        }
        
        // Simple state tracking based on any modifier
        let hasModifier: Bool
        switch selectedHotkey {
        case .rightCommand:
            hasModifier = flags.contains(.maskCommand)
        case .rightOption:
            hasModifier = flags.contains(.maskAlternate)
        case .fn:
            hasModifier = flags.contains(.maskSecondaryFn)
        }
        
        if hasModifier && !wasHeld {
            // Key pressed
            isRightCommandHeld = true
            lastKeyDownTime = Date()
            
            DispatchQueue.main.async { [weak self] in
                self?.onRecordingStart?()
            }
        } else if !hasModifier && wasHeld {
            // Key released
            isRightCommandHeld = false
            
            // Check minimum hold duration
            if let downTime = lastKeyDownTime,
               Date().timeIntervalSince(downTime) >= minimumHoldDuration {
                DispatchQueue.main.async { [weak self] in
                    self?.onRecordingStop?()
                }
            }
            lastKeyDownTime = nil
        }
    }
    
    deinit {
        stopMonitoring()
    }
}
