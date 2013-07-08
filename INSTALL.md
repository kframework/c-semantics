## Installation

Please let us know if these instructions are insufficient or if you needed to
do any installation steps not listed explicitly.

### 1. Install basic dependencies.
- Our `kcc` tool uses the GNU C preprocessor (cpp), so you'll at least
  need that installed. 
- If using Windows, you'll probably need cygwin.

### 2. Install Perl 5.
- Perl 5 will likely already be installed on most Linux and Mac OS X machines.
  But if not, use your package manager to install it.
- For Windows, see here: http://www.perl.org/get.html
- Install the following Perl modules using `cpan` (or `ppm` with ActiveState
  Perl in Windows):
    - XML::LibXML::Reader
    - Text::Diff
    - DBI
    - DBD::SQLite
    - Getopt::Declare

E.g., to install a Perl module using cpan:
```
$ cpan -i XML::LibXML::Reader
```

(It might help to do this as sudo if it doesn't work as a normal user.)

### 3. Install OCaml.
- We use a modified version of the C parser from the CIL project, which is
  written in OCaml.
- Install OCaml from http://caml.inria.fr/ or via your package manager.
- Versions 3.11, 3.12, and 4.00 all work; probably many others work as well.

To check if OCaml is installed:
```
$ ocaml
        Objective Caml version 4.00.0

# 
```

(Press ctrl-d to exit.)

### 4. Install K.
- Download the K Framework from:
  https://code.google.com/p/k-framework/wiki/Downloads
- See the README included with K for build and installation instructions.

### 5. Install optional packages.
- You may want to install Graphviz (dot), for generating images of the state
  space when searching programs.
- You can probably do this with your package manager.
      
To check if dot is installed:
```
$ which dot
/usr/bin/dot
```

### 6. Build our C tool.
- Set C_K_BASE to the full (non-relative) path in which you installed the K
  framework. E.g., run `export C_K_BASE=~/k-framework/dist`.
- Run `make` in the project root directory.
- This should take between 1 and 5 minutes on non-windows machines, and up to
  10 minutes on windows.
- The `make` process creates a `dist/` directory which you can copy elsewhere
  to install the C tool, or simply leave it where it is. Either way, you will
  probably want to add it to your `$PATH`:
```
export PATH=/path/to/c-semantics/dist:$PATH
```
      
To check if kcc is behaving correctly:
```
$ dist/kcc tests/unitTests/helloworld.c
$ ./a.out 
Hello world
```

See README.md for a summary of the features supported by the `kcc` tool.

