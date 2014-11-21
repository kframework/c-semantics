require "../cil.k"

module BINARY-SEARCH-TREE-SPEC
  imports CIL

rule [find-spec]:
<frame>
    <k>
        find(tv(int, V:MInt{bitwidth(32)}), tv(struct treeNode * #__id__, TP:Ptr))
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
<heap>... tree(TP)(T:Tree) ...</heap>
<make-goto-table> MAKEGOTOTABLE </make-goto-table>
requires bst(T)
ensures uvalueMInt(?MI:MInt{bitwidth(32)}) ==K bool2Int(V inMIntSet tree_keys(T))

rule [insert-spec]:
<frame>
    <k>
        insert(tv(int, V:MInt{bitwidth(32)}), tv(struct treeNode * #__id__, TP1:Ptr))
    =>
        tv(struct treeNode * #__id__, ?TP2:Ptr)
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
<heap>... tree(TP1)(T1:Tree) => tree(?TP2)(?T2:Tree) ...</heap>
<make-goto-table> MAKEGOTOTABLE </make-goto-table>
requires bst(T1)
ensures bst(?T2) andBool tree_keys(?T2) ==K { V } U tree_keys(T1)

rule [find-min-spec]:
<frame>
    <k>
        find_min(tv(struct treeNode * #__id__, TP:Ptr))
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
<heap>... tree(TP)(T:Tree) ...</heap>
<make-goto-table> MAKEGOTOTABLE </make-goto-table>
requires TP =/=K Null andBool bst(T)
ensures (?M inMIntSet tree_keys(T)) andBool ({ ?M } <=MIntSet tree_keys(T))

rule [delete-spec]:
<frame>
    <k>
        delete(tv(int, V:MInt{bitwidth(32)}), tv(struct treeNode * #__id__, TP1:Ptr))
    =>
        tv(struct treeNode * #__id__, ?TP2:Ptr)
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
<heap>... tree(TP1)(T1:Tree) => tree(?TP2)(?T2:Tree) ...</heap>
<make-goto-table> MAKEGOTOTABLE </make-goto-table>
requires bst(T1)
ensures bst(?T2) andBool tree_keys(?T2) ==K tree_keys(T1) -MIntSet { V }

endmodule
