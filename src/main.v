module main

import flag
import os

fn main() {
    mut fp := flag.new_flag_parser(os.args)
    fp.description('Source Code Archiver')
    fp.application('scar') // TODO: take it form v.mod
    fp.version('v0.1.0') // TODO: take it form v.mod
    fp.skip_executable()
    fp.arguments_description('SOURCE_FILES | TARGET_DIR')
    fp.footer('\nExamples:\n' +
        '  $ scar -c -f myarchive.py *.py  # create an archive of your python files\n' +
        '  $ scar -x -f myarchive.py here  # extract your archive into "here" directory\n'
    )

    // vfmt off
    create_flag      := fp.bool(  'create',  `c`, false, 'create an archive of SOURCE_FILES')
    extract_flag     := fp.bool(  'extract', `x`, false, 'extract the archive into TARGET_DIR')
    verbose_flag     := fp.bool(  'verbose', `v`, false, 'provide more detailed messages')
    prefix_opt       := fp.string('prefix',  `p`, '',    'comment prefix, auto-detected by default')
    archive_path_opt := fp.string('output',  `f`, '',    'archive file, default: stdin/stdout')
    // vfmt on

    mut app := new_app(verbose_flag)

    cli_fatal := fn [app, fp] (msg string) { app.fail(.cli_error, msg, hint: fp.usage()) }

    extra_args := fp.finalize() or {
        cli_fatal(err.msg())
        return // TODO: remove this line when cli_fatal can have [noreturn] attribute
    }

    if extract_flag && create_flag {
        cli_fatal('You cannot mix options: -c and -x')
    }

    if extract_flag {
        mut target_dir := '.'
        if extra_args.len == 1 {
            target_dir = extra_args.first()
        } else if extra_args.len > 1 {
			cli_fatal('To many positional arguments.')
        }
        app.extract(archive_path_opt, target_dir, prefix_opt) or { app.fail(.runtime_error, err.msg()) }
    } else if create_flag {
        if extra_args.len == 0 {
            cli_fatal('At least one source file must be provided.')
        }
        app.archive(archive_path_opt, extra_args, prefix_opt) or { app.fail(.runtime_error, err.msg()) }
    } else {
        cli_fatal('You must specify one of options: -c or -x')
    }

}
