import Foundation

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension LogSink where Self.Output == Data {
    func compress(using compressionAlgorithm: LogFormatters.Compress.CompressionAlgorithm) -> LogSinks.Concat<Self, LogFormatters.Compress> {
        self + LogFormatters.Compress(compressionAlgorithm: compressionAlgorithm)
    }
}

public extension LogFormatters {
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    struct Compress: LogFormatter {
        public typealias CompressionAlgorithm = NSData.CompressionAlgorithm

        public typealias Input = Data
        public typealias Output = Data

        public let compressionAlgorithm: CompressionAlgorithm

        public init(compressionAlgorithm: CompressionAlgorithm) {
            self.compressionAlgorithm = compressionAlgorithm
        }

        public func format(_ record: LogRecord<Data>) throws -> Data? {
            try (record.output as NSData).compressed(using: compressionAlgorithm) as Data
        }
    }
}
