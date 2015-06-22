// Copyright (c) 2014-2015 K Team. All Rights Reserved.
require "kernelc.k"

module INSERT-SPEC
  imports C-VERIFIER

rule
  //<functions>... FUNCTIONS:Map ...</functions>
  <functions> FUNCTIONS:Map </functions>
  //<structs>... STRUCTS:Map ...</structs>
  <structs> STRUCTS:Map </structs>
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
      //<initializing> Initializing:Int </initializing>
      <initializing> 0 </initializing>
      <duration> auto(0) </duration>
      <k> 
        Call1(
            tv(loc(0 @ static("avl.c"), 0),
               t(.Set, pointerType(t(.Set, functionType(t(.Set, int), ListItem(t(.Set, int)) ListItem(t(.Set, int))))))),
            rvlist(
                ListItem(tv(X:Int, t(.Set, int)))
                ListItem(tv(Y:Int, t(.Set, int)))))
      =>
        tv(maxInt(X, Y), t(.:Set, int))
      ...</k>
    ...</thread>
  </threads>
  <files>
    <file-commands> .K </file-commands>
  </files>
  <error-cell-wrapper> .Bag </error-cell-wrapper>
requires min(t(.Set, int)) <=Int X
 andBool X <=Int max(t(.Set, int))
 andBool min(t(.Set, int)) <=Int Y
 andBool Y <=Int max(t(.Set, int))
 //andBool Initializing >Int 0
  [trusted]


rule
  //<functions>... FUNCTIONS:Map ...</functions>
  <functions> FUNCTIONS:Map </functions>
  //<structs>... STRUCTS:Map ...</structs>
  <structs> STRUCTS:Map </structs>
  <external-types> EXTERNALTYPES:Map </external-types>
  <external-defs> EXTERNALDEFS:Map </external-defs>
  <linkings> LINKINGS:Map </linkings>
  <translation-units> TRANSLATIONUNITS:Bag </translation-units>
    <activeBlocks> .Map </activeBlocks>
  <malloced> _:Map => ?_:Map </malloced>
  <next-malloced> (_:Int => ?_:Int) @ alloc </next-malloced>
  <status> mainCalled </status>
  //<mem>... MEM:Map (tree(TP1)(T1:Tree) => tree(?TP2)(?T2:Tree)) ...</mem>
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
      //<initializing> Initializing:Int </initializing>
      <initializing> 0 </initializing>
      <duration> auto(0) </duration>
      <k> 
        Call1(
            tv(loc(1 @ static("avl.c"), 0),
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
 ensures min(t(.Set, int)) <=Int tree_height(T)
 andBool tree_height(T) <=Int max(t(.Set, int))

/*
rule
  //<functions>... FUNCTIONS:Map ...</functions>
  <functions> FUNCTIONS:Map </functions>
  //<structs>... STRUCTS:Map ...</structs>
  <structs> STRUCTS:Map </structs>
  <external-types> EXTERNALTYPES:Map </external-types>
  <external-defs> EXTERNALDEFS:Map </external-defs>
  <linkings> LINKINGS:Map </linkings>
  <translation-units> TRANSLATIONUNITS:Bag </translation-units>
    <activeBlocks>
      '_Map_(
                Identifier("insert") |-> activity(ABC01:Int, .Map),,
                   Identifier("max") |-> activity(ABC02:Int, .Map),,
                Identifier("height") |-> activity(ABC03:Int, .Map),,
         Identifier("update_height") |-> activity(ABC04:Int, .Map),,
           Identifier("left_rotate") |-> activity(ABC05:Int, .Map),,
          Identifier("right_rotate") |-> activity(ABC06:Int, .Map),,
               Identifier("balance") |-> activity(ABC07:Int, .Map),,
              Identifier("new_node") |-> activity(ABC08:Int, .Map),,
         1 |-> activity( ABC1:Int, .Map),,
         2 |-> activity( ABC2:Int, .Map),,
         3 |-> activity( ABC3:Int, .Map),,
         4 |-> activity( ABC4:Int, .Map),,
         5 |-> activity( ABC5:Int, .Map),,
         6 |-> activity( ABC6:Int, .Map),,
         7 |-> activity( ABC7:Int, .Map),,
         8 |-> activity( ABC8:Int, .Map),,
         9 |-> activity( ABC9:Int, .Map),,
        10 |-> activity(ABC10:Int, .Map),,
        11 |-> activity(ABC11:Int, .Map),,
        12 |-> activity(ABC12:Int, .Map),,
        13 |-> activity(ABC13:Int, .Map),,
        14 |-> activity(ABC14:Int, .Map),,
        15 |-> activity(ABC15:Int, .Map),,
        16 |-> activity(ABC16:Int, .Map),,
        17 |-> activity(ABC17:Int, .Map),,
        18 |-> activity(ABC18:Int, .Map),,
        19 |-> activity(ABC19:Int, .Map),,
        20 |-> activity(ABC20:Int, .Map))
    </activeBlocks>
  <malloced> _:Map => ?_:Map </malloced>
  <next-malloced> (_:Int => ?_:Int) @ alloc </next-malloced>
  <status> mainCalled </status>
  <mem>... MEM:Map (tree(TP1)(T1:Tree) => tree(?TP2)(?T2:Tree)) ...</mem>
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
      //<initializing> Initializing:Int </initializing>
      <initializing> 0 </initializing>
      <duration> auto(0) </duration>
      <k> 
        Call1(
            tv(loc(2 @ static("avl.c"), 0),
               t(.Set, pointerType(t(.Set, functionType(t(.Set, pointerType(t(.Set, structType(global(Identifier("treeNode"), "avl.c"))))), ListItem(t(.Set, int)) ListItem(t(.Set, pointerType(t(.Set, structType(global(Identifier("treeNode"), "avl.c"))))))))))),
            rvlist(
                ListItem(tv(V:Int, t(.Set, int)))
                ListItem(tv(TP1:CanonicalSymLoc, t(.Set, pointerType(t(.Set, structType(global(Identifier("treeNode"), "avl.c")))))))))
      =>
        tv(?TP2:CanonicalSymLoc, t(.Set, pointerType(t(.Set, structType(global(Identifier("treeNode"), "avl.c"))))))
      ...</k>
    ...</thread>
  </threads>
  <files>
    <file-commands> .K </file-commands>
  </files>
  <error-cell-wrapper> .Bag </error-cell-wrapper>
requires avl(T1)
 andBool min(t(.Set, int)) <=Int V:Int
 andBool V:Int <=Int max(t(.Set, int))
 //andBool Initializing >Int 0
 andBool ABC01 >Int 0
 andBool ABC02 >Int 0
 andBool  (ABC1 >Int 0
 andBool  ABC2 >Int 0
 andBool  ABC3 >Int 0
 andBool  ABC4 >Int 0
 andBool  ABC5 >Int 0
 andBool  ABC6 >Int 0
 andBool  ABC7 >Int 0
 andBool  ABC8 >Int 0
 andBool  ABC9 >Int 0
 andBool ABC10 >Int 0)
 andBool (ABC11 >Int 0
 andBool ABC12 >Int 0
 andBool ABC13 >Int 0
 andBool ABC14 >Int 0
 andBool ABC15 >Int 0
 andBool ABC16 >Int 0
 andBool ABC17 >Int 0
 andBool ABC18 >Int 0
 andBool ABC19 >Int 0
 andBool ABC20 >Int 0)
ensures avl(?T2) andBool tree_keys(?T2) ==K { V } U tree_keys(T1)

rule
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
*/
endmodule

