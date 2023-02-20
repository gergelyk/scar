module main
import regex

const (
    comment_prefixes = {
        '#': 'py,ipy,cr,sh,elv,ion,fish,xsh,rb,r,nim,pl',
        '//': 'v,h,hpp,c,cpp,rs,go,js,ts,java,kt,php,swift,scala,sc,re',
        '--': 'lua,elm,vhdl,hs,sql',
        '%': 'm',
        ';;': 'clj',
        '\'': 'vb,vbs',
    }
)

enum ExitCode {
    runtime_error = 1
    cli_error = 2
}

fn get_comment_prefixes() map[string]string {
    mut mapping := map[string]string{}
    for comment_prefix, file_suffxes in comment_prefixes {
        for file_suffix in file_suffxes.split(',') {
            mapping[file_suffix] = comment_prefix
        }
    }
    return mapping
}

fn (a App) extract_target_file_path(prefix string, line string) ? string {
    if !line.starts_with(prefix + ' ') { return none }
    path := line[prefix.len..].trim(' ')
    if path.contains(' ') { return none }
    parts := path.split('/')

    for part in parts {
        if part.len == 0 { return none }
        if part.ends_with('.') { return none }
        if !a.target_file_regex.matches_string(part) { return none }
    }
    return path
}

fn (a App) log_cause(cause IError) {
    if cause.msg() != '' {
        a.log.debug('Cause: ${cause}')
    }
}

struct App {
    prefixes map[string]string
    mut:
    target_file_regex regex.RE
    coercing_regex regex.RE
    log ILogger
}

fn new_app(verbose bool) App {

    prefixes := get_comment_prefixes()

    mut log := ILogger(LoggerWarnLevel{})
    if verbose {
        log = LoggerDebugLevel{}
    }
    target_file_regex := regex.regex_opt('^[0-9a-zA-Z_\\-\\.]+$') or { panic(err) }
    mut coercing_regex := regex.regex_opt('[^_a-zA-Z0-9\\.\\-/]') or { panic(err) }
    return App{prefixes, target_file_regex, coercing_regex, log}
}

fn (a App) prefix_from_opt(prefix_opt string) ? string {
    if prefix_opt == '' {
        return none
    }
    a.log.debug('Prefix specified explicitely.')
    return prefix_opt
}

fn (a App) prefix_from_archive_path(archive_path string) ? string {
    if archive_path == '' {
        return none
    }
    parts := archive_path.split('.')
    if parts.len == 1 {
        a.log.debug('Suffix not available.')
        return none
    }
    path_suffix := parts.last().to_lower()
    prefix := a.prefixes[path_suffix] or {
        a.log.debug('Unknown file suffix "${path_suffix}".')
        return none
    }
    a.log.debug('Prefix determined based on the suffix of the archive.')
    return prefix
}

fn (a App) prefix_from_input_files(filenames []string) ? string {
    mut filename_suffixes_in_use := []string{}

    for filename in filenames {
        parts := filename.split('.')
        suffix := parts.last().to_lower()
        if parts.len > 1 && !(suffix in filename_suffixes_in_use) {
            filename_suffixes_in_use << suffix
        }
    }

    a.log.debug('Filename suffixes in use: ${filename_suffixes_in_use}')

    mut comment_prefixes_in_use := []string{}

    for suffix in filename_suffixes_in_use {
        if suffix in a.prefixes {
            prefix := a.prefixes[suffix]
            if !(prefix in comment_prefixes_in_use) {
                comment_prefixes_in_use << prefix
            }
        } else {
            a.log.warn('Unknown file suffix: ${suffix}')
        }
    }

    a.log.debug('Comment prefixes in use: ${comment_prefixes_in_use}')

    if comment_prefixes_in_use.len == 0 {
        return none
    } else if comment_prefixes_in_use.len > 1 {
        a.log.debug('Ambiguous comment prefix.')
        return none
    }

    return comment_prefixes_in_use.first()
}

fn (a App) determine_prefix(prefix_opt string, archive_path string, filenames []string) ! string {
    prefix := a.prefix_from_opt(prefix_opt) or {
        a.prefix_from_archive_path(archive_path) or {
            a.prefix_from_input_files(filenames) or {
                return error('Comment prefix cannot be determined. Use -p option.')
    }}}
    a.log.info('Prefix in use: "${prefix}"')
    return prefix
}

[params]
struct FailKwArgs {
    hint string
    error IError = error('')
}

[noreturn]
fn (a App) fail(exit_code ExitCode, msg string, kwargs FailKwArgs) {
    if kwargs.error.msg() != '' {
        a.log.debug('Error: ${kwargs.error}')
    }
    a.log.error(msg)
    if kwargs.hint != '' {
        println(kwargs.hint)
    }
    a.log.debug('Exiting with code: ${int(exit_code)} (${exit_code})')
    exit(int(exit_code))
}
