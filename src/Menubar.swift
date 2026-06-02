import Cocoa

class Menubar {
    static var statusItem: NSStatusItem!
    static var menu: NSMenu!
    static var permissionCalloutMenuItems: [NSMenuItem]?
    private static var sourceCodeMenuItem: NSMenuItem!
    private static let menuDelegate = MenubarMenuDelegate()

    @discardableResult
    static func addMenuItem(_ title: String, _ action: Selector, _ keyEquivalent: String, _ symbolName: String?, _ color: NSColor? = nil, _ target: AnyObject? = nil) -> NSMenuItem {
        let item = menu.addItem(withTitle: title, action: action, keyEquivalent: keyEquivalent)
        item.target = target
        if #available(macOS 26.0, *), let symbolName {
            item.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
            if let color {
                item.image = item.image?.withSymbolConfiguration(.init(paletteColors: [color]))
            }
        }
        return item
    }

    static func initialize() {
        menu = NSMenu()
        menu.title = App.name // perf: prevent going through expensive code-path within appkit
        menu.delegate = menuDelegate
        let permissionCalloutMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        permissionCalloutMenuItem.view = PermissionCallout()
        let calloutSeparator = NSMenuItem.separator()
        permissionCalloutMenuItems = [permissionCalloutMenuItem, calloutSeparator]
        addMenuItem(NSLocalizedString("Show", comment: "Menubar option"), #selector(App.showUiFromShortcut0), "", "eye", nil, App.self)
        menu.addItem(NSMenuItem.separator())
        addMenuItem(NSLocalizedString("Settings…", comment: "Menubar option"), #selector(App.showSettingsWindow), ",", "gear", nil, App.self)
        addMenuItem(NSLocalizedString("Check for updates…", comment: "Menubar option"), #selector(App.checkForUpdatesNow), "", "checkmark.arrow.trianglehead.clockwise", nil, App.self)
        addMenuItem(NSLocalizedString("Check permissions…", comment: "Menubar option"), #selector(App.checkPermissions), "", "hand.raised", nil, App.self)
        menu.addItem(NSMenuItem.separator())
        addMenuItem(String(format: NSLocalizedString("About %@", comment: "Menubar option. %@ is AltTab"), App.name), #selector(App.showAboutWindow), "", "info.circle", nil, App.self)
        addMenuItem(NSLocalizedString("Debug tools", comment: "Menubar option"), #selector(App.showDebugWindow), "", "scope", nil, App.self)
        addMenuItem(NSLocalizedString("Send feedback…", comment: "Menubar option"), #selector(App.showFeedbackPanel), "", "text.bubble", nil, App.self)
        sourceCodeMenuItem = addMenuItem(NSLocalizedString("Source code", comment: "Menubar option"), App.supportProjectAction, "", "chevron.left.forwardslash.chevron.right", nil, App.self)
        refreshLicenseMenuItems()
        menu.addItem(NSMenuItem.separator())
        addMenuItem(String(format: NSLocalizedString("Quit %@", comment: "%@ is AltTab"), App.name), #selector(NSApplication.terminate(_:)), "q", nil) // "xmark.rectangle" is not necessary; macos automatically recognizes Quit
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.target = self
        statusItem.button!.action = #selector(statusItemOnClick)
        statusItem.button!.sendAction(on: [.leftMouseDown, .rightMouseDown])
        // Apply icon prefs eagerly here, while the status item is still being added to the
        // menubar. Doing it later (from PreferencesEvents.initialize) sets `button.image` after
        // the WindowServer has already laid the menubar out at its imageless default size, then
        // invalidates NSStatusBarContentView mid-FBS-scene-update — `_NSDetectedLayoutRecursion`.
        applyMenubarIconPreferences()
        #if DEBUG
        installQAMenuMiddleClickMonitor()
        #endif
    }

    #if DEBUG
    private static var qaMenuMiddleClickMonitor: Any?

    // NSStatusBarButton doesn't forward `.otherMouseDown` to its action even when added to
    // `sendAction(on:)`. A local event monitor sees the click before the button can swallow it.
    private static func installQAMenuMiddleClickMonitor() {
        qaMenuMiddleClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .otherMouseDown) { event in
            guard event.buttonNumber == 2,
                  let buttonWindow = statusItem?.button?.window,
                  event.window === buttonWindow else { return event }
            QAMenu.toggleVisibility()
            return nil
        }
    }
    #endif

    static func refreshLicenseMenuItems() {
        sourceCodeMenuItem?.isHidden = false
    }

    // NSMenuItem.isHidden isn't reliable with custom views. We add/remove to hide/show these items
    static func togglePermissionCallout(_ show: Bool) {
        permissionCalloutMenuItems?.enumerated().forEach { offset, element in
            if show && !menu.items.contains(element) {
                menu.insertItem(element, at: offset)
            }
            if !show && menu.items.contains(element) {
                menu.removeItem(element)
            }
        }
    }

    @objc static func statusItemOnClick() {
        // NSApp.currentEvent == nil if the icon is "clicked" through VoiceOver
        if let type = NSApp.currentEvent?.type, type != .leftMouseDown {
            App.showUiFromShortcut0()
        } else {
            statusItem.popUpMenu(Menubar.menu)
        }
    }

    static func menubarIconCallback(_: NSControl?) {
        // Guard: can be invoked during `LicenseManager.initialize()` (e.g. Pro users where
        // `onStateChanged` → `ProTransitionManager.onLicenseStateChanged` fires before
        // `Menubar.setup()`), at which point `statusItem` is still nil.
        guard statusItem != nil else { return }
        applyMenubarIconPreferences()
        if let menubarIconDropdown = GeneralTab.menubarIconDropdown {
            menubarIconDropdown.isEnabled = Preferences.menubarIconShown
        }
    }

    static private func applyMenubarIconPreferences() {
        if Preferences.menubarIconShown {
            loadPreferredIcon()
        } else {
            statusItem.isVisible = false
        }
    }

    private static var badgeDotLayer: CALayer?

    static private func loadPreferredIcon() {
        let i = Preferences.menubarIcon.indexAsString
        let image = NSImage(named: "menubar-\(i)")!
        image.isTemplate = i != "2"
        statusItem.button!.image = image
        statusItem.isVisible = true
        statusItem.button!.imageScaling = .scaleProportionallyUpOrDown
        updateBadgeDotOverlay()
    }

    // CALayer rather than NSView subview: adding an NSView to NSStatusBarButton triggers
    // NSStatusBarContentView layout cascades that race with FBSScene updates at launch,
    // tripping `_NSDetectedLayoutRecursion`. CALayers don't post frame-change notifications.
    static private func updateBadgeDotOverlay() {
        badgeDotLayer?.removeFromSuperlayer()
        badgeDotLayer = nil
        guard ProTransitionManager.shared.shouldShowBadgeDot, let button = statusItem?.button else { return }
        button.wantsLayer = true
        guard let buttonLayer = button.layer else { return }
        let dotSize: CGFloat = 7
        // Anchor to the icon's bottom-right corner (not the button bounds). The button is
        // typically taller than the icon — especially on macOS Tahoe — so positioning relative
        // to button.bounds leaves the dot in the empty space below the icon. `imageRect`
        // returns the icon's actual rendered rect in NSView coords (y up).
        let imageRect = button.cell?.imageRect(forBounds: button.bounds) ?? button.bounds
        // CALayer uses y-down (origin top-left); imageRect is in NSView y-up. Convert the
        // icon's bottom edge to layer space: `button.bounds.height - imageRect.minY`.
        let dot = CALayer()
        dot.frame = NSRect(
            x: imageRect.maxX - dotSize,
            y: button.bounds.height - imageRect.minY - dotSize,
            width: dotSize, height: dotSize)
        dot.backgroundColor = NSColor.systemOrange.cgColor
        dot.cornerRadius = dotSize / 2
        dot.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
        dot.autoresizingMask = [.layerMinXMargin, .layerMinYMargin]
        buttonLayer.addSublayer(dot)
        badgeDotLayer = dot
    }

    static func showPopoverFromMenubar(_ popover: NSPopover) {
        guard let button = statusItem?.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
}

private final class MenubarMenuDelegate: NSObject, NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        LicenseManager.shared.refreshState()
    }
}

class PermissionCallout: StackView {
    convenience init() {
        let label = NSTextField(wrappingLabelWithString: NSLocalizedString("AltTab is running without Screen Recording permissions. Thumbnails won’t show.", comment: "Menubar callout"))
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.preferredMaxLayoutWidth = 250
        label.isSelectable = false
        label.addOrUpdateConstraint(label.widthAnchor, 250)
        let button = NSButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.attributedTitle = NSAttributedString(string: NSLocalizedString("Grant permission", comment: "Menubar callout button"), attributes: [NSAttributedString.Key.foregroundColor: NSColor.white])
        button.onAction = { _ in
            Preferences.remove("screenRecordingPermissionSkipped")
            App.restart()
        }
        self.init([label, button], .vertical, true, top: 8, right: 15, bottom: 10, left: 15)
        wantsLayer = true
        layer!.backgroundColor = NSColor.purple.cgColor
    }
}
