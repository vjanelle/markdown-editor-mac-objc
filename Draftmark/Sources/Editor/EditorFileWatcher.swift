import Foundation

@objc(EditorFileWatcher)
class EditorFileWatcher: NSObject {
    private var source: DispatchSourceFileSystemObject?

    deinit {
        stopWatching()
    }

    @objc(watchFileAtPath:changeHandler:)
    func watchFile(atPath path: String?, changeHandler: @escaping () -> Void) {
        stopWatching()
        guard let path else {
            return
        }

        let fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            return
        }

        let queue = DispatchQueue.global(qos: .utility)
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename],
            queue: queue
        )
        source.setEventHandler {
            DispatchQueue.main.async(execute: changeHandler)
        }
        source.setCancelHandler {
            close(fileDescriptor)
        }
        self.source = source
        source.resume()
    }

    @objc func stopWatching() {
        source?.cancel()
        source = nil
    }
}
