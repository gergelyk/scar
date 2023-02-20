# SCAR - Source Code Archiver

Creates and extracts human-readable archives that include source code. It is designed for small code snippets that span
across multiple files.

## How it works

Input files are copied into archive file without any processing. Each file is prepended by a single-line comment, that
contains corresponding file path.

Archiver works with any text files. The only thing that it needs to know is prefix that comments in the archive should
begin with. Prefix is recognized based on the suffix of the archive file. If archive is written to stdout, suffixes of
the input files are used to determine prefix. Prefix can be also defined explicitely using `-p` option.

## Limitations

File paths must be relative paths in Unix format. Names of the files and directories must consist of lower or upper case
letters, digits and characters: `-`, `_`, `.`  Target directories will be created in the extraction process.

Archived files themselves should not contain comments of the format described above. Otherwise, they would be confused
with desired filenames. If any of your files contain such comment, you can for instanse add `.` at the end of
it. SCAR will consider such comment as regular content, because `.` cannot appear at the end of supported filenames.

Comments that require prefix and suffix, e.g. HTML style: `<!-- foo.html -->` are not supported. Use `-p` option to
specify custom comment prefix for such sources.

## Example

Creating archive of python files from current directory may look like bellow:
```sh
 scar -c *.py -f myarchive.py
```

and produce `myarchive.py` file with following content:

```py
# This is a source code archive. Extract it using SCAR: https://github.com/gergelyk/scar

# greeting.py
def show():
    print("Hello world!")

# main.py
import greeting

if __name__ == '__main__':
    greeting.show()
```

Extracting archive into current directory would look like:
```sh
 scar -x -f myarchive.py
```

Invoke `scar --help` for more usage examples.

Use `-v` flag to make scar more verbouse. Messages are printed to stderr.

## Use cases:

Your code snippet consists of multiple files and you want to:
- send it in a a human-readable form to your friend
- publish it on a web page
- store it as a single file in your notes
- place it in a git repo and extract as an input or reference output for your tests

## Development

Requirements: `vlang >= 0.3.3`.

```sh
# build & run
v run .

# test
v test .

# release
v -prod .
```
