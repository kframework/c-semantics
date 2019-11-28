# Installation

**NOTE**: A more powerful version of the C semantics capable of recovering from 
errors and detecting a broader range of undefined and undesirable behaviors 
can be found at https://runtimeverification.com/match.

---

Please let us know if these instructions are insufficient or if you needed to
do any installation steps not listed explicitly.

## Quickly, using Docker

For convenience, we provide a docker image containing all build
dependencies:

- Install docker (see <https://docs.docker.com/get-started/>)
- Clone this repository:
  ```sh
  git clone https://github.com/kframework/c-semantics.git
  cd c-semantics
  git submodule update --init --recursive
  ```
- From within the cloned repository, run
  ```sh
  docker run -it --rm \
    -v $(pwd -P):/home/user/mounted \
    -w /home/user/mounted \
    runtimeverificationinc/c-semantics:latest
  ```
- You are now inside a docker container with the project
  directory mounted at `/home/user/mounted`. To build
  the semantics, issue the following commands inside
  that same directory:
  ```sh
  eval $(opam config env)
  eval $(perl -I "~/perl5/lib/perl5" -Mlocal::lib)
  make -j4 --output-sync=line
  ```
- The build artifacts will be placed inside the `dist` directory.


## From scratch

We recommend using Linux or OSX on a computer with at least 1 GB of memory.

On Ubuntu 18.04, the installation process for our C semantics can be summarized as:
```sh
sudo apt-get install --yes \
  maven git openjdk-8-jdk flex libgmp-dev \
  libmpfr-dev build-essential cmake zlib1g-dev \
  libclang-3.9-dev llvm-3.9 diffutils libuuid-tiny-perl \
  libstring-escape-perl libstring-shellquote-perl \
  libgetopt-declare-perl opam pkg-config \
  libapp-fatpacker-perl
git clone https://github.com/kframework/c-semantics.git
cd c-semantics
git submodule update --init --recursive
eval $(opam config env)
eval $(perl -I "~/perl5/lib/perl5" -Mlocal::lib)
make -j4 --output-sync=line
```
The build artifacts will be placed inside the `dist` directory.


## Detailed instructions

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
    - App::FatPacker
    - Getopt::Declare
    - String::Escape
    - String::ShellQuote
    - UUID::Tiny

You can also install them using apt-get with
```
$ sudo apt-get install libuuid-tiny-perl libxml-libxml-perl libgetopt-declare-perl libstring-escape-perl libstring-shellquote-perl libapp-fatpacker-perl
```

Alternately, to install these modules using cpan:
```
$ sudo cpan -i Getopt::Declare String::Escape String::ShellQuote App::FatPacker
```
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

