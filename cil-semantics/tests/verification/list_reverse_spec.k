require "../cil.k"

module SUM-SPEC
  imports CIL

rule [loop-inv]:
<frame>...
  <k>
      // TODO(YilongL): investigate why the 'unsigned long' cast would fail the prover
      //while ( ((( unsigned long ) x) != (( unsigned long ) (( void * ) 0))) ) {
      while (x != ( void * ) 0) {
        y = x->next;
        x->next = p;
        p = x;
        x = y;
      }
  =>
      .K
  ...</k>
  <frame-fun-va-args>
      .K
  </frame-fun-va-args>
  <env>...
      (size_t |-> unsigned long)
      x |-> lv ( struct listNode * #__id__ , Ptr ( BasePtr ( PX:Int , 4 ) , 0 ) )
      p |-> lv ( struct listNode * #__id__ , Ptr ( BasePtr ( PP:Int , 4 ) , 0 ) )
      y |-> lv ( struct listNode * #__id__ , Ptr ( BasePtr ( PY:Int , 4 ) , 0 ) )
  ...</env>
  <locals>
      SetItem ( Ptr ( BasePtr ( PX:Int , 4 ) , 0 ) )
      SetItem ( Ptr ( BasePtr ( PP:Int , 4 ) , 0 ) )
      SetItem ( Ptr ( BasePtr ( PY:Int , 4 ) , 0 ) )
  </locals>
...</frame>
<phase>
  executing
</phase>
<tus>... TUS ...</tus>
<aggregates>... AGGREGATES ...</aggregates>
<heap>...
  <object>
    <base-ptr> BasePtr ( PX:Int , 4 ) </base-ptr>
    <bytes>
      0 |-> (X1:Ptr => ?X2:Ptr)
      1 |-> used
      2 |-> used
      3 |-> used
    </bytes>
  </object>
  <object>
    <base-ptr> BasePtr ( PP:Int , 4 ) </base-ptr>
    <bytes>
      0 |-> (P1:Ptr => ?P2:Ptr)
      1 |-> used
      2 |-> used
      3 |-> used
    </bytes>
  </object>
  <object>
    <base-ptr> BasePtr ( PY:Int , 4 ) </base-ptr>
    <bytes>
      0 |-> (_ => ?_)
      1 |-> (_ => ?_)
      2 |-> (_ => ?_)
      3 |-> (_ => ?_)
    </bytes>
  </object>
  (list(X1)(B:List) list(P1)(C:List) => list(?P2)(?A:List))
...</heap>
<make-goto-table> MAKEGOTOTABLE </make-goto-table>
ensures ?A ==K rev(B) C

rule [func-spec]:
<frame>
    <k>
        reverse(tv(struct listNode * #__id__, LP:Ptr))
    =>
        tv(struct listNode * #__id__, ?LP:Ptr)
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
  list(LP)(A:List) => list(?LP)(rev(A))
...</heap>
<make-goto-table> MAKEGOTOTABLE </make-goto-table>

endmodule
