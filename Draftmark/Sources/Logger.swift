import Foundation

func logError(_ message: String) {
    #if DEBUG
    NSLog("%@", message)
    #endif
}

func logWarning(_ message: String) {
    #if DEBUG
    NSLog("%@", message)
    #endif
}

func logInfo(_ message: String) {
    #if DEBUG
    NSLog("%@", message)
    #endif
}

func logDebug(_ message: String) {
    #if DEBUG
    NSLog("%@", message)
    #endif
}

func logVerbose(_ message: String) {
    #if DEBUG
    NSLog("%@", message)
    #endif
}
