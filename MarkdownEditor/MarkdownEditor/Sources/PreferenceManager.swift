import Foundation

@objc(PreferenceManager)
class PreferenceManager: NSObject {
    private static let autoReloadEnabledKey = "AutoReloadEnabled"

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

    @objc func resetToDefaults() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        UserDefaults.standard.removeObject(forKey: Self.autoReloadEnabledKey)
    }
}
