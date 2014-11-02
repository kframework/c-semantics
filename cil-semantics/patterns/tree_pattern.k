// Copyright (c) 2014 K Team. All Rights Reserved.

module TREE-PATTERN
  imports CIL-SEMANTICS
  imports MINT-SET

  syntax Tree ::= "node" "(" MInt "," Tree "," Tree ")"
                | "leaf"

  /* bst tree pattern */
  syntax Bag ::= "tree" "(" Ptr ")" "(" Tree ")"    [pattern(1)]
  rule
    <heap>...
      tree(Ptr(BP:BasePtr, 0))(node(MI:MInt{bitwidth(32)}, TL:Tree, TR:Tree))
    =>
      <object>
        <base-ptr> BP </base-ptr>
        <bytes>
          0 |-> ?B0:MInt{bitwidth(8)}
          1 |-> ?B1:MInt{bitwidth(8)}
          2 |-> ?B2:MInt{bitwidth(8)}
          3 |-> ?B3:MInt{bitwidth(8)}
          4 |-> ?PL:Ptr
          5 |-> used
          6 |-> used
          7 |-> used
          8 |-> ?PR:Ptr
          9 |-> used
          10 |-> used
          11 |-> used
        </bytes>
      </object>
      tree(?PL)(TL)
      tree(?PR)(TR)
    ...</heap>
    ensures MI ==K mIntOfDigits(ListItem(?B0) ListItem(?B1) ListItem(?B2) ListItem(?B3))
    [pattern]
  rule <heap>... tree(Null)(leaf) => .Bag ...</heap>
    [pattern]

  /* avl tree pattern */
  syntax Bag ::= "htree" "(" Ptr ")" "(" Tree ")"    [pattern(1)]
  rule
    <heap>...
      htree(Ptr(BP:BasePtr, 0))(node(MI:MInt{bitwidth(32)}, TL:Tree, TR:Tree))
    =>
      <object>
        <base-ptr> BP </base-ptr>
        <bytes>
          0 |-> ?B0:MInt{bitwidth(8)}
          1 |-> ?B1:MInt{bitwidth(8)}
          2 |-> ?B2:MInt{bitwidth(8)}
          3 |-> ?B3:MInt{bitwidth(8)}
          4 |-> ?B4:MInt{bitwidth(8)}
          5 |-> ?B5:MInt{bitwidth(8)}
          6 |-> ?B6:MInt{bitwidth(8)}
          7 |-> ?B7:MInt{bitwidth(8)}
          8 |-> ?PL:Ptr
          9 |-> used
          10 |-> used
          11 |-> used
          12 |-> ?PR:Ptr
          13 |-> used
          14 |-> used
          15 |-> used
        </bytes>
      </object>
      htree(?PL)(TL)
      htree(?PR)(TR)
    ...</heap>
    ensures MI ==K mIntOfDigits(ListItem(?B0) ListItem(?B1) ListItem(?B2) ListItem(?B3)) andBool
            tree_height(node(MI, TL, TR)) ==Int uvalueMInt(mIntOfDigits(ListItem(?B4) ListItem(?B5) ListItem(?B6) ListItem(?B7)))
    [pattern]
  rule <heap>... htree(Null)(leaf) => .Bag ...</heap>
    [pattern]

  syntax MIntSet ::= "tree_keys" "(" Tree ")"    [function, smtlib(smt_tree_keys)]
  rule tree_keys(node(MI:MInt, TL:Tree, TR:Tree))
    => { MI } U (tree_keys(TL) U tree_keys(TR))
  rule tree_keys(leaf) => .MIntSet

  syntax Int ::= "tree_height" "(" Tree ")"     [function, smtlib(smt_tree_height)]
  rule tree_height(node(_, TL:Tree, TR:Tree))
    => 1 +Int maxInt(tree_height(TL), tree_height(TR))
  rule tree_height(leaf) => 0

  rule tree_height(T:Tree) >=Int 0 => true    [smt-lemma]

  syntax Bool ::= bst(Tree)   [function, smtlib(smt_bst)]
  rule bst(node(MI:MInt, TL:Tree, TR:Tree))
    => tree_keys(TL) <MIntSet { MI } andBool { MI } <MIntSet tree_keys(TR)
       andBool bst(TL) andBool bst(TR)
  rule bst(leaf) => true

  syntax Bool ::= avl(Tree)   [function, smtlib(smt_avl)]
  rule avl(node(MI:MInt, TL:Tree, TR:Tree))
    => tree_keys(TL) <MIntSet { MI } andBool { MI } <MIntSet tree_keys(TR)
       andBool absInt(tree_height(TL) -Int tree_height(TR)) <=Int 1
       andBool avl(TL) andBool avl(TR)
  rule avl(leaf) => true

endmodule
