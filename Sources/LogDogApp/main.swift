import Foundation
import LogDog

LoggingSystem.bootstrap { label -> LogHandler in
    
    let box = BoxTextLogFormatter(showDate: true, showThread: true, showLocation: true)
    let std = StdoutLogAppender()
    let handler1 = SugarLogHandler(label: label, processor: box, appender: std)
    
    let json = JSONLogFormatter().suffix("\n".data(using: .utf8)!)
    let rotator = DailyRotator()
    let file = FileLogAppender(delegate: rotator)
    let handler2 = SugarLogHandler(label: label, processor: json, appender: file)
    
    return MultiplexLogHandler([handler1, handler2])
}

var logger = Logger(label: "app")

func run(logger: Logger) {
    logger.trace("POST /users", metadata: ["body": ["name": "秋"]])

    logger.debug("got response", metadata: ["message": "ok"])

    logger.info("request success")

    logger.notice("latency too long", metadata: ["latency": .any(100), "some": ["a": .any(1)]])

    logger.warning("networking no cononection")

    logger.error("bad response", metadata: ["body": .any(10)])

    logger.critical("can not connect to db")
}

let timer = DispatchSource.makeTimerSource()
timer.setEventHandler {
    run(logger: logger)
}
timer.schedule(deadline: .now(), repeating: 5, leeway: .seconds(0))
timer.resume()

dispatchMain()
