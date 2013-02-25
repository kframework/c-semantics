require "modules/k-functional-visitor.k"

require "cil-common.k"


module CIL-DECL
  imports K-FUNCTIONAL-VISITOR 
  imports CIL-COMMON


  rule G:Global Gs:Globals => G ~> Gs   [structural]
  rule .Globals => .K    [structural]


  /*
   * Function definition.
   */
  rule
    <k>
      T:Type F:CId(Ps:Params) FB:FunBody
    =>
      lower-break-continue-to-goto-control(F) ~> make-goto-table-control(F)
    ...</k>
    <frame-fun-id> _ => F </frame-fun-id>
    <funs>...
      .Bag
    =>
      <fun>
        <fun-id> F </fun-id>
        <fun-type> T </fun-type>
        <formals> Ps </formals>
        <body> FB </body>
        <labels> .Map </labels>
      </fun>
    ...</funs>
  [structural]


  /*
   * Lower break and continue statements to goto statements 
   */
  syntax K ::= "lower-break-continue-to-goto-control" "(" CId ")"
  rule
    <k> lower-break-continue-to-goto-control(F:CId) => .K ...</k>
    <fun>...
      <fun-id> F </fun-id>
      <body>
        FB:FunBody => #visit(FB, 'visitWhileFlow, (.K,, .K), 'isWhileFlow)
      </body>
    ...</fun>
  [structural]

  syntax Label ::= "$breakLabel" "(" Int ")"
                 | "$continueLabel" "(" Int ")"
  syntax Bool ::= isWhileFlow(K)  [function,label(isWhileFlow)]
  syntax K ::= visitWhileFlow(K, Label, Label)  [function,label(visitWhileFlow)]
  rule isWhileFlow(break;) => true
  rule isWhileFlow(continue;) => true
  rule isWhileFlow(while(_:Exp) _:Stmt) => true
  rule visitWhileFlow(break;, L:Label, _) => goto L;
  rule visitWhileFlow(continue;, _, L:Label) => goto L;
  rule
    visitWhileFlow((while(E:Exp) S:Stmt), _, _)
  =>
    {
      $continueLabel(I):
        while(E)
          #visit(S,
                 'visitWhileFlow,
                 ($breakLabel(I),, $continueLabel(I)),
                 'isWhileFlow)
      $breakLabel(I):
        ;
    }
  when fresh(I:Int)


  /*
   * TODO: Compute the switch table.
   */


  /*
   * Compute the goto table (Map{Label, Stmt})
   */
  syntax K ::= "make-goto-table-control" "(" CId ")"
  rule
    <k> make-goto-table-control(F:CId) ...</k>
    <fun>...
      <fun-id> F </fun-id>
      <body> { _:VarDecls { Ss:Stmts } } </body>
    ...</fun>
    <make-goto-table>
      <make-goto-table-enabled> false => true </make-goto-table-enabled>
      (
        _:Bag
      =>
        <make-goto-table-task>...
          <make-goto-table-stmts> Ss </make-goto-table-stmts>
        ...</make-goto-table-task>
      )
    </make-goto-table>
  [structural]
  rule
    <make-goto-table-task>...
      <make-goto-table-stmts> .Stmts </make-goto-table-stmts>
    ...</make-goto-table-task>
  =>
    .Bag
  [structural]
  rule
    <k> (make-goto-table-control(F:CId) => .K) ...</k>
    <make-goto-table>
      <make-goto-table-enabled> true => false </make-goto-table-enabled>
    </make-goto-table>
  [structural]

  rule
    <k> make-goto-table-control(F:CId) ...</k>
    <fun>...
      <fun-id> F </fun-id>
      <labels>... .Map => L |-> (S Ss1) @Stmts Ss2 ...</labels>
    ...</fun>
    <make-goto-table-task>
      <make-goto-table-stmts>
        L:Label : S:Stmt Ss1:Stmts => S Ss1
      </make-goto-table-stmts>
      <make-goto-table-while-continuation>
        Ss2:Stmts
      </make-goto-table-while-continuation>
    </make-goto-table-task>
  [structural]
  rule
    <make-goto-table-task>
      <make-goto-table-stmts>
        if (_) S1:Stmt else S2:Stmt Ss:Stmts
      </make-goto-table-stmts>
      Cells:Bag
    </make-goto-table-task>
  =>
    <make-goto-table-task>
      <make-goto-table-stmts> S1 @Stmts Ss </make-goto-table-stmts>
      Cells
    </make-goto-table-task>
    <make-goto-table-task>
      <make-goto-table-stmts> S2 @Stmts Ss </make-goto-table-stmts>
      Cells
    </make-goto-table-task>
  [structural]
  rule
    <make-goto-table-task>...
      <make-goto-table-stmts>
        while (E:Exp) S:Stmt Ss:Stmts => Ss
      </make-goto-table-stmts>
    ...</make-goto-table-task>
    (
      .Bag
    =>
      <make-goto-table-task>
        <make-goto-table-stmts> S .Stmts </make-goto-table-stmts>
        <make-goto-table-while-continuation>
          while (E) S Ss
        </make-goto-table-while-continuation>
      </make-goto-table-task>
    )
  [structural]
  rule
    <make-goto-table-stmts>
      { Ss1:Stmts } Ss2:Stmts => Ss1 @Stmts Ss2
    </make-goto-table-stmts>
  [structural]
  rule
    <make-goto-table-stmts>
      KLabel:KLabel(KList:KList) Ss:Stmts => Ss
    </make-goto-table-stmts>
  when
    isStmt(KLabel:KLabel(KList:KList)) andBool
    KLabel =/=KLabel '_:_ andBool
    KLabel =/=KLabel 'if`(_`)_else_ andBool
    KLabel =/=KLabel 'while`(_`)_ andBool
    KLabel =/=KLabel '`{_`}
  [structural]


  /*
   * Variable declarations (without initializers).
   */
  rule VD:VarDecl VDs:VarDecls => VD ~> VDs   [structural]
  rule .VarDecls => .K    [structural]

  rule T:Type X:CId; => bindLocal(X, newObject(T))
  syntax K ::= bindLocal(CId, K)    [strict(2)]
  rule
    <k> bindLocal(X:CId, tv(T:Type*, P:Ptr)) => .K ...</k>
    <env>... .Map => X |-> P ...</env>
    <type-env>... .Map => X |-> T ...</type-env>
  [structural]


  /*
   * Memory management.
   */
  syntax K ::= Object(Type, Map)
  syntax K ::= newObject(Type)
             | "$newObject" "(" Type "," Int "," Type ")"   [strict(3)]
             | castObject(Type, Ptr)
             | deleteObject(Ptr)
  rule newObject(T:Type) => $newObject(T, Base, T)
  when fresh(Base:Int)
  [structural]
  rule
    <k>
      $newObject(T1:Type, Base:Int, T2:Type)
    =>
      tv(T1*, Ptr(BasePtr(Base, (byteWidth(T2))), (0)))
    ...</k>
    <heap>...
      .Bag
    =>
      <object>
        <base-ptr> BasePtr(Base, (byteWidth(T2))) </base-ptr>
        <object-type> T1 </object-type>
        <bytes> Map(#rangeList(byteWidth(T2))) </bytes>
      </object>
    ...</heap>
  [structural]
  rule
    <k> deleteObject(Ptr(BP:BasePtr, (0))) => .K ...</k>
    <heap>...
      <object>...
        <base-ptr> BP </base-ptr>
      ...</object>
    =>
      .Bag
    ...</heap>
  [structural]


  /*
   * Memory access.
   */
  syntax K ::= "load" "(" Type "," Ptr ")"
             | "$load" "(" Type "," Ptr "," Type")"    [strict(3)]
             | "$load" "(" Type "," Ptr "," Nat "," List ")"
             | "store" "(" Type "," Ptr "," Value ")"   [strict(1)]
             | "$store" "(" Ptr "," List ")"

  /* TODO: check beforehand that load/store would be successful */
  rule
    store(T:Type, P:Ptr, V:Value) => $store(P, value2Bytes(T, V))
  [structural]
  rule
    <k>
      $store(
          Ptr(BP:BasePtr, (Offset:Nat => Offset +Int 1)),
          (ListItem(N:Nat) => .List) L:List)
    ...</k>
    <heap>...
      <object>...
        <base-ptr> BP </base-ptr>
        <bytes>... Offset |-> (_ => N) ...</bytes>
      ...</object>
    ...</heap>
  [structural]
  rule $store(_:Ptr, .List) => .K   [structural]

  rule load(T:Type, P:Ptr) => $load(T, P, T) [structural]
  rule
    $load(T1:Type, P:Ptr, T2:Type) => $load(T1, P, (byteWidth(T2)), .List)
  [structural]
  rule
    <k>
      $load(
          _:Type,
          Ptr(BP:BasePtr, (Offset:Nat => Offset +Int 1)),
          (M:Nat => M:Nat -Int 1),
          L:List (.List => ListItem(N:Nat)))
    ...</k>
    <heap>...
      <object>...
        <base-ptr> BP </base-ptr>
        <bytes>... Offset |-> N ...</bytes>
      ...</object>
    ...</heap>
  when M >Int 0
  [structural]
  rule
    $load(T:Type, _:Ptr, (0), L:List) => tv(T, bytes2Value(T, L))
  [structural]

  //context (HOLE => HOLE ~> noLeftValueConversion) = _;
  context '_=_;((HOLE => HOLE ~> noLeftValueConversion),, _)
  rule nclv(T:Type, P:Ptr) = tv(T, V:Value); => store(T, P, V)
    
  rule (lv(T:Type, P:Ptr) => load(T, P)) ~> KLabel:KLabel(KList:KList)
  when KLabel(KList) =/=K noLeftValueConversion
  
endmodule

