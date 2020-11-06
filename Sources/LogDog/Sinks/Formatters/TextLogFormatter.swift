import Foundation

public struct TextLogFormatter: LogFormatter {
    public typealias Input = Void
    public typealias Output = String

    private let beforeSink: ((LogEntry) -> Void)?
    private let format: (LogRecord<Void>) throws -> String?

    public init(beforeSink: ((LogEntry) -> Void)? = nil,
                format: @escaping (LogRecord<Void>) throws -> String?)
    {
        self.beforeSink = beforeSink
        self.format = format
    }

    // TODO: A pattern layout? https://logging.apache.org/log4j/2.x/manual/layouts.html
//    public init(/**/) {
//        fatalError()
//    }

    public func beforeSink(_ entry: LogEntry) {
        beforeSink?(entry)
    }

    public func format(_ record: LogRecord<Void>) throws -> String? {
        try format(record)
    }
}

public extension TextLogFormatter {
    private struct DefaultContext: LogParameterKey {
        typealias Value = DefaultContext
        var currentTime: String
    }

    static let `default` = TextLogFormatter { entry in
        entry.parameters[DefaultContext.self] = DefaultContext(currentTime: LogHelper.currentTime)
    } format: { record -> String? in
        guard let context = record.entry.parameters[DefaultContext.self] else {
            return nil
        }

        let level = record.entry.level.initial

        let currentTime = context.currentTime

        let filename = LogHelper.basename(of: record.entry.file)

        var output = "\(currentTime) \(level)/\(record.entry.label): \(filename):\(record.entry.line).\(record.entry.function) \(record.entry.message)"

        if !record.entry.metadata.isEmpty {
            let metadata = record.entry.metadata
                .map {
                    "\($0)=\($1)"
                }
                .joined(separator: ", ")

            output += "\n    \(metadata)"
        }

        return output
    }
}