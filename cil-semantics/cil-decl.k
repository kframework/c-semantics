// vim: set ts=2 sw=2:
require "modules/k-functional-visitor.k"
require "cil-common.k"
//require "cil-const-propagation.k"

module CIL-DECL
  imports K-FUNCTIONAL-VISITOR 
  imports CIL-TYPING-SYNTAX
  imports CIL-COMMON
  imports CIL-EXP
  //imports CIL-CONST-PROPAGATION

  rule G:Global Gs:Globals => G ~> Gs [structural]
  rule .Globals => .K [structural]

  syntax K ::= declInternal(CId, K) [strict(2)]
             | declExternal(CId, K) [strict(2)]
             | defineFun(Ptr, Type, Params, FunBody)

  /*
   * Function definition.
   */

  rule 
    <k> TS:TypeSpec D:Declarator FB:FunBody
    => declExternal(getId(D), nclv(normType(TS D), FunPtr(getId(D), Tu)))
    ~> defineFun(FunPtr(getId(D), Tu), downFun(normType(TS D)), getParams(D), FB)
    ...</k>
    <phase> Tu:TransUnit </phase>

  rule 
    <k> extern TS:TypeSpec D:Declarator FB:FunBody
    => declExternal(getId(D), nclv(normType(TS D), FunPtr(getId(D), Tu))) 
    ~> defineFun(FunPtr(getId(D), Tu), downFun(normType(TS D)), getParams(D), FB)
    ...</k>
    <phase> Tu:TransUnit </phase>

  rule 
    <k> static TS:TypeSpec D:Declarator FB:FunBody
    => declInternal(getId(D), nclv(normType(TS D), FunPtr(getId(D), Tu)))
    ~> defineFun(FunPtr(getId(D), Tu), downFun(normType(TS D)), getParams(D), FB)
    ...</k>
    <phase> Tu:TransUnit </phase>
  
  rule 
    <k> declInternal(X:CId, nt(T:Type)) => . ...</k>
    <tu-id> Tu </tu-id>
    <env> Env:Map => Env[T / X] </env>
    <tu-env> TuEnv:Map => TuEnv[T / X] </tu-env>
    <phase> Tu:TransUnit </phase>
  rule 
    <k> declInternal(X:CId, nclv(T:Type, P:Ptr)) => . ...</k>
    <tu-id> Tu </tu-id>
    <env> Env:Map => Env[lv(T, P) / X] </env>
    <tu-env> TuEnv:Map => TuEnv[lv(T, P) / X] </tu-env>
    <phase> Tu:TransUnit </phase>
  rule 
    <k> declInternal(X:CId, tv(T:Type, P:Ptr)) => . ...</k>
    <tu-id> Tu </tu-id>
    <env> Env:Map => Env[lv(downPtr(T), P) / X] </env>
    <tu-env> TuEnv:Map => TuEnv[lv(downPtr(T), P) / X] </tu-env>
    <phase> Tu:TransUnit </phase>

  rule 
    <k> declExternal(X:CId, nclv(T:Type, P:Ptr)) => . ...</k>
    <env> Env:Map => Env[lv(T, P) / X] </env>
    <global-env> GEnv:Map => GEnv[lv(T, P) / X] </global-env>
  rule 
    <k> declExternal(X:CId, tv(T:Type, P:Ptr)) => . ...</k>
    <env> Env:Map => Env[lv(downPtr(T), P) / X] </env>
    <global-env> GEnv:Map => GEnv[lv(downPtr(T), P) / X] </global-env>

  rule
    <k>
      defineFun(F:Ptr, T:Type, Ps:Params, FB:FunBody)
    =>
      lower-break-continue-to-goto-control(F) ~> make-goto-table-control(F)
      //~> propagate-constants(F)
    ...</k>
    // <frame-fun-id> _ => F </frame-fun-id>
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

  // Typedefs share the same name space as other declarations.
  rule 
    typedef TS:TypeSpec D:Declarator ; 
    => declInternal(getId(D), nt(normType(TS D)))

  // TODO(chathhorn): what happens if these are functions?!?

  // TODO(chathhorn): Tentative definition; need to look up the rules again.
  rule 
    <k> TS:TypeSpec D:Declarator ;  
    => declExternal(getId(D), newObject(normType(TS D)))
    ...</k>
    <phase> _:TransUnit </phase>

  rule 
    <k> extern TS:TypeSpec D:Declarator ;  
    => declExternal(getId(D), newObject(normType(TS D)))
    ...</k>
    <phase> _:TransUnit </phase>

  rule 
    <k> static TS:TypeSpec D:Declarator ;  
    => declInternal(getId(D), newObject(normType(TS D)))
    ...</k>
    <phase> _:TransUnit </phase>

  rule 
    <k> S:DeclSpecs D:Declarator = E:Exp ;
    => S D ; ~> getId(D) = E ;
    ...</k>
    <phase> _:TransUnit </phase>
  rule 
    <k> S:DeclSpecs D:Declarator = { Is:Initializers } ;
    => S D ; ~> initVar(getId(D), Is, 0)
    ...</k>
    <phase> _:TransUnit </phase>

  syntax K ::= initVar(Exp, Initializers, Int)

  rule initVar(X:Exp, (E:Exp, Is:Initializers), Pos:Int) 
    => (X @ Pos) = E ; ~> initVar(X, Is, Pos +Int 1)

  rule initVar(X:Exp, ({ Is:Initializers }, Is:Initializers), Pos:Int)
    => initVar(X @ Pos, Is, 0) ~> initVar(X, Is, Pos +Int 1)

  rule initVar(_, .Initializers, _) => .

  syntax LVal ::= Exp "@" Int [right]
  context (HOLE => HOLE ~> noLeftValueConversion) @ _:Int
  rule 
    <k> 
      nclv(Agg:AggTypeSpec, Ptr(Base:BasePtr, Offset:Int)) @ Pos:Int
      => lv(T, Ptr(Base, Offset +Int MOffset))
    ...</k>
    <agg-id> Agg </agg-id>
    <field-pos> M </field-pos>
    <field-type> T:Type </field-type>
    <offset> MOffset:Int </offset>

  rule nclv(T:Type, P:Ptr) @ Pos:Int => (lv(T, P))[Pos]
    when isArrayType(T) ==K true

  /*
   * Lower break and continue statements to goto statements 
   */
  syntax K ::= "lower-break-continue-to-goto-control" "(" Ptr ")"
  rule
    <k> lower-break-continue-to-goto-control(F:Ptr) => .K ...</k>
    <fun>...
      <fun-id> F </fun-id>
      <body>
        FB:FunBody => #visit(FB, 'visitWhileFlow, (.K,, .K), 'isWhileFlow)
      </body>
    ...</fun>
  [structural]

  syntax Label ::= "$breakLabel" "(" Int ")"
                 | "$continueLabel" "(" Int ")"
  syntax Bool ::= isWhileFlow(K) [function]
  syntax K ::= visitWhileFlow(K, Label, Label) [function]
  rule isWhileFlow(break;) => true
  //rule isWhileFlow(continue;) => true
  rule isWhileFlow(while(_:Exp) _:Stmt) => true
  rule visitWhileFlow(break;, L:Label, _) => goto L;
  //rule visitWhileFlow(continue;, _, L:Label) => goto L;
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
  syntax K ::= "make-goto-table-control" "(" Ptr ")"
  rule
    <k> make-goto-table-control(F:Ptr) ...</k>
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
    <k> (make-goto-table-control(_:Ptr) => .K) ...</k>
    <make-goto-table>
      <make-goto-table-enabled> true => false </make-goto-table-enabled>
    </make-goto-table>
  [structural]

  rule
    <k> make-goto-table-control(F:Ptr) ...</k>
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
        <make-goto-table-stmts> S (.Stmts) </make-goto-table-stmts>
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
   * Local variable declarations (without initializers).
   */
  rule VD:VarDecl VDs:VarDecls => VD ~> VDs [structural]
  rule .VarDecls => .K [structural]

  rule 
    <k> TS:TypeSpec D:Declarator ; 
    => bindLocal(getId(D), newObject(normType(TS D)))
    ...</k>
    <phase> executing </phase>

  syntax K ::= bindLocal(CId, K) [strict(2)]
  rule
    <k> bindLocal(X:CId, tv(T:Type, P:Ptr)) => .K ...</k>
    <env> M:Map => M:Map[lv(downPtr(T), P) / X] </env>
  [structural]

  syntax K ::= declStruct(CId, VarDecls, K, Int) [strict(3)]
             | declUnion(CId, VarDecls, K, Int) [strict(3)]
  rule 
    <k> struct X:CId { VDs:VarDecls } ; => declStruct(X, VDs, 0, 0) ...</k>
    (. => <aggregate>... <agg-id> struct X </agg-id> ...</aggregate>)
       
  rule declStruct(_, (VD:VarDecl VDs:VarDecls => VD ~> VDs), _, _) 
    [structural]
  rule declStruct(_, (.VarDecls => .) , _, _) 
    [structural]

  rule 
     <k> declStruct(X:CId, T:TypeSpec F:CId; ~> VDs:VarDecls, Offset:TypedValue, Pos:Int) 
     => declStruct(X, VDs, Offset + sizeof(T), Pos +Int 1) ...</k>
     <agg-id> struct X </agg-id>
     <fields>...
        (. => <field>...
          <field-id> F </field-id>
          <field-pos> Pos </field-pos>
          <field-type> T </field-type>
          <offset> val(Offset) </offset>
        ...</field>)
     ...</fields>
    [structural]
     
  rule 
     <k> declStruct(X:CId, .K, Offset:TypedValue, _) => . ...</k>
     <agg-id> struct X </agg-id>
     <size> _ => val(Offset) </size>
    [structural]

  syntax K ::= maxK(K, K) [strict]
  rule maxK(X:TypedValue, Y:TypedValue) => X when val(X) >=Int val(Y)
  rule maxK(X:TypedValue, Y:TypedValue) => Y when val(X) <Int val(Y)

  rule 
    <k> union X:CId { VDs:VarDecls } ; => declUnion(X, VDs, 0, 0) ...</k>
    (. => <aggregate>... <agg-id> union X </agg-id> ...</aggregate>)
       
  rule declUnion(_, (VD:VarDecl VDs:VarDecls => VD ~> VDs), _, _) 
    [structural]
  rule declUnion(_, (.VarDecls => .), _, _) 
    [structural]

  rule 
     <k> declUnion(X:CId, T:TypeSpec F:CId; ~> VDs:VarDecls, Size:TypedValue, Pos:Int)
     => declUnion(X, VDs, maxK(Size, sizeof(T)), Pos +Int 1) ...</k>
     <agg-id> union X </agg-id>
     <fields>...
        (. => <field>...
          <field-id> F </field-id>
          <field-pos> Pos </field-pos>
          <field-type> T </field-type>
          <offset> 0 </offset>
        ...</field>)
     ...</fields>
    [structural]
     
  rule 
     <k> declUnion(X:CId, .K, Size:TypedValue, _) => . ...</k>
     <agg-id> union X </agg-id>
     <size> _ => val(Size) </size>
    [structural]

endmodule
