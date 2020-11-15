/// A namespace for formatter-style sinks.
public enum LogFormatters {}

public extension LogSink {
    func format<NewOutput>(
        format: @escaping (LogRecord<Output>) throws -> NewOutput?
    )
        -> LogSinks.Concat<Self, LogFormatters.Format<Output, NewOutput>>
    {
        self + .init(format: format)
    }
}

public extension LogFormatters {
    struct Format<Input, Output>: LogSink {
        public let format: (LogRecord<Input>) throws -> Output?

        public init(format: @escaping (LogRecord<Input>) throws -> Output?) {
            self.format = format
        }

        public func sink(_ record: LogRecord<Input>, next: @escaping LogSinkNext<Output>) {
            record.sink(next: next) { (record) -> Output? in
                try format(record)
            }
        }
    }
}
