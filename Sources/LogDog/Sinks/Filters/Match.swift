// An expressive DSL for creating matching filters.

public extension LogSink {
    func when<T>(_ transform: @escaping (LogRecord<Output>) -> T) -> LogFilters.When<Self, T> {
        .init(sink: self, transform: .init(transform))
    }

    func when<T>(_ transform: LogFilters.When<Self, T>.Transform) -> LogFilters.When<Self, T> {
        .init(sink: self, transform: transform)
    }
}

public extension LogFilters.When where T: StringProtocol {
    func includes<S: StringProtocol>(_ other: S) -> LogFilters.When<Sink, T>.Match {
        .init(when: self) {
            $0.contains(other)
        }
    }

    func excludes<S: StringProtocol>(_ other: S) -> LogFilters.When<Sink, T>.Match {
        .init(when: self) {
            !$0.contains(other)
        }
    }

    func hasPrefix<Prefix>(_ prefix: Prefix) -> LogFilters.When<Sink, T>.Match where Prefix: StringProtocol {
        .init(when: self) {
            $0.hasPrefix(prefix)
        }
    }

    func hasSuffix<Suffix>(_ suffix: Suffix) -> LogFilters.When<Sink, T>.Match where Suffix: StringProtocol {
        .init(when: self) {
            $0.hasSuffix(suffix)
        }
    }
}

public extension LogFilters.When where T == String {
    func match(_ regexp: String) -> LogFilters.When<Sink, T>.Match {
        .init(when: self) {
            $0.range(of: regexp, options: .regularExpression, range: nil, locale: nil) != nil
        }
    }
}

public extension LogFilters.When where T: Equatable {
    func equals(_ other: T) -> LogFilters.When<Sink, T>.Match {
        .init(when: self) {
            $0 == other
        }
    }
}

public extension LogFilters.When.Match {
    var allow: LogFilters.When<Sink, T>.Match.Do {
        .init(match: self, action: .allow)
    }

    var deny: LogFilters.When<Sink, T>.Match.Do {
        .init(match: self, action: .deny)
    }
}

public extension LogFilters {
    struct When<Sink: LogSink, T> {
        public struct Transform {
            public let transform: (LogRecord<Sink.Output>) -> T

            public init(_ transform: @escaping (LogRecord<Sink.Output>) -> T) {
                self.transform = transform
            }
        }

        public let sink: Sink
        public let transform: Transform

        public init(sink: Sink, transform: Transform) {
            self.sink = sink
            self.transform = transform
        }

        public struct Match {
            public let when: When

            public let match: (T) -> Bool

            public init(when: When, match: @escaping (T) -> Bool) {
                self.when = when
                self.match = match
            }

            public struct Do: LogSink {
                public typealias Input = Sink.Input
                public typealias Output = Sink.Output

                public let match: Match

                public enum Action {
                    case deny
                    case allow
                }

                public let action: Action

                public init(match: Match, action: Action) {
                    self.match = match
                    self.action = action
                }

                public func beforeSink(_ entry: inout LogEntry) {
                    match.when.sink.beforeSink(&entry)
                }

                public func sink(_ record: LogRecord<Sink.Input>, next: @escaping LogSinkNext<Sink.Output>) {
                    record.sink(
                        firstly: match.when.sink,
                        next: next
                    ) { record in
                        let t = match.when.transform.transform(record)

                        let matches = match.match(t)

                        switch action {
                        case .allow:
                            return matches ? record.output : nil
                        case .deny:
                            return matches ? nil : record.output
                        }
                    }
                }
            }
        }
    }
}

public extension LogFilters.When.Transform {
    static var level: LogFilters.When<Sink, Logger.Level>.Transform {
        .init {
            $0.entry.level
        }
    }

    static var message: LogFilters.When<Sink, String>.Transform {
        .init {
            String(describing: $0.entry.message)
        }
    }

    static var source: LogFilters.When<Sink, String>.Transform {
        .init {
            String(describing: $0.entry.source)
        }
    }

    static var path: LogFilters.When<Sink, String>.Transform {
        .init {
            $0.entry.file
        }
    }

    static var filename: LogFilters.When<Sink, String>.Transform {
        .init {
            LogHelper.basename(of: $0.entry.file)
        }
    }
}
