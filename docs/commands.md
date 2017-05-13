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

Add TESLA instrumentation code to LLVM IR.

The assertion code to be added is generated from a TESLA assertion manifest, and
replaces instrumentation hooks.

### Usage

```shell
tesla instrument -tesla-manifest <manifest> <IR file> -o <output>
```

### Options

* `-S`: print textual LLVM IR instead of binary. If this is specified, then `-o`
  can be omitted and the output will go to `stdout`.

## `print`

### Summary

Print TESLA automata information from an assertion manifest.

Supports multiple formats for the printed information.

### Usage

```shell
tesla print [options] <input file>
```

### Options

* Output formats (`-format=`):
    * `dot`: GraphViz dot
    * `instr`: instrumentation points
    * `names`: automata names
    * `source`: automata definitions from the original source code
    * `summary`: succinct summaries
    * `text`: textual automata representations
* Automata determinism:
    * `-r`: raw (unlinked) NFA
    * `-n`: NFA
    * `-d`: DFA

## `static`

### Summary

Perform static analysis on an assertion manifest, producing a new manifest with
safe assertions deleted.

### Usage

```shell
tesla static [options] <manifest> <IR> -o <output>
```

### Options

* Pass selection:
    * `-mc`: Run the TESLA model checker.
* Model checker options:
    * `-bound=<int>`: set the maximum length of finite traces to examine
      (measured in the number of basic blocks).
    * `-unroll=<int>`: set the maximum function call inlining depth. If your
      call graph is deeper than this value, information can be lost at the
      inlining phase.
    * `-mem2reg`: run the LLVM memory to register promotion pass before the
      model checker. This can make the checker run a lot faster, but loses
      information about variable names. Some assertions will be incorrectly
      marked as unsafe if using this option.

[libtooling]: https://clang.llvm.org/docs/LibTooling.html
