// Copyright (c) 2014-2015 K Team. All Rights Reserved.
require "kernelc.k"

module MAX-SPEC
  imports C-VERIFIER

rule
  <functions>... FUNCTIONS:Map ...</functions>
  <structs>... STRUCTS:Map ...</structs>
  <external-types> EXTERNALTYPES:Map </external-types>
  <external-defs> EXTERNALDEFS:Map </external-defs>
  <linkings> LINKINGS:Map </linkings>
  <translation-units> TRANSLATIONUNITS:Bag </translation-units>
    <activeBlocks> .Map => ?_:Map </activeBlocks>
  <next-malloced> (_:Int => ?_:Int) @ alloc </next-malloced>
  <status> mainCalled </status>
  <mem>... MEM:Map ...</mem>
  <threads>
    <thread>...
      <thread-id> 0 </thread-id>
        <buffer> .List </buffer>
        <curr-function> _:CId </curr-function>
        <curr-subobject> .List </curr-subobject>
        <locs-written> _:List => .List </locs-written>
      <formatting-wrapper> .Bag </formatting-wrapper>
      <type-wrapper> .Bag </type-wrapper>
      <initializing> Initializing:Int </initializing>
      <duration> auto(0) </duration>
      <k>
        Call(
            tv(loc(0 @ static("max.c"), 0),
               t(.Set, pointerType(t(.Set, functionType(t(.Set, int), ListItem(t(.Set, int)) ListItem(t(.Set, int))))))),
            rvlist(
                ListItem(tv(X:Int, t(.Set, int)))
                ListItem(tv(Y:Int, t(.Set, int)))))
      =>
        tv(maxInt(X, Y), t(.Set, int))
      ...</k>
    ...</thread>
  </threads>
  <files>
    <file-commands> .K </file-commands>
  </files>
  <error-cell-wrapper> .Bag </error-cell-wrapper>
requires Initializing >=Int 0
 andBool min(t(.Set, int)) <=Int X:Int
 andBool X:Int <=Int max(t(.Set, int))
 andBool min(t(.Set, int)) <=Int Y:Int
 andBool Y:Int <=Int max(t(.Set, int))

endmodule

