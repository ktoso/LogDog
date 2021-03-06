import Foundation

class TextStream: TextOutputStream {
    let lock = NSLock()
    var buffer = ""

    func write(_ string: String) {
        lock.lock()
        defer {
            lock.unlock()
        }

        buffer.write(string)
    }
}
