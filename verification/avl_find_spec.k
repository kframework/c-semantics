require "kernelc.k"

module FIND-SPEC
imports C-VERIFIER

rule [func-find]:
  <functions> FUNCTIONS:Map </functions> // <functions>... FUNCTIONS:Map ...</functions>
  <structs> STRUCTS:Map </structs>       // <structs>... STRUCTS:Map ...</structs>
  <external-types> EXTERNALTYPES:Map </external-types>
  <external-defs> EXTERNALDEFS:Map </external-defs>
  <linkings> LINKINGS:Map </linkings>
  <translation-units> TRANSLATIONUNITS:Bag </translation-units>
  <activeBlocks> .Map </activeBlocks>
  <next-malloced> (_:Int => ?_:Int) @ alloc </next-malloced>
  <status> mainCalled </status>
  <mem>... MEM:Map htree(TP)(T:Tree) ...</mem>
  <restrict> .Map </restrict>
  <threads>
    <thread>...
      <thread-id> 0 </thread-id>
        <buffer> .List </buffer>
        <curr-function> _:CId </curr-function>
        <curr-subobject> .List </curr-subobject>
        <locs-written> _:List => .List </locs-written>
      <formatting-wrapper> .Bag </formatting-wrapper>
      <type-wrapper> .Bag </type-wrapper>
      <initializing> 0 /* Initializing:Int */ </initializing>
      <duration> auto(0) </duration>
      <k> 
        Call1(
            tv(loc(8 /* find */ @ static("avl.c"), 0),
               t(.Set, pointerType(t(.Set, functionType(t(.Set, int), ListItem(t(.Set, int)) ListItem(t(.Set, pointerType(t(.Set, structType(global(Identifier("node"), "avl.c"))))))))))),
            rvlist(
                ListItem(tv(V:Int, t(.Set, int)))
                ListItem(tv(TP:CanonicalSymLoc, t(.Set, pointerType(t(.Set, structType(global(Identifier("node"), "avl.c")))))))))
      =>
        tv(?B:Int, t(.Set, int))
      ...</k>
    ...</thread>
  </threads>
  <files>
    <file-commands> .K </file-commands>
  </files>
  <error-cell-wrapper> .Bag </error-cell-wrapper>
requires avl(T)
 andBool min(t(.Set, int)) <=Int V:Int andBool V:Int <=Int max(t(.Set, int)) // c-specific
// andBool Initializing >=Int 0 // c-specific
ensures  (?B =/=K 0) ==K (V inIntSet tree_keys(T))

rule [aux-checkLoc]:
  <functions> FUNCTIONS:Map </functions>
  <structs> STRUCTS:Map </structs>
  <external-types> EXTERNALTYPES:Map </external-types>
  <external-defs> EXTERNALDEFS:Map </external-defs>
  <linkings> LINKINGS:Map </linkings>
  <translation-units> TRANSLATIONUNITS:Bag </translation-units>
  <status> mainCalled </status>
  <mem>... MEM:Map htree(TP)(_:Tree) ...</mem>
  <threads>
    <thread>...
      <thread-id> 0 </thread-id>
        <buffer> .List </buffer>
        <curr-function> _:CId </curr-function>
        <curr-subobject> .List </curr-subobject>
      <formatting-wrapper> .Bag </formatting-wrapper>
      <type-wrapper> .Bag </type-wrapper>
      <duration> auto(0) </duration>
      <k> checkLoc(TP:CanonicalSymLoc) => .K ...</k>
    ...</thread>
  </threads>
  <files>
    <file-commands> .K </file-commands>
  </files>
  <error-cell-wrapper> .Bag </error-cell-wrapper>

endmodule
