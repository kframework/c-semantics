See [INSTALL.md](INSTALL.md) for installation instructions and [LICENSE](LICENSE) for licensing
information.

If this readme isn't enough, consider checking out these papers to better
understand this project:

- Chucky Ellison and Grigore Rosu. An Executable Formal Semantics of C with 
  Applications. *POPL'12*. 
  <http://fsl.cs.uiuc.edu/pubs/ellison-rosu-2012-popl.pdf>
- Chucky Ellison. *A Formal Semantics of C with Applications*. PhD Thesis.
  <http://fsl.cs.uiuc.edu/pubs/ellison-2012-thesis.pdf>

## Quick overview

- `kcc` is meant to to act a lot like `gcc`. You use it and run programs the
  same way.
- The programs `kcc` generates act like normal programs. Both the output to
  stdout (e.g., `printf`), as well as the return value of the program should be
  what you expect. In terms of operational behavior, a correct program compiled
  with kcc should act the same as one compiled with `gcc`.
- Take a look at `kcc -h` for some compile-time options. For most programs,
  you only need to run `kcc program.c` and everything will work.
- After compiling a program and generating an output file `a.out`, running
  `HELP=1 ./a.out` will display some runtime options, including `SEARCH`,
  `PROFILE`, and `LTLMC`. Notice that these extra interpreter options are
  passed via environment variables and not on the command line. This allows us
  to pass the actual command line parameters straight to the `kcc`-compiled
  program, unchanged.
- If you try to run a program that is undefined (or one for which we are
  missing semantics), the program will get stuck. The message should tell you
  where it got stuck and may give a hint as to why. If you want help
  deciphering the output, or help understanding why the program is undefined,
  please send your final configuration to us. This can be generated using
  either the `DUMPALL` flag on `kcc`-generated executables (e.g., `DUMPALL=1
  ./a.out`) or via `kcc -d` in the case of "compile-time" errors.

## Runtime features

Once `kcc` has been run on C source files, it should produce an executable
script (`a.out` by default).

### Searching the state-space of non-deterministic behaviors

Running `SEARCH=1 ./a.out` will exhaustively search the state space resulting
from considering all possible expression sequencings (as allowed by the
standard) and generate a .pdf and .ps of the space (if Graphviz is installed).
This is the only way to check all possible evaluation orders of a program to
find undefined behavior.

Likewise, running `THREADSEARCH=1 ./a.out` will exhaustively search the state
space resulting from non-deterministic interleaving of threads as described in
the standard. Very experimental.

See [examples/README.md](examples/README.md#search) for more details.

### LTL model checking

We also support LTL model checking of the possible executions resulting from
considering different expression sequencings.

See [examples/README.md](examples/README.md#ltl-model-checking) for more details.

### Profiling the semantics

Running `PROFILE=1 ./a.out` will record which rules of the semantics are
exercised during the evaluation of a program. The program executes as normal,
but this additional information is recorded in an SQLite database
`kccProfileDB.sqlite` in your current directory. You can access the
information by running queries against the database. Some sample queries are
provided by the `query-kcc-prof` script, and can be executed with, e.g., 
```
$ query-kcc-prof exec
```
You can look at the provided queries (see [scripts/query-kcc-prof][]) and
construct your own, or access the database using your own programs. Different
runs of the tool are kept distinct in the database, so you can run a bunch of
programs and then analyze the collective data. You can simply delete the
`kccProfileDB.sqlite` file to start another series of tests with a fresh
database.

### Testing the semantics

The [tests][] directory includes many of the tests we've used to build confidence
in the correctness of our semantics. For example, to run tests from the GCC
torture test suite, use the following command from the [tests][] directory:
```
$ make torture
```
And to run the undefinedness test suite:
```
$ make undef
```

## Project structure

Directories:

- [examples][]: some simple example programs for trying out the SEARCH and
  LTLMC features.

- [libc][]: library headers and some library sources for functions that aren't
  defined directly in the semantics itself.

- [parser][]: the lightly modified OCaml CIL C parser.

- [scripts][]: e.g., the `kcc` script and `program-runner`, the script that
  becomes `a.out`.

- [semantics][]: the K C semantics.

- [tests][]: undefinedness, gcc-torture, juliet, llvm, etc.

- `dist`: created during the build process, this is where the final products
  go. For convenience, consider adding this directory to your `$PATH`.

During the build process, three versions of the semantics are built using
`kompile` with different flags: a "deterministic" version, a version for
supporting non-deterministic expression sequencing, and another with
non-deterministic thread-interleaving. These all get copied to `dist/` along
with the contents of [libc][] and the [scripts/kcc][] script. Finally, make
runs `kcc -c` on all the libc source files in [libc/src][].

The `kcc` script is the primary interface to our semantics. Invoking `kcc
myprogram.c` results in the contents of the parameter C source file being piped
through, consecutively:

1. the GNU C preprocessor, resulting in the C program with all preprocessor
   macros expanded;
2. the CIL C parser (cparser), resulting in an XML AST;
3. and finally the `xml-to-k` script, resulting in a K-ified AST.

The root of this AST is a single `TranslationUnit` term, which is then
interpreted by our "translation" semantics.

See [semantics/README.md][] for more details.

[semantics/README.md]: semantics/README.md
[semantics/language/dynamic.k]: semantics/language/dynamic.k
[scripts/kcc]: scripts/kcc
[scripts/program-runner]: scripts/program-runner
[scripts/query-kcc-prof]: scripts/query-kcc-prof
[examples]: examples
[libc]: libc
[libc/src]: libc/src
[parser]: parser
[scripts]: scripts
[semantics]: semantics
[tests]: tests
[INSTALL.md]: INSTALL.md
[LICENSE]: LICENSE
