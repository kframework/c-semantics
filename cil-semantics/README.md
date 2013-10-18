### A bit about how things work:

The `kcil` and `kcil-runner` scripts are copied from the C semantics with very
few changes. In particular, many of the options they might say they support
might not be supported in their CIL versions.

In the C semantics' `kcc` script, C source files are parsed into K syntax (in
place of the compile step) before being run by `krun`. In the CIL semantics,
instead of parsing, we run C source files through the `kcil-pp` script.
`kcil-pp` does these things:

1. It runs the file through `cilly` with the `--includedir` parameter set to
`./lib/includes` to generate CIL source. This means that our `kcil` script will
accept arbitrary C source and transform it into CIL source. We do things this
way (at least in part) to make testing against `gcc` easier. Because `cilly`
wants to expand all the preprocessor directives (i.e., `#include`), CIL source
seems to necessarily include implementation details of the particular standard
library whose headers are being included. We can't, for example, run all the
GCC torture tests through `cilly` and then test the results against both `gcc`
and `kcil` because when we generate the CIL we need to choose which headers we
use for the standard library -- either the GNU C library or our own library
headers -- and they're incompatible. I suppose in the future it might make
sense to just support the GNU C library.

2. It prepends `#pragma KCIL_TU "filename"` to the source file. During the
"link" phase, we flatten all source files into a single file, so this allows us
to tell one translation unit from another.

3. Removes a few `gcc`isms that might be present (currently just the
`__attribute__` syntax).

### How to use and test the CIL semantics:

1. Make sure `kompile` and `krun` are in your `$PATH`.

2. Kompile the semantics: `kompile cil` from this directory.

3. Make sure `kcil` and `kcil-pp` are in your `$PATH`.

4. To interpret a script, `kcil` should behave the same as `kcc`:
```
$ kcil my_cil_or_c_file.c
$ ./a.out
```

5. To debug, pass the `DUMPALL=1` option to `a.out`:
```
$ DUMPALL=1 ./a.out
```
This should result in a `tmp-kcil-out-*` containing the raw final
configuration.

6. To test the semantics against `gcc`:
```
$ cd tests
$ ./runtests -p gcc-torture
```
Where `gcc-torture` is a directory full of source files.

### Things that I know of that aren't currently supported:

- File I/O. In particular, `printf`. It'd be nice to grab the `printf`
  implementation (and the rest of the I/O stuff) from the C semantics. It
  should be possible, but I don't think it'll be completely trivial.

- Various other parts of the standard library.

- Arguments to `main`. Currently, if `main` wants an argument, it gets zeros,
  regardless of what the command line looks like. All of the support for this
  exists in `kcil-runner`, though -- `$ARGV` and `$ARGC` just need to be added
  to the configuration in the apropriate place.

- Variable length arrays (these do appear in the torture tests).

- Some details regarding char (and probably string) literals.

- See the TODOs scattered about in comments for more details.
