// Copyright (c) 2014-2015 K Team. All Rights Reserved.
require "kernelc.k"

module DELETE-SPEC
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
    <activeBlocks>
      '_Map_(
           Identifier("delete") |-> activity(ABC01:Int, .Map),,
         Identifier("find_min") |-> activity(ABC02:Int, .Map),,
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
        20 |-> activity(ABC20:Int, .Map),,
        21 |-> activity(ABC21:Int, .Map),,
        22 |-> activity(ABC22:Int, .Map),,
        23 |-> activity(ABC23:Int, .Map),,
        24 |-> activity(ABC24:Int, .Map),,
        25 |-> activity(ABC25:Int, .Map),,
        26 |-> activity(ABC26:Int, .Map),,
        27 |-> activity(ABC27:Int, .Map),,
        28 |-> activity(ABC28:Int, .Map),,
        29 |-> activity(ABC29:Int, .Map),,
        30 |-> activity(ABC30:Int, .Map),,
        31 |-> activity(ABC31:Int, .Map),,
        32 |-> activity(ABC32:Int, .Map),,
        33 |-> activity(ABC33:Int, .Map),,
        34 |-> activity(ABC34:Int, .Map),,
        35 |-> activity(ABC35:Int, .Map),,
        36 |-> activity(ABC36:Int, .Map),,
        37 |-> activity(ABC37:Int, .Map),,
        38 |-> activity(ABC38:Int, .Map),,
        39 |-> activity(ABC39:Int, .Map),,
        40 |-> activity(ABC40:Int, .Map),,
        41 |-> activity(ABC41:Int, .Map),,
        42 |-> activity(ABC42:Int, .Map),,
        43 |-> activity(ABC43:Int, .Map),,
        44 |-> activity(ABC44:Int, .Map),,
        45 |-> activity(ABC45:Int, .Map),,
        46 |-> activity(ABC46:Int, .Map),,
        47 |-> activity(ABC47:Int, .Map),,
        48 |-> activity(ABC48:Int, .Map),,
        49 |-> activity(ABC49:Int, .Map),,
        50 |-> activity(ABC50:Int, .Map))
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
            tv(loc(4 @ static("bst.c"), 0),
               t(.Set, pointerType(t(.Set, functionType(t(.Set, pointerType(t(.Set, structType(global(Identifier("treeNode"), "bst.c"))))), ListItem(t(.Set, int)) ListItem(t(.Set, pointerType(t(.Set, structType(global(Identifier("treeNode"), "bst.c"))))))))))),
            rvlist(
                ListItem(tv(V:Int, t(.Set, int)))
                ListItem(tv(TP1:CanonicalSymLoc, t(.Set, pointerType(t(.Set, structType(global(Identifier("treeNode"), "bst.c")))))))))
      =>
        tv(?TP2:CanonicalSymLoc, t(.Set, pointerType(t(.Set, structType(global(Identifier("treeNode"), "bst.c"))))))
      ...</k>
    ...</thread>
  </threads>
  <files>
    <file-commands> .K </file-commands>
  </files>
  <error-cell-wrapper> .Bag </error-cell-wrapper>
requires bst(T1)
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
 andBool (ABC21 >Int 0
 andBool ABC22 >Int 0
 andBool ABC23 >Int 0
 andBool ABC24 >Int 0
 andBool ABC25 >Int 0
 andBool ABC26 >Int 0
 andBool ABC27 >Int 0
 andBool ABC28 >Int 0
 andBool ABC29 >Int 0
 andBool ABC30 >Int 0)
 andBool (ABC31 >Int 0
 andBool ABC32 >Int 0
 andBool ABC33 >Int 0
 andBool ABC34 >Int 0
 andBool ABC35 >Int 0
 andBool ABC36 >Int 0
 andBool ABC37 >Int 0
 andBool ABC38 >Int 0
 andBool ABC39 >Int 0
 andBool ABC40 >Int 0)
 andBool (ABC41 >Int 0
 andBool ABC42 >Int 0
 andBool ABC43 >Int 0
 andBool ABC44 >Int 0
 andBool ABC45 >Int 0
 andBool ABC46 >Int 0
 andBool ABC47 >Int 0
 andBool ABC48 >Int 0
 andBool ABC49 >Int 0
 andBool ABC50 >Int 0)
ensures bst(?T2) andBool tree_keys(?T2) ==K tree_keys(T1) -IntSet { V }

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
           Identifier("delete") |-> activity(ABC01:Int, .Map),,
         Identifier("find_min") |-> activity(ABC02:Int, .Map),,
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
        20 |-> activity(ABC20:Int, .Map),,
        21 |-> activity(ABC21:Int, .Map),,
        22 |-> activity(ABC22:Int, .Map),,
        23 |-> activity(ABC23:Int, .Map),,
        24 |-> activity(ABC24:Int, .Map),,
        25 |-> activity(ABC25:Int, .Map),,
        26 |-> activity(ABC26:Int, .Map),,
        27 |-> activity(ABC27:Int, .Map),,
        28 |-> activity(ABC28:Int, .Map),,
        29 |-> activity(ABC29:Int, .Map),,
        30 |-> activity(ABC30:Int, .Map),,
        31 |-> activity(ABC31:Int, .Map),,
        32 |-> activity(ABC32:Int, .Map),,
        33 |-> activity(ABC33:Int, .Map),,
        34 |-> activity(ABC34:Int, .Map),,
        35 |-> activity(ABC35:Int, .Map),,
        36 |-> activity(ABC36:Int, .Map),,
        37 |-> activity(ABC37:Int, .Map),,
        38 |-> activity(ABC38:Int, .Map),,
        39 |-> activity(ABC39:Int, .Map),,
        40 |-> activity(ABC40:Int, .Map),,
        41 |-> activity(ABC41:Int, .Map),,
        42 |-> activity(ABC42:Int, .Map),,
        43 |-> activity(ABC43:Int, .Map),,
        44 |-> activity(ABC44:Int, .Map),,
        45 |-> activity(ABC45:Int, .Map),,
        46 |-> activity(ABC46:Int, .Map),,
        47 |-> activity(ABC47:Int, .Map),,
        48 |-> activity(ABC48:Int, .Map),,
        49 |-> activity(ABC49:Int, .Map),,
        50 |-> activity(ABC50:Int, .Map))
    </activeBlocks>
  <malloced> _:Map => ?_:Map </malloced>
  <next-malloced> (_:Int => ?_:Int) @ alloc </next-malloced>
  <status> mainCalled </status>
  <mem>... MEM:Map tree(TP)(T:Tree) ...</mem>
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
            tv(loc(3 @ static("bst.c"), 0),
               t(.Set, pointerType(t(.Set, functionType(t(.Set, int), ListItem(t(.Set, pointerType(t(.Set, structType(global(Identifier("treeNode"), "bst.c"))))))))))),
            rvlist(
                ListItem(tv(TP:CanonicalSymLoc, t(.Set, pointerType(t(.Set, structType(global(Identifier("treeNode"), "bst.c")))))))))
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
 andBool bst(T)
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
 andBool (ABC21 >Int 0
 andBool ABC22 >Int 0
 andBool ABC23 >Int 0
 andBool ABC24 >Int 0
 andBool ABC25 >Int 0
 andBool ABC26 >Int 0
 andBool ABC27 >Int 0
 andBool ABC28 >Int 0
 andBool ABC29 >Int 0
 andBool ABC30 >Int 0)
 andBool (ABC31 >Int 0
 andBool ABC32 >Int 0
 andBool ABC33 >Int 0
 andBool ABC34 >Int 0
 andBool ABC35 >Int 0
 andBool ABC36 >Int 0
 andBool ABC37 >Int 0
 andBool ABC38 >Int 0
 andBool ABC39 >Int 0
 andBool ABC40 >Int 0)
 andBool (ABC41 >Int 0
 andBool ABC42 >Int 0
 andBool ABC43 >Int 0
 andBool ABC44 >Int 0
 andBool ABC45 >Int 0
 andBool ABC46 >Int 0
 andBool ABC47 >Int 0
 andBool ABC48 >Int 0
 andBool ABC49 >Int 0
 andBool ABC50 >Int 0)
ensures (?M:Int inIntSet tree_keys(T))
andBool ({ ?M:Int } <=IntSet tree_keys(T))
andBool min(t(.Set, int)) <=Int ?M:Int
andBool ?M:Int <=Int max(t(.Set, int))


rule
  <functions> FUNCTIONS:Map </functions>
  <structs> STRUCTS:Map </structs>
  <external-types> EXTERNALTYPES:Map </external-types>
  <external-defs> EXTERNALDEFS:Map </external-defs>
  <linkings> LINKINGS:Map </linkings>
  <translation-units> TRANSLATIONUNITS:Bag </translation-units>
  <status> mainCalled </status>
  <mem>... MEM:Map tree(TP)(_:Tree) ...</mem>
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
  [no-pattern-expansion]
endmodule

