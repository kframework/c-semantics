// Copyright (c) 2014 K Team. All Rights Reserved.

module TREE-PATTERN-SYNTAX
  imports INT-SET
  imports C-DYNAMIC-SYNTAX

  syntax Tree ::= "node" "(" Int "," Tree "," Tree ")"
                | "leaf"

  syntax Map ::= "tree" "(" SymLoc ")" "(" Tree ")"    [pattern(1)]
  syntax IntSet ::= "tree_keys" "(" Tree ")"    [function, smtlib(smt_tree_keys)]
  syntax Int ::= "tree_height" "(" Tree ")"     [function, smtlib(smt_tree_height)]
  syntax Bool ::= bst(Tree)   [function, smtlib(smt_bst)]
  syntax Bool ::= avl(Tree)   [function, smtlib(smt_avl)]
endmodule

module TREE-PATTERN
  imports TREE-PATTERN-SYNTAX

  /* bst tree pattern */
  rule
      tree(loc(BP:Int @ alloc, 0, SetItem(align(16)) SetItem(fromArray(0, 12))))(node(I:Int, LT:Tree, RT:Tree))
    =>
      BP:Int @ alloc |-> object(t(.Set, no-type), 12,
         0 |-> piece(?B0:Int, 8)
         1 |-> piece(?B1:Int, 8)
         2 |-> piece(?B2:Int, 8)
         3 |-> piece(?B3:Int, 8)
         4 |-> piece(subObject(?LP, 0, 0), 8)
         5 |-> piece(subObject(?LP, 1, 1), 8)
         6 |-> piece(subObject(?LP, 2, 2), 8)
         7 |-> piece(subObject(?LP, 3, 3), 8)
         8 |-> piece(subObject(?RP, 0, 0), 8)
         9 |-> piece(subObject(?RP, 1, 1), 8)
        10 |-> piece(subObject(?RP, 2, 2), 8)
        11 |-> piece(subObject(?RP, 3, 3), 8))
      tree(?LP:SymLoc)(LT)
      tree(?RP:SymLoc)(RT)
    //ensures MI ==K mIntOfDigits(ListItem(?B0) ListItem(?B1) ListItem(?B2) ListItem(?B3))
    [pattern]
  rule tree(NullPointer)(leaf) => .Map
    [pattern]

//  /* avl tree pattern */
//  syntax Bag ::= "htree" "(" Ptr ")" "(" Tree ")"    [pattern(1)]
//  rule
//    <heap>...
//      htree(Ptr(BP:BasePtr, 0))(node(MI:MInt{bitwidth(32)}, TL:Tree, TR:Tree))
//    =>
//      <object>
//        <base-ptr> BP </base-ptr>
//        <bytes>
//          0 |-> ?B0:MInt{bitwidth(8)}
//          1 |-> ?B1:MInt{bitwidth(8)}
//          2 |-> ?B2:MInt{bitwidth(8)}
//          3 |-> ?B3:MInt{bitwidth(8)}
//          4 |-> ?B4:MInt{bitwidth(8)}
//          5 |-> ?B5:MInt{bitwidth(8)}
//          6 |-> ?B6:MInt{bitwidth(8)}
//          7 |-> ?B7:MInt{bitwidth(8)}
//          8 |-> ?PL:Ptr
//          9 |-> used
//          10 |-> used
//          11 |-> used
//          12 |-> ?PR:Ptr
//          13 |-> used
//          14 |-> used
//          15 |-> used
//        </bytes>
//      </object>
//      htree(?PL)(TL)
//      htree(?PR)(TR)
//    ...</heap>
//    ensures MI ==K mIntOfDigits(ListItem(?B0) ListItem(?B1) ListItem(?B2) ListItem(?B3)) andBool
//            tree_height(node(MI, TL, TR)) ==Int uvalueMInt(mIntOfDigits(ListItem(?B4) ListItem(?B5) ListItem(?B6) ListItem(?B7)))
//    [pattern]
//  rule <heap>... htree(Null)(leaf) => .Bag ...</heap>
//    [pattern]

  rule tree_keys(node(I:Int, TL:Tree, TR:Tree))
    => { I } U (tree_keys(TL) U tree_keys(TR))
  rule tree_keys(leaf) => .IntSet

  rule tree_height(node(_, TL:Tree, TR:Tree))
    => 1 +Int maxInt(tree_height(TL), tree_height(TR))
  rule tree_height(leaf) => 0

  rule tree_height(T:Tree) >=Int 0 => true    [smt-lemma]

  rule bst(node(I:Int, TL:Tree, TR:Tree))
    => tree_keys(TL) <IntSet { I } andBool { I } <IntSet tree_keys(TR)
       andBool bst(TL) andBool bst(TR)
  rule bst(leaf) => true

  rule avl(node(I:Int, TL:Tree, TR:Tree))
    => tree_keys(TL) <IntSet { I } andBool { I } <IntSet tree_keys(TR)
       andBool absInt(tree_height(TL) -Int tree_height(TR)) <=Int 1
       andBool avl(TL) andBool avl(TR)
  rule avl(leaf) => true

endmodule

