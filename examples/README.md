## Search

The C standard allows compilers freedom in optimizing code, which includes
allowing them to choose their own expression evaluation order. This includes
allowing them to:

- delay side effects: e.g., allowing the write to memory required by `x=5` or
  `x++` to be made separately from its evaluation or use;
- interleave evaluation: e.g., A + (B * C) can be evaluated in the order B, A,
  C.

At the same time, the programmer must be able to write programs whose behaviors
are reproducible, and only allow non-determinism in a controlled way.
Therefore, the standard makes undefined certain situations where reordering
creates a "race condition". The latest treatment of this restriction is given
by the C11 standard:

> If a side effect on a scalar object is unsequenced relative to either a
> different side effect on the same scalar object or a value computation using
> the value of the same scalar object, the behavior is undefined. If there are
> multiple allowable orderings [...], the behavior is undefined if such an
> unsequenced side effect occurs in any of the orderings [C11, §6.5:2].

This means that if there are two writes, or a write and a read to the same
object that are unsequenced (i.e., either is allowed to happen before the
other), then the expression is undefined. Examples of expressions made
undefined by this clause include `(x=0)+(x=1)` and `(x=0)+x` and `x=x++` and
`*p=x++`, for `int x` and `int* p=&x`. This relation is related to the concept
of "sequence points," also defined by the standard. Sequence points cause the
expressions they fall between to be sequenced. The most common example of a
sequence point is the semicolon, i.e., the end of an expression-statement. All
previous evaluations and side effects must be complete before crossing sequence
points.

A hasty read of the standard may wrongly indicate that detecting this kind of
undefined behavior is an easy problem that can be checked statically. In fact,
it is undecidable statically; moreover, one needs to use the entire semantics
in order to check it dynamically. However, one can use `kcc` to help identify
these problems as well as to explore correct non-deterministic evaluations.

### Undefinedness examples

Let's start with a simple example that can be caught just with interpretation.
Consider the program at [search/undefAdd.c][]:
```c
int main(void){
      int x = 0;
      return (x = 1) + x;
}
```
The `(x = 1) + x` expression is undefined because the read of `x` (the lone
`x`) is unsequenced with respect to the write of `x` (the assignment). Running
this program:
```
$ kcc -s undefAdd.c
$ ./a.out
=============================================================
ERROR! KCC encountered an error while executing this program.
=============================================================
Error: 00003
Description: Unsequenced side effect on scalar object with value computation of same object.
=============================================================
File: search/undefAdd.c
Function: main
Line: 3
=============================================================
Final Computation:
...
```
detects the error. However, we were lucky because the interpreter doesn't
always detect these kinds of errors. Consider the program at
[search/undefComma.c][]:
```c
int main(void){
      int x = 0;
      return x + (x, x = 3);
}
```
This program is also undefined. Here, the read of `x` in the right argument of
the `+` is unsequenced with the write to `x` in `x=3`. Let's try interpreting:
```
$ kcc -s undefComma.c
$ ./a.out
$ echo $?
3
```

Running this program through the interpreter fails to find the error! However,
by instructing `kcc` to search the state space, we can identify this program as
being undefined:
```
$ SEARCH=1 ./a.out 
Searching reachable states... (with non-deterministic expression sequencing)
Examining the output...
========================================================================
2 solutions found
------------------------------------------------------------------------
Solution 1
Program got stuck
File: search/undefComma.c
Line: 3
Error: 00003
Description: Unsequenced side effect on scalar object with value computation of same object.
Output:

------------------------------------------------------------------------
Solution 2
Program completed successfully
Exit code: 3
Output:

========================================================================
2 solutions found
```

If any of the results returned by search indicate undefined behavior, then the
program is undefined. During interpretation, we don't always notice undefined
behavior, but if it exists, it will always be identified using search.

## LTL model checking

NOTE: LTL model checking seems to be broken in recent versions of K.

We currently support LTL model checking over possible expression sequencings.

### Syntax

The syntax of LTL formulas is given by the following grammar:
```
LTL ::= "~Ltl" LTL
      | "OLtl" LTL
      | "<>Ltl" LTL
      | "[]Ltl" LTL
      | LTL "/\Ltl" LTL
      | LTL "\/Ltl" LTL
      | LTL "ULtl" LTL
      | LTL "RLtl" LTL
      | LTL "WLtl" LTL
      | LTL "|->Ltl" LTL
      | LTL "->Ltl" LTL 
      | LTL "<->Ltl" LTL
      | LTL "=>Ltl" LTL 
      | LTL "<=>Ltl" LTL
```
Additionally, we support a subset of the C expression syntax and we resolve
symbols in the global scope of the program being checked. We support two other
special atomic propositions: `__running` and `__error`. The first holds only
after `main` has been called and becomes false when `main` returns. The second
holds when the semantics enters some error state, such as it does upon
encountering undefined behavior.

### Examples

For example, consider the C program at [ltlmc/bad.c][]:
```c
int x, y;
int main(void) {
      y = x + (x=1);
      return 0;
}
```

This program contains undefined behavior because `x` is both read and written
to between sequence points. But, unlike the `undefAdd.c` program (see above),
our `kcc` tool will not catch this undefinedness during interpretation.
To catch it, we could use `SEARCH`, just like in the above example, but we
could also use model checking:
```
$ kcc -s bad.c -o bad
$ LTLMC="[]Ltl ~Ltl __error" ./bad
```

We might also wish to check the value of `y`:
```
$ LTLMC="<>Ltl y == 2" ./bad
```
Both of these checks should fail, producing a counter-example (which will be
huge -- consider using the `-s` flag with `kcc` to prevent linking with the
standard library and cut down the size a bit).

Compare these results with model checking the same LTL propositions on the C
program at [ltlmc/good.c][]:
```c
int x, y;
int main(void) {
      y = 1 + (x=1);
      return 0;
}
```
For this program, no counter-example will be found for either proposition and
the only result should be `true`.

### Traffic lights

For a more complicated example, consider the traffic light simulator at
[ltlmc/lights.c][]:
```c
typedef enum {green, yellow, red} state;

state lightNS = green;
state lightEW = red;

int changeNS(){
      switch (lightNS) {
            case(green):
                  lightNS = yellow;
                  return 0;
            case(yellow):
                  lightNS = red;
                  return 0;
            case(red):
                  if (lightEW == red) {
                        lightNS = green;
                  }
                  return 0;
      }
}
int changeEW(){
      switch (lightEW) {
            case(green):
                  lightEW = yellow;
                  return 0;
            case(yellow):
                  lightEW = red;
                  return 0;
            case(red):
                  if (lightNS == red) {
                        lightEW = green;
                  }
                  return 0;
      }
}

int main(void){
      while(1) {
            changeNS() + changeEW();
      }
}
```

Using LTL model checking, we can verify that our algorithm is "safe" in the
sense that at least one light is red at all times:
```
$ kcc -s lights.c
$ LTLMC="[]Ltl __running ->Ltl (lightsNS == red \/Ltl lightsEW == red)" ./a.out
LTL model checking... (with non-deterministic expression sequencing)
true
```

But we can also discover that we are not guaranteed that a light will eventually
turn green. The following should produce a counter-example:
```
$ LTLMC="[]Ltl <>Ltl lightNS == green" ./a.out
```
We can fix this by replacing the line `changeNS() + changeEW();` with
`changeNS(); changeEW();`. Both propositions should then hold.

[search/undefAdd.c]: search/undefAdd.c
[search/undefComma.c]: search/undefComma.c
[ltlmc/bad.c]: ltlmc/bad.c
[ltlmc/good.c]: ltlmc/good.c
[ltlmc/lights.c]: ltlmc/lights.c
