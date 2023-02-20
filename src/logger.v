import term

interface ILogger {
    error(msg string)
    warn(msg string)
    info(msg string)
    debug(msg string)
}

fn xprintln(msg string) {
    eprintln(msg)
}

struct LoggerSilent {
}

struct LoggerWarnLevel {
    LoggerSilent
}

struct LoggerDebugLevel {
    LoggerWarnLevel
}

fn (_ LoggerSilent) error(msg string) {
}

fn (_ LoggerSilent) warn(msg string) {
}

fn (_ LoggerSilent) info(msg string) {
}

fn (_ LoggerSilent) debug(msg string) {
}

fn (_ LoggerWarnLevel) error(msg string) {
    xprintln(term.red(msg))
}

fn (_ LoggerWarnLevel) warn(msg string) {
    xprintln(term.yellow(msg))
}

fn (_ LoggerWarnLevel) info(msg string) {
}

fn (_ LoggerWarnLevel) debug(msg string) {
}

fn (_ LoggerDebugLevel) info(msg string) {
    xprintln(term.green(msg))
}

fn (_ LoggerDebugLevel) debug(msg string) {
    xprintln(term.blue(msg))
}
