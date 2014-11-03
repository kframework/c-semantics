require "../cil.k"

module AVL-TREE-SPEC
  imports CIL

rule [find-spec]:
<frame>
    <k>
        find(tv(unsigned int, V:MInt{bitwidth(32)}), tv(struct node * #__id__, TP:Ptr))
    =>
        tv(unsigned int, ?MI:MInt{bitwidth(32)})
    ...</k>
    <frame-fun-va-args>
        .K
    </frame-fun-va-args>
    <env>... ENV:Map ...</env>
...</frame>
<funs>... FUNS:Bag ...</funs>
<aggregates>... AGGREGATES ...</aggregates>
<global-env>... GLOBALENV:Map ...</global-env>
<phase>
   executing
</phase>
<tus> TUS:Bag </tus>
<heap>... htree(TP)(T:Tree) ...</heap>
<make-goto-table> MAKEGOTOTABLE </make-goto-table>
requires avl(T)
ensures (?MI:MInt{bitwidth(32)} =/=K mi(32, 0)) ==K (V inMIntSet tree_keys(T))
[trusted]

rule [find-min-spec]:
<frame>
    <k>
        find_min(tv(struct node * #__id__, TP:Ptr))
    =>
        tv(unsigned int, ?M:MInt{bitwidth(32)})
    ...</k>
    <frame-fun-va-args>
        .K
    </frame-fun-va-args>
    <env>... ENV:Map ...</env>
...</frame>
<funs>... FUNS:Bag ...</funs>
<aggregates>... AGGREGATES ...</aggregates>
<global-env>... GLOBALENV:Map ...</global-env>
<phase>
   executing
</phase>
<tus> TUS:Bag </tus>
<heap>... htree(TP)(T:Tree) ...</heap>
<make-goto-table> MAKEGOTOTABLE </make-goto-table>
requires TP =/=K Null andBool avl(T)
ensures (?M inMIntSet tree_keys(T)) andBool ({ ?M } <=MIntSet tree_keys(T))
[trusted]

// TODO(YilongL): prove update_height
rule [update-height-spec]:
<frame>
    <k>
        update_height(tv(struct node * #__id__, Ptr(BP:BasePtr, 0)))
    =>
        tv(void, undef)
    ...</k>
    <frame-fun-va-args>
        .K
    </frame-fun-va-args>
    <env>... ENV:Map ...</env>
...</frame>
<funs>... FUNS:Bag ...</funs>
<aggregates>... AGGREGATES ...</aggregates>
<global-env>... GLOBALENV:Map ...</global-env>
<phase>
    executing
</phase>
<tus> TUS:Bag </tus>
<heap>...
    <object>
        <base-ptr> BP </base-ptr>
        <bytes>
          // TODO: remove B0 ~ B3
          0 |-> B0:MInt{bitwidth(8)}
          1 |-> B1:MInt{bitwidth(8)}
          2 |-> B2:MInt{bitwidth(8)}
          3 |-> B3:MInt{bitwidth(8)}
          '_Map_( ('_|->_(4,, (_:K => ?B4:MInt{bitwidth(8)}))) ,,
          '_Map_( ('_|->_(5,, (_:K => ?B5:MInt{bitwidth(8)}))) ,,
          '_Map_( ('_|->_(6,, (_:K => ?B6:MInt{bitwidth(8)}))) ,,
                  ('_|->_(7,, (_:K => ?B7:MInt{bitwidth(8)}))) ) ) )
          8 |-> PL:Ptr
          9 |-> used
          10 |-> used
          11 |-> used
          12 |-> PR:Ptr
          13 |-> used
          14 |-> used
          15 |-> used
        </bytes>
    </object>
    htree(PL)(TL:Tree)
    htree(PR)(TR:Tree)
...</heap>
<make-goto-table> MAKEGOTOTABLE </make-goto-table>
//requires tree_height(TR) <Int umaxMInt(32)
//ensures tree_height(TR) +Int 1 ==Int uvalueMInt(mIntOfDigits(ListItem(?B4) ListItem(?B5) ListItem(?B6) ListItem(?B7)))
//requires avl(TL) andBool avl(TR) andBool maxInt(tree_height(TL), tree_height(TR)) <Int smaxMInt(32)
//ensures tree_height(node(_, TL, TR)) ==Int uvalueMInt(mIntOfDigits(ListItem(?B4) ListItem(?B5) ListItem(?B6) ListItem(?B7)))

endmodule
