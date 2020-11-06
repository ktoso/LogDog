public extension LogSink {
    func eraseToAnyLogSink() -> AnyLogSink<Input, Output> {
        .init(self)
    }
}

public struct AnyLogSink<Input, Output>: LogSink {
    private let sink: AbstractSink<Input, Output>

    public init<Sink>(_ sink: Sink) where Sink: LogSink, Input == Sink.Input, Output == Sink.Output {
        self.sink = SinkBox(sink)
    }

    init(beforeSink: @escaping (LogEntry) -> Void,
         sink: @escaping (LogRecord<Input>, (Result<LogRecord<Output>?, Error>) -> Void) -> Void)
    {
        self.sink = ClosureBox(beforeSink: beforeSink, sink: sink)
    }

    public func beforeSink(_ entry: LogEntry) {
        sink.beforeSink(entry)
    }

    public func sink(_ record: LogRecord<Input>, next: @escaping (Result<LogRecord<Output>?, Error>) -> Void) {
        sink.sink(record, next: next)
    }
}

private class AbstractSink<Input, Output>: LogSink {
    func beforeSink(_: LogEntry) {
        fatalError()
    }

    func sink(_: LogRecord<Input>, next _: @escaping (Result<LogRecord<Output>?, Error>) -> Void) {
        fatalError()
    }
}

private final class ClosureBox<Input, Output>: AbstractSink<Input, Output> {
    private let beforeSink: (LogEntry) -> Void
    private let sink: (LogRecord<Input>, (Result<LogRecord<Output>?, Error>) -> Void) -> Void

    init(beforeSink: @escaping (LogEntry) -> Void,
         sink: @escaping (LogRecord<Input>, (Result<LogRecord<Output>?, Error>) -> Void) -> Void)
    {
        self.beforeSink = beforeSink
        self.sink = sink
    }

    override func beforeSink(_ entry: LogEntry) {
        beforeSink(entry)
    }

    override func sink(_ record: LogRecord<Input>, next: @escaping (Result<LogRecord<Output>?, Error>) -> Void) {
        sink(record, next)
    }
}

private final class SinkBox<Sink>: AbstractSink<Sink.Input, Sink.Output> where Sink: LogSink {
    private let sink: Sink

    init(_ sink: Sink) {
        self.sink = sink
    }

    override func beforeSink(_ entry: LogEntry) {
        sink.beforeSink(entry)
    }

    override func sink(_ record: LogRecord<Input>, next: @escaping (Result<LogRecord<Output>?, Error>) -> Void) {
        sink.sink(record, next: next)
    }
}
