# Installation

Please let us know if these instructions are insufficient or if you needed to
do any installation steps not listed explicitly.

### 1. Install basic dependencies.
- Our `kcc` tool uses the GNU C preprocessor (cpp), so you'll at least
  need that. 
- If using Windows, you'll probably need cygwin.

### 2. Install Perl
- You almost definitely will have this installed if you use Linux or Mac OS X;
  otherwise, use your package manager to install it.
- Windows perl can be found here: http://www.activestate.com/activeperl
- Perl is used for many of the scripts in both the C tool and in K.
- Install the following perl modules (probably using either ppm in windows, or
  cpan elsewhere).
    - XML::LibXML::Reader
    - Text::Diff
    - DBI
    - DBD::SQLite
    - Getopt::Declare

E.g., to install a package using cpan:
<pre>
$ cpan -i XML::LibXML::Reader
</pre>

(It might help to do this as sudo if it doesn't work as a normal user.)

### 3. Install OCaml (http://caml.inria.fr/)
- OCaml is used by the C parser.
- Versions 3.11, 3.12, and 4.00 all work; probably many others work as well.

To check if OCaml is installed:
<pre>
$ ocaml
        Objective Caml version 4.00.0

# 
</pre>

(Press ctrl-d to exit.)

### 4. Install K
- Go to http://code.google.com/p/k-framework/source/checkout and check out the
  K Semantic Framework.
- See the README included with K for build and installation instructions.
- Set C_K_BASE to the full (non-relative) path in which you installed the K
  framework.
    - E.g., run "export C_K_BASE=~/k-framework/dist".
    - We suggest you make this change "stick" by adding it to your login
      script.  E.g., if you use the bash shell on linux, you can make this
      change stay by adding the line "export C_K_BASE=~/k-framework/trunk" to
      your ~/.bashrc file.

### 5. Install optional packages
- You may want to install Graphviz (dot), for generating images of the state
  space when searching programs.
- You can probably do this with your package manager.
      
To check if dot is installed:
<pre>
$ which dot
/usr/bin/dot
</pre>

### 6. Build our C tool
- Run "make" in our main directory, the directory of this README.
- This should take between 1 and 5 minutes on non-windows machines, and up to
  10 minutes on windows.
- The "make" process creates a "dist" directory which you can copy elsewhere to
  install the C tool, or simply leave it where it is. Either way, you will
  probably want to add it to your path like you did for Maude above:
  PATH=/path/to/c-semantics/dist:$PATH
      
To check if kcc is behaving correctly:
<pre>
$ dist/kcc tests/unitTests/helloworld.c
$ ./a.out 
Hello world
</pre>

If you chose to add dist to your path, then you can simply type "kcc" instead
of "dist/kcc".

