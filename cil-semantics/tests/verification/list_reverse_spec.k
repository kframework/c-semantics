require "../cil.k"

module SUM-SPEC
  imports CIL

rule
<strings>
  _:Map
</strings>
<external>...
  _:Set 
...</external>
<frame>
  <k>
      while ( ((( unsigned long ) x) != (( unsigned long ) (( void * ) 0))) ) {
        y = ((* x) . next) ;
        ((* x) . next) = p;
        p = x;
        x = y;
      }
      $breakLabel ( 1 ) : ;
  =>
      .K
  ...</k>
  <frame-fun-id>
      FunPtr ( reverse , tu ( "unknown" ) )
  </frame-fun-id>
  <frame-fun-va-args>
      .K
  </frame-fun-va-args>
  <env>...
  /*
      (size_t |-> unsigned long)
  */
      x |-> lv ( struct listNode * #__id__ , Ptr ( BasePtr ( 17 , 4 ) , 0 ) )
      (p |-> lv ( struct listNode * #__id__ , Ptr ( BasePtr ( 19 , 4 ) , 0 ) ))
      (y |-> lv ( struct listNode * #__id__ , Ptr ( BasePtr ( 21 , 4 ) , 0 ) ))
  ...</env>
  <locals>
      SetItem ( Ptr ( BasePtr ( 17 , 4 ) , 0 ) )
      SetItem ( Ptr ( BasePtr ( 19 , 4 ) , 0 ) )
      SetItem ( Ptr ( BasePtr ( 21 , 4 ) , 0 ) )
  </locals>
</frame>
<frame-stack>
  _:Bag
</frame-stack>
<funs>
  _:Bag
</funs>
<global-env>
  _:Map
</global-env>
<phase>
  executing
</phase>
<tus>
  <tu>
    <tu-id>
      tu ( "unknown" )
    </tu-id>
    <tu-env>
      size_t |-> unsigned long
    </tu-env>
    <internal>
      .Set
    </internal>
  </tu>
</tus>
<aggregates>...
  <aggregate>
    <agg-id> struct listNode </agg-id>
    <size> 8 </size>
    <fields>
      <field>
        <field-id> value </field-id>
        <field-pos> 0 </field-pos>
        <field-type> int </field-type>
        <offset> 0 </offset>
      </field>
      <field>
        <field-id> next </field-id>
        <field-pos> 1 </field-pos>
        <field-type> struct listNode * #__id__ </field-type>
        <offset> 4 </offset>
      </field>
    </fields>
  </aggregate>
...</aggregates>
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
  (list(X1)(B:Seq) list(P1)(C:Seq) => list(?P2)(?A:Seq))
...</heap>
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
ensures ?A ==K rev(B) @ C
endmodule

