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

endmodule
