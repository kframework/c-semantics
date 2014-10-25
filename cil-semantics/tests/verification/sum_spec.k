require "../../cil.k"

module SUM-SPEC
  imports CIL

rule
<frame>
    <k>
        'call(
            nclv(unsigned int #__id__ ( unsigned int ) , FunPtr(sum, tu("unknown"))),,
            ('tv(unsigned int,, I32N:MInt{bitwidth(32)}), .Exps)) // TODO(YilongL): get rid of .Exps
    =>
        'tv(unsigned int,, udivMInt(mulMInt(I32N, addMInt(I32N, mi(32, 1))), mi(32, 2)))
    ...</k>
    <frame-fun-va-args>
        .K
    </frame-fun-va-args>
    <env>... ENV:Map ...</env>
...</frame>
<funs>... FUNS:Bag ...</funs>
<global-env>... GLOBALENV:Map ...</global-env>
<phase>
   executing
</phase>
<tus> TUS:Bag </tus>
<make-goto-table>
    <make-goto-table-enabled>
        false
    </make-goto-table-enabled>
    <make-goto-table-tasks>
        .Bag
    </make-goto-table-tasks>
</make-goto-table>
//requires ultMInt(I32N, umaxMInt(width(unsigned int) /Int 2))
requires ultMInt(I32N, mi(32, 65536))

endmodule
