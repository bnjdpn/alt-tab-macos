import Cocoa

class UpgradeTab {
    static func initTab() -> NSView {
        let label = NSTextField(wrappingLabelWithString: NSLocalizedString("All features are included in this free and open-source fork.", comment: ""))
        label.translatesAutoresizingMaskIntoConstraints = false
        let button = NSButton(title: NSLocalizedString("Open source repository", comment: ""), target: nil, action: nil)
        button.onAction = { _ in openAccountPage() }
        let stack = StackView([label, button], .vertical)
        stack.spacing = GridView.interPadding
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    static func cleanup() { }
    static func refreshStatus() { }

    static func openAccountPage() {
        NSWorkspace.shared.open(URL(string: App.repository)!)
    }

    static func navigateToUpgradeTab() {
        SettingsWindow.shared?.navigateToSection("general")
    }

    static func showAutoActivating(_ licenseKey: String) {
        navigateToUpgradeTab()
    }

    static func showAutoActivationSuccess() {
        navigateToUpgradeTab()
    }

    static func showAutoActivationFailed(_ licenseKey: String) {
        navigateToUpgradeTab()
    }
}
