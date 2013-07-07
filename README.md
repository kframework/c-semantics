# Installation

See INSTALL.md.

# Usage
      
### Understanding the tool
- 'kcc' is meant to to act a lot like gcc.  You use it and run programs the
  same way.
- The programs kcc generates act like normal programs.  Both the output to
  stdio (e.g., printf), as well as the return value of the program should be
  what you expect.  In terms of operational behavior, a correct program
  compiled with kcc should act the same as one compiled with gcc.
- Take a look at 'kcc -h' for some compile-time options.  For most programs,
  you only need to run "kcc program.c" and everything will work.  Caveats
  below.
- After compiling a program and generating an output file "a.out", running
  "HELP=1 ./a.out" will display some runtime options, including SEARCH and
  PROFILE.
- If you try to run a program that is undefined (or one for which we are
  missing semantics), the program will get stuck.  The message should tell you
  where it got stuck and may give a hint as to why.  If you want help
  deciphering the output, or help understanding why the program is defined,
  please send your .kdump file to the e-mail listed at the top of this file.
      
### Runtime features
- Running "SEARCH=1 ./a.out" will exhaustively search the state space of your
  program and generate a .pdf and .ps of the space (if you installed Graphviz).
  This is the only way to check all possible evaluation orders of a program to
  find undefined behavior. This feature is currently under development.

- Running "PROFILE=1 ./a.out" will record which rules of the semantics are
  exercised during the evaluation of the program.  The program executes as
  normal, but this additional information is recorded in a SQLite database
  "maudeProfileDBfile.sqlite" in your current directory. You can access the
  information by running queries against the database. Some sample queries are
  provided in the dist directory, and can be tried by running, e.g., 
  <pre>
  $ cat dist/profile-executiveSummaryByProgram.sql | perl dist/accessProfiling.pl
  </pre>
  You can look at the provided queries and construct your own, or access the
  database using your own programs.  Different runs of the tool are kept
  distinct in the database, so you can run a bunch of programs and then analyze
  the collective data.  You can simply delete "maudeProfileDBfile.sqlite" file
  to start another series of tests with a fresh database.

### Caveats and miscellanea
- In order to use any file I/O, you need to compile the program with the -i
  option.  The support for file I/O is still incredibly rudimentary and very
  few functions are supported.
- If you are only using one of the standard library functions that we directly
  give semantics to (printf being the most important), you can prevent the tool
  from linking in the standard library with the -s option. This can speed up
  the execution time of your program. If the program needs the standard
  library and you use the -s option, it will simply get stuck and you will see
  it trying to call that missing function at the top of the computation.

### Understanding the semantics
Links to help understand K:
- http://code.google.com/p/k-framework/
- http://k-framework.org/ 
- See particularly:
    - Traian Serbanuta's thesis defense slides
      (http://fsl.cs.uiuc.edu/pubs/serbanuta-2010-thesis-slides.pdf) for a high
      level overview 
    - "An Overview of the K Semantic Framework" from the Journal of Logic and
      Algebraic Programming
      (http://fsl.cs.uiuc.edu/pubs/rosu-serbanuta-2010-jlap.pdf) for a detailed
      explanation.
            
To generate pdf versions of the semantics (INCOMPLETE):
- Run "make pdf".
- Currently this creates only pdfs in the /semantics directory.
- The pdfs are often incorrect, in that they omit necessary parentheses.
  Moreover, the semantics is quite messy as we are still experimenting with the
  best way to represent things and find the most undefined behavior. However,
  these pdfs are sufficient for helping build an understanding of the
  semantics.
      
For licensing information, see LICENSE.
