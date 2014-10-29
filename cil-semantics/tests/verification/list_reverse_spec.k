require "../cil.k"

module SUM-SPEC
  imports CIL

rule
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
      // TODO(YilongL): implement a naive AC-matching for BuiltinSet and replace the memory locations with integer variables
      x |-> lv ( struct listNode * #__id__ , Ptr ( BasePtr ( 17 , 4 ) , 0 ) )
      p |-> lv ( struct listNode * #__id__ , Ptr ( BasePtr ( 19 , 4 ) , 0 ) )
      y |-> lv ( struct listNode * #__id__ , Ptr ( BasePtr ( 21 , 4 ) , 0 ) )
  ...</env>
  <locals>
      SetItem ( Ptr ( BasePtr ( 17 , 4 ) , 0 ) )
      SetItem ( Ptr ( BasePtr ( 19 , 4 ) , 0 ) )
      SetItem ( Ptr ( BasePtr ( 21 , 4 ) , 0 ) )
  </locals>
...</frame>
<phase>
  executing
</phase>
<tus>... TUS ...</tus>
<aggregates>... AGGREGATES ...</aggregates>
<heap>...
  <object>
    <base-ptr> BasePtr ( 17 , 4 ) </base-ptr>
    <bytes>
      0 |-> (X1:Ptr => ?X2:Ptr)
      1 |-> used
      2 |-> used
      3 |-> used
    </bytes>
  </object>
  <object>
    <base-ptr> BasePtr ( 19 , 4 ) </base-ptr>
    <bytes>
      0 |-> (P1:Ptr => ?P2:Ptr)
      1 |-> used
      2 |-> used
      3 |-> used
    </bytes>
  </object>
  <object>
    <base-ptr> BasePtr ( 21 , 4 ) </base-ptr>
    <bytes>
      0 |-> (Y1:Ptr => ?Y2:Ptr)
      1 |-> used
      2 |-> used
      3 |-> used
    </bytes>
  </object>
  (list(X1)(B:List) list(P1)(C:List) => list(?P2)(?A:List))
...</heap>
<make-goto-table> MAKEGOTOTABLE </make-goto-table>
ensures ?A ==K rev(B) C
endmodule
