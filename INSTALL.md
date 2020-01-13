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

We recommend using Linux or OSX on a computer with at least 4 GB of memory.

On Ubuntu 18.04, the installation process for our C semantics can be summarized as:
```sh
sudo apt-get install --yes \
  maven git openjdk-8-jdk flex libgmp-dev libffi-dev \
  libmpfr-dev build-essential cmake zlib1g-dev \
  diffutils libuuid-tiny-perl \
  libstring-escape-perl libstring-shellquote-perl \
  libgetopt-declare-perl opam pkg-config \
  libapp-fatpacker-perl liblocal-lib-perl \
  clang-6.0 libclang-6.0-dev
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
- The GNU C compiler (GCC), Make, diff, patch, CMake, Maven, and libraries.
```sh
sudo apt-get install build-essential diffutils bison cmake maven pkg-config \
  libgmp-dev libffi-dev libmpfr-dev flex
```
- If using Windows, you'll probably want to install cygwin.

### 2. Install Perl 5 and required modules.
- Perl 5 will likely already be installed on most Linux and Mac OS X machines.
  But if not, use your package manager to install it.
- For Windows, see here: <http://www.perl.org/get.html>
- Install the following Perl modules:
    - App::FatPacker
    - Getopt::Declare
    - String::Escape
    - String::ShellQuote
    - UUID::Tiny
    - local::lib

The easiest way is to install them using apt-get:
```
$ sudo apt-get install libuuid-tiny-perl libxml-libxml-perl libgetopt-declare-perl libstring-escape-perl libstring-shellquote-perl libapp-fatpacker-perl liblocal-lib-perl
```

Alternatively, to install these modules using cpan:
```
$ sudo cpan -i Getopt::Declare String::Escape String::ShellQuote App::FatPacker local::lib
```

### 3. Install OCaml
We use ocaml for the C parser and for K OCaml backend. Install OCaml using
```sh
sudo apt-get install --yes opam
```

### 3. Clone the semantics
```
git clone --depth=1 https://github.com/kframework/c-semantics.git
cd c-semantics
```


### 4. Install K
An appropriate version of K framework is a submodule of the c-semantics repository.
To build it, first update all the submodules:
```
git submodule update --init --recursive
```
then build K:
```
pushd .build/k
mvn package -DskipTests -DskipKTest -Dhaskell.backend.skip -Dllvm.backend.skip
```
and install the dependencies of K's OCaml backend:
```
./k-distribution/src/main/scripts/bin/k-configure-opam-dev
popd
eval `opam config env`
```

### 5. Install Clang
We use Clang to parse C++ programs. Install Clang 6.0 using
```
sudo apt-get install --yes clang-6.0 libclang-6.0-dev
```

### 6. Build our C tool.
- Run `make` (or `make -j4` if you have enough memory) in the project root directory.
- The build takes about 30 minutes.
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

### 8. Subsequent builds
When building in a fresh shell after all dependencies are installed, before the `make` command, run
```
eval $(opam config env)
eval $(perl -I "~/perl5/lib/perl5" -Mlocal::lib)
```


