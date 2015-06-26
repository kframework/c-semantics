// Copyright (c) 2014 K Team. All Rights Reserved.

module TREE-PATTERN
  imports C-COMMON
  imports INT-SET

  syntax Tree ::= "node" "(" Int "," Tree "," Tree ")"
                | "leaf"

  syntax IntSet ::= "tree_keys" "(" Tree ")"    [function, smtlib(smt_tree_keys)]
  rule tree_keys(node(I:Int, TL:Tree, TR:Tree))
    => { I } U (tree_keys(TL) U tree_keys(TR))
  rule tree_keys(leaf) => .IntSet

  syntax Int ::= "tree_height" "(" Tree ")"     [function, smtlib(smt_tree_height)]
  rule tree_height(node(_, TL:Tree, TR:Tree))
    => 1 +Int maxInt(tree_height(TL), tree_height(TR))
  rule tree_height(leaf) => 0

  /* bst tree pattern */
  syntax Map ::= "tree" "(" CanonicalSymLoc ")" "(" Tree ")"    [pattern(1)]
  rule
      tree(loc(BP:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 12))))(node(I:Int, LT:Tree, RT:Tree))
    =>
      BP:Int @ alloc |-> object(t(.Set, no-type), 12,
         0 |-> piece(?I0:Int, 8) 
         1 |-> piece(?I1:Int, 8) 
         2 |-> piece(?I2:Int, 8) 
         3 |-> piece(?I3:Int, 8) 
         4 |-> piece(subObject(?LP, 0, 0), 8)
         5 |-> piece(subObject(?LP, 1, 1), 8)
         6 |-> piece(subObject(?LP, 2, 2), 8)
         7 |-> piece(subObject(?LP, 3, 3), 8)
         8 |-> piece(subObject(?RP, 0, 0), 8)
         9 |-> piece(subObject(?RP, 1, 1), 8)
        10 |-> piece(subObject(?RP, 2, 2), 8)
        11 |-> piece(subObject(?RP, 3, 3), 8),
         0 |-> t(.Set, int)
         4 |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("treeNode"), "bst.c")))))
         8 |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("treeNode"), "bst.c"))))))
      tree(?LP:CanonicalSymLoc)(LT)
      tree(?RP:CanonicalSymLoc)(RT)
  ensures I ==K (((((?I3:Int <<Int 8) |Int ?I2:Int) <<Int 8) |Int ?I1:Int) <<Int 8) |Int ?I0:Int
  andBool min(t(.Set, int)) <=Int I:Int
  andBool I:Int <=Int max(t(.Set, int))
    [pattern]
  rule tree(NullPointer)(leaf) => .Map
    [pattern]

  syntax Bool ::= bst(Tree)   [function, smtlib(smt_bst)]
  rule bst(node(I:Int, TL:Tree, TR:Tree))
    => tree_keys(TL) <IntSet { I } andBool { I } <IntSet tree_keys(TR)
       andBool bst(TL) andBool bst(TR)
  rule bst(leaf) => true

  /* avl tree pattern */
  syntax Map ::= "htree" "(" CanonicalSymLoc ")" "(" Tree ")"    [pattern(1)]
  rule
      htree(loc(BP:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 16))))(node(I:Int, LT:Tree, RT:Tree))
    =>
      BP:Int @ alloc |-> object(t(.Set, no-type), 16,
         0 |-> piece(?I0:Int, 8) 
         1 |-> piece(?I1:Int, 8) 
         2 |-> piece(?I2:Int, 8) 
         3 |-> piece(?I3:Int, 8) 
         4 |-> piece(?I4:Int, 8) 
         5 |-> piece(?I5:Int, 8) 
         6 |-> piece(?I6:Int, 8) 
         7 |-> piece(?I7:Int, 8)
         8 |-> piece(subObject(?LP, 0, 0), 8)
         9 |-> piece(subObject(?LP, 1, 1), 8)
        10 |-> piece(subObject(?LP, 2, 2), 8)
        11 |-> piece(subObject(?LP, 3, 3), 8)
        12 |-> piece(subObject(?RP, 0, 0), 8)
        13 |-> piece(subObject(?RP, 1, 1), 8)
        14 |-> piece(subObject(?RP, 2, 2), 8)
        15 |-> piece(subObject(?RP, 3, 3), 8),
         0 |-> t(.Set, int) // value
         4 |-> t(.Set, int) // height
         8 |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("node"), "avl.c")))))
        12 |-> t(.Set, pointerType(t(.Set, structType(global(Identifier("node"), "avl.c"))))))
      htree(?LP:CanonicalSymLoc)(LT)
      htree(?RP:CanonicalSymLoc)(RT)
  ensures I ==K (((((?I3:Int <<Int 8) |Int ?I2:Int) <<Int 8) |Int ?I1:Int) <<Int 8) |Int ?I0:Int
  andBool min(t(.Set, int)) <=Int I:Int
  andBool I:Int <=Int max(t(.Set, int))
  //
  andBool tree_height(node(I, LT, RT)) ==K (((((?I7:Int <<Int 8) |Int ?I6:Int) <<Int 8) |Int ?I5:Int) <<Int 8) |Int ?I4:Int
  andBool min(t(.Set, int)) <=Int tree_height(node(I, LT, RT))
  andBool tree_height(node(I, LT, RT)) <=Int max(t(.Set, int))
    [pattern]
  rule htree(NullPointer)(leaf) => .Map
    [pattern]

  syntax Bool ::= avl(Tree)   [function, smtlib(smt_avl)]
  rule avl(node(I:Int, TL:Tree, TR:Tree))
    => tree_keys(TL) <IntSet { I } andBool { I } <IntSet tree_keys(TR)
       andBool avl(TL) andBool avl(TR)
       andBool absInt(tree_height(TL) -Int tree_height(TR)) <=Int 1
  rule avl(leaf) => true

  rule tree_height(_:Tree) >=Int 0 => true    [smt-lemma]

endmodule
