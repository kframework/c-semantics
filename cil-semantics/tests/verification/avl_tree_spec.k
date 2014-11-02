require "../cil.k"

module AVL-TREE-SPEC
  imports CIL

rule [find-spec]:
<frame>
    <k>
        find(tv(int, V:MInt{bitwidth(32)}), tv(struct node * #__id__, TP:Ptr))
    =>
        tv(int, ?MI:MInt{bitwidth(32)})
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
        tv(int, ?M:MInt{bitwidth(32)})
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

endmodule
