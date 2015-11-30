See [INSTALL.md](INSTALL.md) for installation instructions and [LICENSE](LICENSE) for licensing
information.

If this readme isn't enough, consider checking out these papers to better
understand this project:

- Chris Hathhorn, Chucky Ellison, and Grigore Rosu. Defining the
  Undefinedness of C. *PLDI'15*.
  <http://fslweb.cs.illinois.edu/FSL/papers/2015/hathhorn-ellison-rosu-2015-pldi/hathhorn-ellison-rosu-2015-pldi-public.pdf>
- Chucky Ellison and Grigore Rosu. An Executable Formal Semantics of C with 
  Applications. *POPL'12*. 
  <http://fsl.cs.uiuc.edu/pubs/ellison-rosu-2012-popl.pdf>
- Chucky Ellison. *A Formal Semantics of C with Applications*. PhD Thesis.
  <http://fsl.cs.uiuc.edu/pubs/ellison-2012-thesis.pdf>

## Quick overview

- `kcc` is meant to to act a lot like `gcc`. You use it and run programs the
  same way. If your system provides a command `kcc` already (of which there are
  several possible), we also provide the synonym `kclang`.
- The programs `kcc` generates act like normal programs. Both the output to
  stdout (e.g., `printf`), as well as the return value of the program should be
  what you expect. In terms of operational behavior, a correct program compiled
  with kcc should act the same as one compiled with `gcc`.
- Take a look at `kcc -h` for some compile-time options. For most programs,
  you only need to run `kcc program.c` and everything will work.
- After compiling a program and generating an output file `a.out`, the
  resulting program is a native executable and can be run on any platform
  provided it has access to the runtime libraries required by the dynamic
  linker.
- If you try to run a program that is undefined (or one for which we are
  missing semantics), the program will get stuck. The message should tell you
  where it got stuck and may give a hint as to why. If you want help
  deciphering the output, or help understanding why the program is undefined,
  please send your final configuration to us. If you are using default settings,
  this configuration is located in the file `config` in the current directory
  if the program got stuck while executing, or can be generated using `kcc -d`
  in case of compile-time errors.

## Runtime features

Once `kcc` has been run on C source files, it should produce an executable
script (`a.out` by default).

### Testing the semantics

The [tests][] directory includes many of the tests we've used to build confidence
in the correctness of our semantics. To run the basic set of tests, run `make check`
from the top-level directory. For performance reasons, you may first wish to run 
`kserver` in the background, and pass a `-j` flag to make to get the desired level
of parallelism.

## A note on libraries

KCC comes by default with relatively limited support for the C library. If you are
compiling and linking a program that makes use of many library functions, you may likely
run into CV-CID1 and UB-TDR2 errors, signifying respectively that the function you are
calling was not declared in the appropriate header file, or that it was declared, but
no definition exists currently in the semantics.

We recommend if you wish to execute such programs that you contact Runtime Verification,
Inc, which licenses a tool RV-Match based on this semantics which is capable of executing
such programs by linking against the native code provided on your system for these libraries.
For more information, contact https://runtimeverification.com/support.

## Project structure

Directories:

- [examples][]: some simple example programs for demonstrating the undefinedness that we 
  can catch.

- [x86-gcc-limited-libc][]: library headers and some library sources for functions that aren't
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
with the contents of [x86-gcc-limited-libc/include][] and the [scripts/kcc][] script. Finally, make
runs `kcc -s -shared` on all the libc source files in [x86-gcc-limited-libc/src][].

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
[x86-gcc-limited-libc]: x86-gcc-limited-libc
[x86-gcc-limited-libc/src]: x86-gcc-limited-libc/src
[parser]: parser
[scripts]: scripts
[semantics]: semantics
[tests]: tests
[INSTALL.md]: INSTALL.md
[LICENSE]: LICENSE
