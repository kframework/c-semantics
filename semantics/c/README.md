## Understanding K

See:
- <http://code.google.com/p/k-framework/>
- <http://k-framework.org/>

## Understanding the C semantics

See:
- Chucky Ellison, *A Formal Semantics of C with Applications*, PhD Thesis,
  <http://fsl.cs.uiuc.edu/pubs/ellison-2012-thesis.pdf>
- Chucky Ellison and Grigore Rosu, *An Executable Formal Semantics of C with
  Applications*, POPL'12,
  <http://fsl.cs.uiuc.edu/pubs/ellison-rosu-2012-popl.pdf>

## Structure of the C semantics

This is a formal semantics of C as described in the ISO/IEC 9899:2011 standard
("C11"). Some highlights:

- [language/translation][]: semantics specific to the translation phase.

- [language/execution][]: semantics specific to the execution phase.

- [language/common][]: semantics shared between the translation and execution
  phases.

- [library][]: the definition of various functions from the C standard library
  described in the standard.

- [c11.k][]: the main syntax/semantics language modules for the execution phase.

- [c11-translation.k][]: the main syntax/semantics language modules for the
  translation phase.

- [language/common/syntax.k][]: the main C language syntax module. 

### Style notes

Various stylistic conventions:

1. 80 character lines.

2. `vim: expandtab, tabstop=5, shiftwidth=5`

   Because "rule` `" and "when` `" are both 5 characters, indents of 5 spaces make
   things line up very prettily.

3. I avoid plurals in module names, unless there might be confusion otherwise.
   E.g., `C-EXPRESSION-FUNCTION-CALL` instead of
   `C-EXPRESSIONS-FUNCTION-CALLS`.

4. I think of syntax modules somewhat like C header files. `MYMODULE-SYNTAX`
   should contain the interface of a module (i.e., only "public" syntax
   productions -- cf. symbols with external linkage in C). Generally, when
   module `A` uses syntax productions that are defined by module `B`, module
   `A` should import `B-SYNTAX`. If some part of `B`'s syntax isn't meant to be
   used in other modules, then it shouldn't be included in `B-SYNTAX`.

   Generally, semantic modules should only ever import `-SYNTAX` modules,
   except for the main language semantics module, which should only import
   non-`SYNTAX` modules. And most `-SYNTAX` modules should not import any
   other module, but if they do, then it should better be another `-SYNTAX`
   module.

5. I try to avoid giant modules, especially giant `SYNTAX` modules. These seem
   analogous to putting everything in a global namespace and can make figuring
   out other modules' true dependencies difficult.

6. `context` rules should probably go in semantic modules and not syntactic
   modules because they often have awkward dependencies (e.g., `reval` and
   `peval` in the C semantics).

7. My module names generally correspond somehow to file names, but with dashes
   for slashes. E.g., the module called `C-EXPRESSION-FUNCTION-CALL` is at
   [language/expression/function-call.k][]. 

8. The word "semantics" in module names and elsewhere seems redundant.

9. I like to "declare" variables in rules at the point where they're bound
   (i.e., on the left side of the `=>`).

10. I prefer single quotes (e.g., `func'`, `func''`, etc.) for "auxiliary"
    syntax productions.

11. I prefix "#" to predicates that aren't total functions. 

[language/translation]: language/translation
[language/execution]: language/execution
[language/common]: language/common
[library]: library
[c11.k]: c11.k
[c11-translation.k]: c11-translation.k
[language/common/syntax.k]: language/common/syntax.k
[language/execution/expr/function-call.k]: language/execution/expr/function-call.k
