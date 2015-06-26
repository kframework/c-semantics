require "kernelc.k"

module DELETE-SPEC
imports C-VERIFIER

rule [func-max]:
  <functions> FUNCTIONS:Map </functions> // <functions>... FUNCTIONS:Map ...</functions>
  <structs> STRUCTS:Map </structs>       // <structs>... STRUCTS:Map ...</structs>
  <external-types> EXTERNALTYPES:Map </external-types>
  <external-defs> EXTERNALDEFS:Map </external-defs>
  <linkings> LINKINGS:Map </linkings>
  <translation-units> TRANSLATIONUNITS:Bag </translation-units>
  <activeBlocks> .Map </activeBlocks>
  <malloced> _:Map => ?_:Map </malloced>
  <next-malloced> (_:Int => ?_:Int) @ alloc </next-malloced>
  <status> mainCalled </status>
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
            tv(loc(0 /* max */ @ static("avl.c"), 0),
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
requires min(t(.Set, int)) <=Int X andBool X <=Int max(t(.Set, int)) // c-specific
 andBool min(t(.Set, int)) <=Int Y andBool Y <=Int max(t(.Set, int)) // c-specific
// andBool Initializing >=Int 0 // c-specific

rule [func-height]:
  <functions> FUNCTIONS:Map </functions> // <functions>... FUNCTIONS:Map ...</functions>
  <structs> STRUCTS:Map </structs>       // <structs>... STRUCTS:Map ...</structs>
  <external-types> EXTERNALTYPES:Map </external-types>
  <external-defs> EXTERNALDEFS:Map </external-defs>
  <linkings> LINKINGS:Map </linkings>
  <translation-units> TRANSLATIONUNITS:Bag </translation-units>
  <activeBlocks> .Map </activeBlocks>
  <malloced> _:Map => ?_:Map </malloced>
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
            tv(loc(1 /* height */ @ static("avl.c"), 0),
               t(.Set, pointerType(t(.Set, functionType(t(.Set, int), ListItem(t(.Set, pointerType(t(.Set, structType(global(Identifier("node"), "avl.c"))))))))))),
            rvlist(
                ListItem(tv(TP:CanonicalSymLoc, t(.Set, pointerType(t(.Set, structType(global(Identifier("node"), "avl.c")))))))))
      =>
        tv(tree_height(T), t(.Set, int))
      ...</k>
    ...</thread>
  </threads>
  <files>
    <file-commands> .K </file-commands>
  </files>
  <error-cell-wrapper> .Bag </error-cell-wrapper>
requires avl(T)
 andBool tree_height(T) <=Int max(t(.Set, int)) // c-specific
// andBool Initializing >=Int 0 // c-specific

rule [func-update-height]:
  <functions> FUNCTIONS:Map </functions> // <functions>... FUNCTIONS:Map ...</functions>
  <structs> STRUCTS:Map </structs>       // <structs>... STRUCTS:Map ...</structs>
  <external-types> EXTERNALTYPES:Map </external-types>
  <external-defs> EXTERNALDEFS:Map </external-defs>
  <linkings> LINKINGS:Map </linkings>
  <translation-units> TRANSLATIONUNITS:Bag </translation-units>
  <activeBlocks> .Map </activeBlocks>
  <malloced> _:Map => ?_:Map </malloced>
  <next-malloced> (_:Int => ?_:Int) @ alloc </next-malloced>
  <status> mainCalled </status>
  <mem>...
    MEM:Map
    TP:Int @ alloc |-> object(t(.Set, no-type), 16,
       0 |-> piece(I0:Int, 8) // value
       1 |-> piece(I1:Int, 8) 
       2 |-> piece(I2:Int, 8) 
       3 |-> piece(I3:Int, 8) 
       4 |-> piece(_:Int => ?H0:Int, 8) // height
       5 |-> piece(_:Int => ?H1:Int, 8) 
       6 |-> piece(_:Int => ?H2:Int, 8) 
       7 |-> piece(_:Int => ?H3:Int, 8)
       8 |-> piece(subObject(LP, 0, 0), 8)
       9 |-> piece(subObject(LP, 1, 1), 8)
      10 |-> piece(subObject(LP, 2, 2), 8)
      11 |-> piece(subObject(LP, 3, 3), 8)
      12 |-> piece(subObject(RP, 0, 0), 8)
      13 |-> piece(subObject(RP, 1, 1), 8)
      14 |-> piece(subObject(RP, 2, 2), 8)
      15 |-> piece(subObject(RP, 3, 3), 8),
       0 |-> t(.Set, int) // value
       4 |-> t(.Set, int) // height
       8 |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("node"), "avl.c")))))
      12 |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("node"), "avl.c"))))))
    htree(LP:CanonicalSymLoc)(LT:Tree)
    htree(RP:CanonicalSymLoc)(RT:Tree)
  ...</mem>
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
            tv(loc(2 /* update_height */ @ static("avl.c"), 0),
               t(.Set, pointerType(t(.Set, functionType(t(.Set, void), ListItem(t(.Set, pointerType(t(.Set, structType(global(Identifier("node"), "avl.c"))))))))))),
            rvlist(
                ListItem(tv(loc(TP:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 16))), t(.Set, pointerType(t(.Set, structType(global(Identifier("node"), "avl.c")))))))))
      =>
        voidVal
      ...</k>
    ...</thread>
  </threads>
  <files>
    <file-commands> .K </file-commands>
  </files>
  <error-cell-wrapper> .Bag </error-cell-wrapper>
requires avl(LT) andBool avl(RT)
 andBool tree_height(LT) <=Int max(t(.Set, int)) -Int 1 // c-specific
 andBool tree_height(RT) <=Int max(t(.Set, int)) -Int 1 // c-specific
// andBool Initializing >=Int 0 // c-specific
 //
 /*
 andBool I:Int ==K (((((I3:Int <<Int 8) |Int I2:Int) <<Int 8) |Int I1:Int) <<Int 8) |Int I0:Int
 andBool min(t(.Set, int)) <=Int I andBool I <=Int max(t(.Set, int))
 */
ensures  tree_height(node(_:Int, LT, RT)) ==K (((((?H3:Int <<Int 8) |Int ?H2:Int) <<Int 8) |Int ?H1:Int) <<Int 8) |Int ?H0:Int
 andBool min(t(.Set, int)) <=Int tree_height(node(_:Int, LT, RT)) andBool tree_height(node(_:Int, LT, RT)) <=Int max(t(.Set, int)) // c-specific

rule [func-find-min]:
  <functions> FUNCTIONS:Map </functions> // <functions>... FUNCTIONS:Map ...</functions>
  <structs> STRUCTS:Map </structs>       // <structs>... STRUCTS:Map ...</structs>
  <external-types> EXTERNALTYPES:Map </external-types>
  <external-defs> EXTERNALDEFS:Map </external-defs>
  <linkings> LINKINGS:Map </linkings>
  <translation-units> TRANSLATIONUNITS:Bag </translation-units>
  <activeBlocks> .Map </activeBlocks>
  <malloced> _:Map => ?_:Map </malloced>
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
            tv(loc(3 /* find_min */ @ static("avl.c"), 0),
               t(.Set, pointerType(t(.Set, functionType(t(.Set, int), ListItem(t(.Set, pointerType(t(.Set, structType(global(Identifier("node"), "avl.c"))))))))))),
            rvlist(
                ListItem(tv(TP:CanonicalSymLoc, t(.Set, pointerType(t(.Set, structType(global(Identifier("node"), "avl.c")))))))))
      =>
        tv(?M:Int, t(.Set, int))
      ...</k>
    ...</thread>
  </threads>
  <files>
    <file-commands> .K </file-commands>
  </files>
  <error-cell-wrapper> .Bag </error-cell-wrapper>
requires TP =/=K NullPointer 
 andBool avl(T)
 andBool tree_height(T) <=Int max(t(.Set, int)) // c-specific
// andBool Initializing >=Int 0 // c-specific
ensures  (?M inIntSet tree_keys(T))
 andBool ({ ?M } <=IntSet tree_keys(T))
 andBool min(t(.Set, int)) <=Int ?M andBool ?M <=Int max(t(.Set, int)) // c-specific

rule [func-delete]:
  <functions> FUNCTIONS:Map </functions> // <functions>... FUNCTIONS:Map ...</functions>
  <structs> STRUCTS:Map </structs>       // <structs>... STRUCTS:Map ...</structs>
  <external-types> EXTERNALTYPES:Map </external-types>
  <external-defs> EXTERNALDEFS:Map </external-defs>
  <linkings> LINKINGS:Map </linkings>
  <translation-units> TRANSLATIONUNITS:Bag </translation-units>
  <activeBlocks> .Map </activeBlocks>
  <malloced> _:Map => ?_:Map </malloced>
  <next-malloced> (_:Int => ?_:Int) @ alloc </next-malloced>
  <status> mainCalled </status>
  <mem>...
    MEM:Map
  (
    htree( TP1:CanonicalSymLoc)( T1:Tree)
  =>
    htree(?TP2:CanonicalSymLoc)(?T2:Tree)
  )
  ...</mem>
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
            tv(loc(10 /* delete */ @ static("avl.c"), 0),
                t(.Set, pointerType(t(.Set, functionType(t(.Set, pointerType(t(.Set, structType(global(Identifier("node"), "avl.c"))))), ListItem(t(.Set, int)) ListItem(t(.Set, pointerType(t(.Set, structType(global(Identifier("node"), "avl.c"))))))))))),
            rvlist(
                ListItem(tv(V:Int, t(.Set, int)))
                ListItem(tv(TP1:CanonicalSymLoc, t(.Set, pointerType(t(.Set, structType(global(Identifier("node"), "avl.c")))))))))
      =>
        tv(?TP2:CanonicalSymLoc, t(.Set, pointerType(t(.Set, structType(global(Identifier("node"), "avl.c"))))))
      ...</k>
    ...</thread>
  </threads>
  <files>
    <file-commands> .K </file-commands>
  </files>
  <error-cell-wrapper> .Bag </error-cell-wrapper>
requires avl(T1)
 andBool tree_height(T1) <=Int max(t(.Set, int)) -Int 1 // c-specific
 andBool min(t(.Set, int)) <=Int V:Int andBool V:Int <=Int max(t(.Set, int)) // c-specific
// andBool Initializing >=Int 0 // c-specific
ensures  avl(?T2)
 andBool tree_keys(?T2) ==K tree_keys(T1) -IntSet { V }
 andBool tree_height(T1) -Int 1 <=Int tree_height(?T2) andBool tree_height(?T2) <=Int tree_height(T1)

endmodule
