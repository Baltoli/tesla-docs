# TESLA Commands

## `analyse`

### Summary

Extracts TESLA assertions from a program and output them to an assertion manifest
file. Takes a single C source file as an argument, and produces a TESLA
assertion file in either binary or textual format.

Because `tesla analyse` is implemented as a [Clang tool][libtooling], it needs
to be given the compilation options for the file it's analysing (so that it can
properly handle preprocessor definitions and other program features). Currently,
these options need to be given at the command line---using
`compile_commands.json` is not yet supported.

### Usage

```shell
tesla analyse [options] <source> -o <output> -- [compilation options]
```

Note that even if your code has no specific command line options, you must still
terminate the list of arguments to `tesla analyse` with `--`.

### Options

* `-S`: generate textual TESLA output (rather than binary) for debugging
  purposes.

## `cat`

### Summary

Combine multiple TESLA assertion files together into a single file for
instrumentation.

Takes all the assertion files as positional arguments, and a single output file
as a named argument. If no output is specified, the resulting assertion manifest
is output on `stdout`. The output of `tesla cat` is always a textual manifest
(rather than binary).

Because each source file produces its own assertion file, which can reference
automata defined in other files, we need to combine them together (while also
checking for consistency---if two files both define an automata, the definitions
need to be the same).

### Usage

```shell
tesla cat <input ...> -o <output>
```

## `instrument`

### Summary
### Usage
### Options

## `print`

### Summary
### Usage
### Options

## `static`

### Summary
### Usage
### Options

[libtooling]: https://clang.llvm.org/docs/LibTooling.html
