// Copyright (c) 2014 K Team. All Rights Reserved.

module TREE-PATTERN
  imports CIL-SEMANTICS
  imports MINT-SET

  syntax Tree ::= "node" "(" MInt "," Tree "," Tree ")"
                | "leaf"

  /* tree pattern */
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

  syntax MIntSet ::= "tree_keys" "(" Tree ")"    [function, smtlib(smt_tree_keys)]
  rule tree_keys(node(MI:MInt, TL:Tree, TR:Tree))
    => { MI } U (tree_keys(TL) U tree_keys(TR))
  rule tree_keys(leaf) => .MIntSet

  syntax Bool ::= bst(Tree)   [function, smtlib(smt_bst)]
  rule bst(node(MI:MInt, TL:Tree, TR:Tree))
    => tree_keys(TL) <MIntSet { MI } andBool { MI } <MIntSet tree_keys(TR)
       andBool bst(TL) andBool bst(TR)
  rule bst(leaf) => true

endmodule
