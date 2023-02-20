import os

const intro = 'This is a source code archive. Extract it using SCAR: https://github.com/gergelyk/scar'

fn (mut a App) read_input_lines(filename string, archive_path string) ? []string {
        if filename == archive_path {
            a.log.warn('Output file cannot be used as input. File "${filename}" skipped.')
            return none
        }

        a.log.info('Reading "${filename}"')
        lines := os.read_lines(filename) or {
            a.log.error('Cannot read "${filename}". Skipped.')
            return none
        }

        return lines
}

fn (mut a App) coerce_filename(filename string) string {
    filename_coerced := a.coercing_regex.replace_simple(filename, '_')
    if filename != filename_coerced {
        a.log.warn('Filename "${filename}" not supported. File will be renamed to "${filename_coerced}".')
    }
    return filename_coerced
}

type WriteLn = fn (string) !
type WriteLnClose = fn ()

fn (a App) get_writeln_fn(archive_path string) ! (WriteLn, WriteLnClose) {

    mut writeln := fn (line string) ! { println(line) }
    mut writelnclose := fn () { }

    if archive_path != '' {

        mut fh_out := os.create(archive_path) or {
            a.log_cause(err)
            return error('Failed to create "${archive_path}".')
        }

        writeln = fn [a, mut fh_out, archive_path] (line string) ! {
            fh_out.write_string(line + '\n') or {
                a.log_cause(err)
                return error('Cannot write to "${archive_path}".')
            }
        }

        writelnclose = fn [a, mut fh_out, archive_path] () {
            fh_out.close()
            a.log.info('Archive created: "${archive_path}"')
        }
    }
    return writeln, writelnclose
}

fn (mut a App) archive(archive_path string, input_files []string, prefix_opt string) ! {

    prefix := a.determine_prefix(prefix_opt, archive_path, input_files)!
    writeln, writelnclose := a.get_writeln_fn(archive_path)!
    defer { writelnclose() }
    writeln('${prefix} ${intro}')!

    for filename in input_files {
        lines := a.read_input_lines(filename, archive_path) or { continue }
        filename_coerced := a.coerce_filename(filename)
        writeln('\n${prefix} ${filename_coerced}')!
        for line_idx, line in lines {
            a.extract_target_file_path(prefix, line) or {
                writeln(line)!
                continue
            }
            a.log.warn('Line ${line_idx+1} in "${filename}" looks like a file header. Line skipped.')
        }
    }

}
