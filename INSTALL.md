## Installation

**NOTE**: A more powerful version of the C semantics capable of recovering from 
errors and detecting a broader range of undefined and undesirable behaviors 
can be found at https://runtimeverification.com/match.

---

Please let us know if these instructions are insufficient or if you needed to
do any installation steps not listed explicitly.

We recommend using Linux or OSX on a computer with at least 1 GB of memory.

On Ubuntu, the installation process for our C semantics can be summarized as:
```
$ git clone --depth=1 https://github.com/runtimeverification/k.git
$ cd k
$ mvn package
$ export PATH=$PATH:`pwd`/k-distribution/target/release/k/bin
$ mvn dependency:copy -Dartifact=com.runtimeverification.rv_match:ocaml-backend:1.0-SNAPSHOT -DoutputDirectory=k-distribution/target/release/k/lib/java
$ git clone --depth=1 https://github.com/kframework/c-semantics.git
$ sudo apt-get install build-essential diffutils libxml-libxml-perl libstring-escape-perl libgetopt-declare-perl opam
$ k-configure-opam-dev
$ eval `opam config env`
$ cd c-semantics
$ make -j4
$ export PATH=$PATH:~/c-semantics/dist
```

### 1. Install basic dependencies.
- The GNU C compiler (GCC), Make, diff, and patch. On OSX, these programs are generally part
  of XCode. On Ubuntu, these programs are part of the "build-essential" and "diffutils" packages
  and can be installed with the following:
```
$ sudo apt-get install build-essential diffutils
```
- If using Windows, you'll probably want to install cygwin.

### 2. Install Perl 5 and required modules.
- Perl 5 will likely already be installed on most Linux and Mac OS X machines.
  But if not, use your package manager to install it.
- For Windows, see here: <http://www.perl.org/get.html>
- Install the following Perl modules using `cpan` (or `ppm` with ActiveState
  Perl in Windows):
    - Getopt::Declare
    - MIME::Base64
    - XML::LibXML::Reader
    - String::Escape

You can also install them using apt-get with
```
$ sudo apt-get install libxml-libxml-perl libgetopt-declare-perl libstring-escape-perl
```

Alternately, to install these modules using cpan:
```
$ sudo cpan -i Getopt::Declare MIME::Base64 XML::LibXML::Reader String::Escape
```

If you are using CPAN to install XML::LibXML::Reader, you will likely also need
the development packages for libcrypt, zlib, and libxml2.

### 3. Install K.
- This version of the C semantics should be compatible with the latest version
  of Runtime Verification's version of the K Framework (<https://github.com/runtimeverification/k>).
- Ensure `kompile` and `krun` are included in your `$PATH`. For example, if you
  downloaded the K Framework to `~/k` (and add this to your `~/.bashrc` to make
  this permanent):
```
$ export PATH=$PATH:~/k/bin
```

### 4. Install OCaml K backend.
- This is a proprietary component used to compile and execute programs written in K.
  It is Copyright Runtime Verification, Inc. and subject to the Runtime Verification
  Licenses (<https://runtimeverification.com/licensing/>). 
  A completely free executable version of the C semantics is not available at this time.
  From the K source root, you can install it by running:
```
$ mvn dependency:copy -Dartifact=com.runtimeverification.rv_match:ocaml-backend:1.0-SNAPSHOT -DoutputDirectory=k-distribution/target/release/k/lib/java
```

### 5. Install OCaml.
- We use a modified version of the C parser from the CIL project, which is
  written in OCaml.
- We also now default to using OCaml to execute the C semantics.

For execution the unreleased 4.03 is required, and compiling the semantics
uses ocamlfind to locate require OCaml packages.
This is most easily managed with opam - https://opam.ocaml.org/
To install the required dependencies using OPAM, run

```
k-configure-opam-dev
eval `opam config env`
```

To check if OCaml is installed:
```
$ ocamlfind ocamlopt -version
        Objective Caml version 4.03.0+dev10-2015-07-29

# 
```

(Press ctrl-d to exit.)

(For the parser alone versions 3.11, 3.12, and 4.00 all work, probably many
more as well, and no special dependency handling is required.
Installing with your OS package manger or from https://ocaml.org/ will work.
On Ubuntu, `apt-get install ocaml`)

### 6. Download our C semantics.
Use the following command if `git` is installed:
```
$ git clone --depth=1 https://github.com/kframework/c-semantics.git
```
Otherwise, download the latest stable version from github here:
<https://github.com/kframework/c-semantics/releases/tag/latest>

### 7. Build our C tool.
- Run `make -j4` in the project root directory.
- This should take roughly 10 minutes on non-windows machines, and up to
  60 minutes on windows.
- The `make` process creates a `dist/` directory which you can copy elsewhere
  to install the C tool, or simply leave it where it is. Either way, you will
  probably want to add it to your `$PATH`:
```
$ export PATH=$PATH:/path/to/c-semantics/dist
```
      
To check if kcc is behaving correctly:
```
$ dist/kcc tests/unitTests/helloworld.c
$ ./a.out 
Hello world
```

See [README.md](README.md) for a summary of the features supported by the `kcc`
tool.

