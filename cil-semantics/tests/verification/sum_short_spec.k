require "../cil.k"

module SUM-SPEC
  imports CIL

rule
<strings>
    .Map
</strings>
<external>
    .Set
</external>
<frame>
    <k>
        'call(
            nclv ( unsigned short #__id__ ( unsigned short, .Params ) , FunPtr ( sum , tu ( "/Users/andrei/c-semantics/cil-semantics/verification/sum.c" ) ) ),,
            ('tv('unsignedshort(.KList),, I16N:MInt{bitwidth(16)}), .Exps))
    =>
        'tv('unsignedshort(.KList),, udivMInt(mulMInt(I16N, addMInt(I16N, mi(16, 1))), mi(16, 2)))
    ...</k>
    <frame-fun-id>
        _:KItem
    </frame-fun-id>
    <frame-fun-va-args>
        .K
    </frame-fun-va-args>
    <env>...
        sum |-> lv ( unsigned short #__id__ ( unsigned short, .Params ) , FunPtr ( sum , tu ( "/Users/andrei/c-semantics/cil-semantics/verification/sum.c" ) ) )
    ...</env>
    <locals> _:Set </locals>
</frame>
<frame-stack>
    //_:List
    _:Bag
</frame-stack>
<funs>
  <fun>
    <fun-id>
      FunPtr ( sum , tu ( "/Users/andrei/c-semantics/cil-semantics/verification/sum.c" ) )
    </fun-id>
    <fun-type>
        unsigned short
    </fun-type>
    <formals>
        (unsigned short n), .Params
    </formals>
    <body>
        { unsigned short tmp ; { if ( n ) { tmp = sum ( ((n - ((unsigned short) 1)), .Exps) ) ;
          return ( '_+_(n ,, tmp) ) ; } else { return ( (unsigned short) 0 ) ; } } }
    </body>
    <labels>
        .Map
    </labels>
    <labels-generated>
        false
    </labels-generated>
  </fun>
</funs>
<global-env>
    sum |-> lv ( unsigned short #__id__ ( unsigned short, .Params ) , FunPtr ( sum , tu ( "/Users/andrei/c-semantics/cil-semantics/verification/sum.c" ) ) )
</global-env>
<phase>
   executing 
</phase>
<tus>
  <tu>
    <tu-id>
      tu ( "/Users/andrei/c-semantics/cil-semantics/verification/sum.c" )
    </tu-id>
    <tu-env>
        .Map
    </tu-env>
    <internal>
        .Set
    </internal>
  </tu>
  <tu>
    <tu-id>
      tu ( "unknown" )
    </tu-id>
    <tu-env>
        .Map
    </tu-env>
    <internal>
        .Set
    </internal>
  </tu>
</tus>
<aggregates>
    //.Map
    .Bag
</aggregates>
<heap>
    //_:Map
    _:Bag
</heap>
<make-goto-table>
    <make-goto-table-enabled>
        false
    </make-goto-table-enabled>
    <make-goto-table-tasks>
        .Bag
    </make-goto-table-tasks>
</make-goto-table>
<make-case-labels>
    .Map
</make-case-labels>
//requires ultMInt(I16N, umaxMInt(width(unsigned short) /Int 2))
requires ultMInt(I16N, mi(16, 256))

endmodule

