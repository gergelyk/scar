import os

fn (a App) read_archive_lines(archive_path string, target_dir string) ! []string {
    mut lines := []string{}
    if archive_path == '' {
        a.log.info('Extracting stdin as an archive into "${target_dir}" directory.')
        lines = os.get_raw_lines_joined().split_into_lines()
    } else {
        a.log.info('Extracting "${archive_path}" archive into "${target_dir}" directory.')
        lines = os.read_lines(archive_path) or {
            a.log_cause(err)
            return error('Cannot read from "${archive_path}".')
        }
    }
    return lines
}

fn (a App) process_lines(lines []string, target_dir string, prefix string) ! {
    mut target_file := os.File{}
    defer { target_file.close() }

    for line in lines {

        mut target_abs_path := ''
        if target_file_path := a.extract_target_file_path(prefix, line) {
            target_abs_path = os.abs_path(os.expand_tilde_to_home(target_dir + '/' + target_file_path))
            target_parent_dir := os.dir(target_abs_path)

            a.log.info('Writing to "${target_abs_path}".')
            os.mkdir_all(target_parent_dir) or {
                a.log_cause(err)
                return error('Cannot create directory "${target_parent_dir}".')
            }

            target_file = os.open_file(target_abs_path, 'w+') or {
                a.log_cause(err)
                return error('Cannot create file "${target_abs_path}".')
            }
        } else {
            if target_file.is_opened {
                target_file.write_string(line + '\n') or {
                    a.log_cause(err)
                    return error('Cannot write to "${target_abs_path}".')
                }
            } else {
                 a.log.debug('HEADER : ' + line)
            }
        }
    }
}

fn (a App) extract(archive_path string, target_dir string, prefix_opt string) ! {
    lines := a.read_archive_lines(archive_path, target_dir)!
    prefix := a.determine_prefix(prefix_opt, archive_path, []string{})!
    a.process_lines(lines, target_dir, prefix)!
}
