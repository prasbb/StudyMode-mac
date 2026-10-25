import AppKit
import CoreAudio

// Study Mode: local-only; checks the DEFAULT audio output every three seconds.
private func audioString(_ id: AudioObjectID, _ selector: AudioObjectPropertySelector) -> String? {
    var address = AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    var size = UInt32(MemoryLayout<CFString?>.size)
    var value: CFString?
    let status = withUnsafeMutablePointer(to: &value) { ptr in
        AudioObjectGetPropertyData(id, &address, 0, nil, &size, ptr)
    }
    return status == noErr ? (value as String?) : nil
}

private func audioUInt(_ id: AudioObjectID, _ selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal) -> UInt32? {
    var address = AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
    guard AudioObjectHasProperty(id, &address) else { return nil }
    var result: UInt32 = 0
    var size = UInt32(MemoryLayout<UInt32>.size)
    let status = AudioObjectGetPropertyData(id, &address, 0, nil, &size, &result)
    return status == noErr ? result : nil
}

private func defaultOutput() -> AudioObjectID? {
    guard let id = audioUInt(AudioObjectID(kAudioObjectSystemObject), kAudioHardwarePropertyDefaultOutputDevice) else { return nil }
    return id == kAudioObjectUnknown ? nil : id
}

private func headphonesActive() -> Bool {
    guard let id = defaultOutput() else { return false }
    let name = (audioString(id, kAudioObjectPropertyName) ?? "").lowercased()
    let headphones = ["headphone", "headset", "airpods", "earbuds", "earphones", "beats", "bose", "sony wh-", "sony wf-", "buds", "jabra", "sennheiser", "quietcomfort"]
    if headphones.contains(where: { name.contains($0) }) { return true }

    // Bluetooth default output generally means wireless personal listening.
    // This can include Bluetooth speakers; see README for this limitation.
    if let transport = audioUInt(id, kAudioDevicePropertyTransportType),
       transport == kAudioDeviceTransportTypeBluetooth || transport == kAudioDeviceTransportTypeBluetoothLE { return true }

    // Depending on model/macOS version, a wired jack is exposed on the output device.
    if audioUInt(id, kAudioDevicePropertyJackIsConnected, scope: kAudioObjectPropertyScopeOutput) == 1 { return true }
    return false
}

final class StudyModeApp: NSObject, NSApplicationDelegate {
    private var item: NSStatusItem!
    private var toggle: NSMenuItem!
    private var panel: NSPanel?
    private var timer: Timer?
    private var enabled = UserDefaults.standard.object(forKey: "studyEnabled") as? Bool ?? true

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "headphones", accessibilityDescription: "Study Mode")
            if button.image == nil { button.title = "🎧" }
        }
        let menu = NSMenu()
        toggle = NSMenuItem(title: "Study Mode", action: #selector(toggleMode), keyEquivalent: "")
        toggle.target = self
        menu.addItem(toggle)
        menu.addItem(NSMenuItem.separator())
        let check = NSMenuItem(title: "Check headphones now", action: #selector(refresh), keyEquivalent: "")
        check.target = self
        menu.addItem(check)
        menu.addItem(NSMenuItem.separator())
        let quit = NSMenuItem(title: "Quit Study Mode", action: #selector(quitApp), keyEquivalent: "")
        quit.target = self
        menu.addItem(quit)
        item.menu = menu
        timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
        refresh()
    }

    @objc private func toggleMode() {
        enabled.toggle()
        UserDefaults.standard.set(enabled, forKey: "studyEnabled")
        refresh()
    }

    @objc private func quitApp() { NSApp.terminate(nil) }

    @objc private func refresh() {
        toggle.state = enabled ? .on : .off
        let connected = headphonesActive()
        item.button?.toolTip = enabled ? (connected ? "Study Mode · headphones connected" : "Study Mode · connect headphones") : "Study Mode is off"
        if enabled && !connected { showBanner() } else { panel?.orderOut(nil) }
    }

    private func showBanner() {
        if panel == nil {
            let p = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 355, height: 115),
                            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            p.isOpaque = false
            p.backgroundColor = .clear
            p.hasShadow = true
            p.level = .floating
            p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            p.hidesOnDeactivate = false

            let card = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 355, height: 115))
            card.material = .popover
            card.state = .active
            card.wantsLayer = true
            card.layer?.cornerRadius = 18
            card.layer?.masksToBounds = true

            let heading = NSTextField(labelWithString: "🎧  Connect your headphones")
            heading.font = NSFont.systemFont(ofSize: 17, weight: .semibold)
            heading.frame = NSRect(x: 20, y: 65, width: 320, height: 28)
            card.addSubview(heading)
            let detail = NSTextField(wrappingLabelWithString: "Study Mode is on. This reminder disappears automatically once your headphones are the selected sound output.")
            detail.font = NSFont.systemFont(ofSize: 12)
            detail.textColor = .secondaryLabelColor
            detail.frame = NSRect(x: 20, y: 17, width: 314, height: 43)
            card.addSubview(detail)
            p.contentView = card
            panel = p
        }
        guard let p = panel else { return }
        let screen = NSScreen.main ?? NSScreen.screens.first
        if let bounds = screen?.visibleFrame {
            p.setFrameOrigin(NSPoint(x: bounds.maxX - p.frame.width - 22, y: bounds.maxY - p.frame.height - 20))
        }
        if !p.isVisible { p.orderFrontRegardless() }
    }
}

let app = NSApplication.shared
let delegate = StudyModeApp()
app.delegate = delegate
app.run()
