module main

fn test_get_comment_prefixes() {
	app := new_app(false)
	prefixes := get_comment_prefixes()
	assert prefixes['py'] == '#'
	assert prefixes['cpp'] == '//'
}

fn test_successful_extract_target_file_path() {
	app := new_app(false)
	assert app.extract_target_file_path('#', '# foo.py')! == 'foo.py', 'file in cwd'
	assert app.extract_target_file_path('#', '# foo-bar_baz123.py')! == 'foo-bar_baz123.py', 'complex name'
	assert app.extract_target_file_path('#', '# foo/bar.py')! == 'foo/bar.py', 'file in subdirectory'
	assert app.extract_target_file_path('#', '# bar')! == 'bar', 'file withouth suffix'
	assert app.extract_target_file_path('#', '# foo/bar')! == 'foo/bar', 'file withouth suffix in subdirectory'
	assert app.extract_target_file_path('#', '# foo.py  ')! == 'foo.py', 'trailing spaces'
	assert app.extract_target_file_path('#', '#   foo.py')! == 'foo.py', 'leading spaces'
}

fn test_unsuccessful_extract_target_file_path() {
	app := new_app(false)
	assert 'none' == app.extract_target_file_path('#', '') or { 'none' }, 'empty string'
	assert 'none' == app.extract_target_file_path('#', 'foo.py') or { 'none' }, 'missing prefix'
	assert 'none' == app.extract_target_file_path('#', '- foo.py') or { 'none' }, 'incorrect prefix'
	assert 'none' == app.extract_target_file_path('#', ' # foo.py') or { 'none' }, 'space before prefix'
	assert 'none' == app.extract_target_file_path('#', '# foo.py.') or { 'none' }, 'trailing period'
	assert 'none' == app.extract_target_file_path('#', '# foo bar.py') or { 'none' }, 'space in the name'
	assert 'none' == app.extract_target_file_path('#', '# foo+bar.py') or { 'none' }, 'illegal character in name'
	assert 'none' == app.extract_target_file_path('#', '# /foo.py') or { 'none' }, 'file in the root directory'
	assert 'none' == app.extract_target_file_path('#', 'foo.py/') or { 'none' }, 'trailing slash'
	assert 'none' == app.extract_target_file_path('#', 'foo//bar.py') or { 'none' }, 'directory with missing name'
}

fn test_successful_determine_prefix() {
	app := new_app(false)

	// prefix provided explicitely
	assert '#' == app.determine_prefix('#', '', []string{}) or { 'error' }
	assert '#' == app.determine_prefix('#', 'arch.cpp', ['foo.cpp', 'bar.cpp']) or { 'error' }

	// prefix based on archive suffix
	assert '#' == app.determine_prefix('', 'arch.py', []string{}) or { 'error' }
	assert '#' == app.determine_prefix('', 'arch.py', ['foo.cpp', 'bar.cpp']) or { 'error' }

	// prefix based on input files
	assert '#' == app.determine_prefix('', '', ['foo.py', 'bar.py', 'baz.elv']) or { 'error' }
	assert '#' == app.determine_prefix('', 'arch.blah', ['foo.py', 'bar.PY']) or { 'error' }
}

fn test_unsuccessful_determine_prefix() {
	app := new_app(false)
	assert 'error' == app.determine_prefix('', '', []string{}) or { 'error' }
	assert 'error' == app.determine_prefix('', 'py', []string{}) or { 'error' }
	assert 'error' == app.determine_prefix('', 'foo.blah', []string{}) or { 'error' }
	assert 'error' == app.determine_prefix('', '', ['py', 'cpp']) or { 'error' }
	assert 'error' == app.determine_prefix('', '', ['foo.py', 'bar.cpp']) or { 'error' }
}
