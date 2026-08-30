import Cocoa

@objc(PreferenceManager)
class PreferenceManager: NSObject {
    private static let autoReloadEnabledKey = "AutoReloadEnabled"
    private static let editorFontNameKey = "EditorFontName"
    private static let editorFontSizeKey = "EditorFontSize"

    static let editorFontSettingsDidChange = Notification.Name("EditorFontSettingsDidChange")

    @objc(sharedManager)
    static let shared = PreferenceManager()

    @objc var autoReloadEnabled: Bool {
        get {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            guard let storedValue = UserDefaults.standard.object(forKey: Self.autoReloadEnabledKey) as? NSNumber else {
                return true
            }
            return storedValue.boolValue
        }
        set {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            UserDefaults.standard.set(newValue, forKey: Self.autoReloadEnabledKey)
        }
    }

    @objc var editorFontName: String {
        get {
            if let storedName = UserDefaults.standard.string(forKey: Self.editorFontNameKey) {
                return storedName
            }
            let systemFamily = NSFont.monospacedSystemFont(
                ofSize: NSFont.systemFontSize,
                weight: .regular
            ).familyName
            return systemFamily ?? "Menlo"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.editorFontNameKey)
            NotificationCenter.default.post(name: Self.editorFontSettingsDidChange, object: self)
        }
    }

    @objc var editorFontSize: CGFloat {
        get {
            let storedSize = UserDefaults.standard.double(forKey: Self.editorFontSizeKey)
            return storedSize > 0 ? storedSize : NSFont.systemFontSize
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.editorFontSizeKey)
            NotificationCenter.default.post(name: Self.editorFontSettingsDidChange, object: self)
        }
    }

    @objc func resetToDefaults() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        UserDefaults.standard.removeObject(forKey: Self.autoReloadEnabledKey)
        UserDefaults.standard.removeObject(forKey: Self.editorFontNameKey)
        UserDefaults.standard.removeObject(forKey: Self.editorFontSizeKey)
        NotificationCenter.default.post(name: Self.editorFontSettingsDidChange, object: self)
    }
}
