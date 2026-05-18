import Cocoa
import UniformTypeIdentifiers

@objc(EditorDialogPresenter)
class EditorDialogPresenter: NSObject {
    @objc(showAlertWithTitle:message:forWindow:)
    func showAlert(title: String, message: String, for window: NSWindow?) {
        let alert = warningAlert(title: title, message: message)
        if let window {
            alert.beginSheetModal(for: window)
        }
    }

    private func warningAlert(title: String, message: String) -> NSAlert {
        let alert = NSAlert()
        alert.informativeText = title
        alert.messageText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        return alert
    }

    @objc(confirmDiscardingChangesForWindow:completionHandler:)
    func confirmDiscardingChanges(for window: NSWindow?, completionHandler handler: @escaping (NSApplication.ModalResponse) -> Void) {
        let alert = NSAlert()
        alert.informativeText = "Your changes will be lost if you don't save them."
        alert.messageText = "Do you want to save the changes you made to New file?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Don't Save")
        if let window {
            alert.beginSheetModal(for: window, completionHandler: handler)
        } else {
            handler(.cancel)
        }
    }

    @objc(showOpenFilePanelForWindow:initialPath:completionHandler:)
    func showOpenFilePanel(for window: NSWindow?, initialPath: String, completionHandler handler: @escaping (URL?) -> Void) {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: initialPath)
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.canSelectHiddenExtension = true
        if let window {
            panel.beginSheetModal(for: window) { result in
                handler(result == .OK ? panel.url : nil)
            }
        } else {
            handler(nil)
        }
    }

    @objc(showSaveFilePanelForWindow:initialPath:completionHandler:)
    func showSaveFilePanel(for window: NSWindow?, initialPath: String, completionHandler handler: @escaping (URL?) -> Void) {
        let panel = NSSavePanel()
        panel.directoryURL = URL(fileURLWithPath: initialPath)
        panel.allowedContentTypes = ["md", "markdown"].compactMap { UTType(filenameExtension: $0) }
        panel.canSelectHiddenExtension = true
        if let window {
            panel.beginSheetModal(for: window) { result in
                handler(result == .OK ? panel.url : nil)
            }
        } else {
            handler(nil)
        }
    }
}
