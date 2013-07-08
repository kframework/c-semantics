See INSTALL.md for installation instructions and LICENSE for licensing
information.

## Usage

### Quick overview
- `kcc` is meant to to act a lot like `gcc`. You use it and run programs the
  same way.
- The programs `kcc` generates act like normal programs. Both the output to
  stdio (e.g., `printf`), as well as the return value of the program should be
  what you expect. In terms of operational behavior, a correct program
  compiled with kcc should act the same as one compiled with `gcc`.
- Take a look at `kcc -h` for some compile-time options. For most programs,
  you only need to run `kcc program.c` and everything will work.
- After compiling a program and generating an output file `a.out`, running
  `HELP=1 ./a.out` will display some runtime options, including `SEARCH`, 
  `PROFILE`, and `LTLMC`.
- If you try to run a program that is undefined (or one for which we are
  missing semantics), the program will get stuck. The message should tell you
  where it got stuck and may give a hint as to why. If you want help
  deciphering the output, or help understanding why the program is defined,
  please send your `.kdump` file to us.

### Runtime features

Once `kcc` has been run on C source files, it should produce an executable
script (`a.out` by default).

#### Searching the state-space of non-deterministic behaviors

Running "SEARCH=1 ./a.out" will exhaustively search the state space resulting
from considering all possible expression sequencings (as allowed by the
standard) and generate a .pdf and .ps of the space (if Graphviz is installed).
This is the only way to check all possible evaluation orders of a program to
find undefined behavior.

Likewise, running "THREADSEARCH=1 ./a.out" will exhaustively search the state
space resulting from non-deterministic interleaving of threads as described in
the standard. Very experimental.

See examples/README.md for more details.

#### LTL model checking

We also support LTL model checking of the possible executions resulting from
considering different expression sequencings.

See examples/README.md for more details.

#### Profiling the semantics

Running `PROFILE=1 ./a.out` will record which rules of the semantics are
exercised during the evaluation of the program. The program executes as normal,
but this additional information is recorded in an SQLite database
`maudeProfileDB.sqlite` in your current directory. You can access the
information by running queries against the database. Some sample queries are
provided in the dist directory, and can be tried by running, e.g., 
```
$ query-kcc-prof exec
```
You can look at the provided queries (see the `query-kcc-prof` script) and
construct your own, or access the database using your own programs. Different
runs of the tool are kept distinct in the database, so you can run a bunch of
programs and then analyze the collective data. You can simply delete
`maudeProfileDB.sqlite` file to start another series of tests with a fresh
database.

#### Testing the semantics

The `tests` directory includes many of the tests we've used to build confidence
in the correctness of our semantics. For example, to run tests from the GCC
torture test suite, use the following command from the `tests/` directory:
```
$ make torture
```

### Caveats and miscellanea

- If not using the standard library, consider `kcc`'s `-s` flag in order to
  prevent the tool from linking in the standard library. This can greatly
  reduce the size of the configuration for small test programs and make the
  output of state-space search and model checking more manageable.

## Understanding the semantics

Links to help understand K:
- http://code.google.com/p/k-framework/
- http://k-framework.org/ 

See `semantics/README.md` for more details.
