import Foundation

@objc(EditorFileWatcher)
class EditorFileWatcher: NSObject {
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: CInt = -1

    deinit {
        stopWatching()
    }

    @objc(watchFileAtPath:changeHandler:)
    func watchFile(atPath path: String?, changeHandler: @escaping () -> Void) {
        stopWatching()
        guard let path else {
            return
        }

        fileDescriptor = open(path, O_EVTONLY)
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
        source.setCancelHandler { [weak self] in
            guard let self, self.fileDescriptor >= 0 else {
                return
            }
            close(self.fileDescriptor)
            self.fileDescriptor = -1
        }
        self.source = source
        source.resume()
    }

    @objc func stopWatching() {
        if let source {
            source.cancel()
            self.source = nil
            return
        }
        if fileDescriptor >= 0 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
    }
}
