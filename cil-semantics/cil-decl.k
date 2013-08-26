// vim: set ts=2 sw=2:
require "modules/k-functional-visitor.k"
require "cil-common.k"

module CIL-DECL
  imports K-FUNCTIONAL-VISITOR 
  imports CIL-TYPING-SYNTAX
  imports CIL-COMMON
  imports CIL-EXP

  rule G:Global Gs:Globals => G ~> Gs [structural]
  rule .Globals => .K [structural]

  // It appears that CIL substitutes constants for the enum tags, but leaves
  // the declaration, so I think it can be safely elided.
  rule enum _:CId { _:EnumInits } ; => .
  rule enum _:CId ; => .

  syntax K ::= declInternal(CId, K) [strict(2)]
             | declExternal(CId, K) [strict(2)]
             | defineFun(Ptr, Type, Params, FunBody)

  /*
   * Function definition.
   */
  rule 
    <k> TS:TypeSpec D:Declarator FB:FunBody
    => declExternal(getId(D), nclv(normType(TS D), FunPtr(getId(D), Tu)))
    ~> defineFun(
      FunPtr(getId(D), Tu), 
      expandTypedefs(downFun(normType(TS D)), E), 
      getParams(D), FB)
    ...</k>
    <env> E:Map </env>
    <external> ExtLnk:Set </external>
    <phase> Tu:TransUnit </phase>
    when getId(D) in ExtLnk
  rule 
    <k> TS:TypeSpec D:Declarator FB:FunBody
    => declExternal(getId(D), nclv(normType(TS D), FunPtr(getId(D), Tu)))
    ~> defineFun(FunPtr(getId(D), Tu), 
      expandTypedefs(downFun(normType(TS D)), E), 
      getParams(D), FB)
    ...</k>
    <env> E:Map </env>
    <external> ExtLnk:Set </external>
    <tu-id> Tu </tu-id>
    <internal> IntLnk:Set </internal>
    <phase> Tu:TransUnit </phase>
    when notBool (getId(D) in IntLnk)
      andBool notBool (getId(D) in ExtLnk)
        
  rule 
    <k> TS:TypeSpec D:Declarator FB:FunBody
    => declInternal(getId(D), nclv(normType(TS D), FunPtr(getId(D), Tu)))
    ~> defineFun(FunPtr(getId(D), Tu), 
      expandTypedefs(downFun(normType(TS D)), E), 
      getParams(D), FB)
    ...</k>
    <tu-id> Tu </tu-id>
    <env> E:Map </env>
    <internal> IntLnk:Set </internal>
    <phase> Tu:TransUnit </phase>
    when getId(D) in IntLnk

  rule 
    <k> extern TS:TypeSpec D:Declarator FB:FunBody
    => declExternal(getId(D), nclv(normType(TS D), FunPtr(getId(D), Tu))) 
    ~> defineFun(FunPtr(getId(D), Tu), 
      expandTypedefs(downFun(normType(TS D)), E), 
      getParams(D), FB)
    ...</k>
    <env> E:Map </env>
    <phase> Tu:TransUnit </phase>

  rule 
    <k> static TS:TypeSpec D:Declarator FB:FunBody
    => declInternal(getId(D), nclv(normType(TS D), FunPtr(getId(D), Tu)))
    ~> defineFun(FunPtr(getId(D), Tu), 
      expandTypedefs(downFun(normType(TS D)), E), 
      getParams(D), FB)
    ...</k>
    <env> E:Map </env>
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
    => lower-break-continue-to-goto-control(F) 
      //~> propagate-constants(F)
    ...</k>
    <funs>...
      .Bag
    =>
      <fun>
        <fun-id> F </fun-id>
        <fun-type> T </fun-type>
        <formals> Ps </formals>
        <body> FB </body>
      ...</fun>
    ...</funs>
  [structural]

  /*
   * Function declarations (without initializers).
   */
  rule
    <k> extern TS:TypeSpec D:Declarator ; 
    => declExternal(getId(D), 
      nclv(normType(TS D), ExtFun(#tokenToString(getId(D))))) ...</k>
    <external>... (. => SetItem(getId(D))) ...</external>
    <phase> _:TransUnit </phase>
    when isFunType(normType(TS D)) ==K true
  rule
    <k> static TS:TypeSpec D:Declarator ; => . ...</k>
    <internal>... (. => SetItem(getId(D))) ...</internal>
    <tu-id> Tu </tu-id>
    <phase> Tu:TransUnit </phase>
    when isFunType(normType(TS D)) ==K true
  rule
    <k> TS:TypeSpec D:Declarator ; => . ...</k>
    <phase> _:TransUnit </phase>
    when isFunType(normType(TS D)) ==K true

  /*
   * Typedef declarations.
   */
  // Typedefs share the same name space as other declarations.
  rule 
    typedef TS:TypeSpec D:Declarator ; 
    => declInternal(getId(D), nt(normType(TS D)))

  // TODO(chathhorn): actually handle linkage properly (e.g., if a declaration
  // has static linkage and a def has no linkage spec, then it's static).

  /*
   * File-scope variable declarations (without initializers).
   */
  // TODO(chathhorn): Correct semantics for tentative definitions.
  rule 
    <k> TS:TypeSpec D:Declarator ;  
    => declExternal(getId(D), newZeroObject(normType(TS D)))
    ...</k>
    <phase> _:TransUnit </phase>
    when isFunType(normType(TS D)) =/=K true

  rule 
    <k> extern TS:TypeSpec D:Declarator ;  
    => declExternal(getId(D), newZeroObject(normType(TS D)))
    ...</k>
    <phase> _:TransUnit </phase>
    when isFunType(normType(TS D)) =/=K true

  rule 
    <k> static TS:TypeSpec D:Declarator ;  
    => declInternal(getId(D), newZeroObject(normType(TS D)))
    ...</k>
    <phase> _:TransUnit </phase>
    when isFunType(normType(TS D)) =/=K true

  /*
   * File-scope variable declarations (with initializers).
   */
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

  rule initVar(X:Exp, ({ Is1:Initializers }, Is2:Initializers), Pos:Int)
    => initVar(X @ Pos, Is1, 0) ~> initVar(X, Is2, Pos +Int 1)

  rule initVar(_, .Initializers, _) => .

  syntax Exp ::= Exp "@" Int [right]
  context (HOLE => HOLE ~> noLeftValueConversion) @ _
  rule 
    <k>
      nclv(Agg:AggTypeSpec, Ptr(Base:BasePtr, Offset:Int)) @ Pos:Int
      => lv(T, Ptr(Base, Offset +Int MOffset))
    ...</k>
    <agg-id> Agg </agg-id>
    <field-pos> Pos </field-pos>
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
        FB:FunBody => normLabels(FB)
      </body>
    ...</fun>
  [structural]

  syntax Label ::= "$breakLabel" "(" Int ")"
                 | "$continueLabel" "(" Int ")"
                 | "$caseLabel" "(" Int "," Exp ")" [klabel('$caseLabel)]
                 | "$defaultLabel" "(" Int ")"
  syntax Bool ::= needsLabelNorm(K) [function]
  syntax K ::= normLabelsVisitor(K, Int) [function]
  syntax Stmt ::= normLabelsStmt(Stmt, Int) [function]
  syntax Stmts ::= normLabelsStmts(Stmts, Int) [function]
  syntax FunBody ::= normLabels(FunBody) [function]

  rule needsLabelNorm(break;) => true
  rule needsLabelNorm(continue;) => true
  rule needsLabelNorm(case _ : _) => true
  rule needsLabelNorm(default : _) => true
  rule needsLabelNorm(while(_) _) => true
  rule needsLabelNorm(switch(_) _) => true

  rule normLabelsVisitor(break;, I:Int) => goto $breakLabel(I);
  rule normLabelsVisitor(continue;, I:Int) => goto $continueLabel(I);
  rule normLabelsVisitor(case E:Exp : S:Stmt , I:Int) => $caseLabel(I, E): S
  rule normLabelsVisitor(default : S:Stmt , I:Int) => $defaultLabel(I): S
  rule normLabelsVisitor(while(E:Exp) S:Stmt, _)
    => {
          $continueLabel(I): 
            while(E) normLabelsStmt(S, I)
          $breakLabel(I): ;
        }
    when fresh(I:Int)
  rule normLabelsVisitor(switch(E:Exp) { Ss:Stmts }, _)
    =>
      {
          goto $caseLabel(I, E);
          @Stmts
          normLabelsStmts(Ss, I)
          @Stmts
          $breakLabel(I): ;
      }
    when fresh(I:Int)

  rule normLabelsStmt(S:Stmt, I:Int)
    => #visit(S, 'normLabelsVisitor, I, 'needsLabelNorm)::Stmt
  rule normLabelsStmts(Ss:Stmts, I:Int)
    => #visit(Ss, 'normLabelsVisitor, I, 'needsLabelNorm)::Stmts
  rule normLabels(FB:FunBody)
    => #visit(FB, 'normLabelsVisitor, 0, 'needsLabelNorm)::FunBody

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

  syntax K ::= declStruct(CId, K, K, Int) [strict(3)]
             | declUnion(CId, K, K, Int) [strict(3)]

  // Elide declarations without definitions.
  rule struct _:CId ; => . [structural]
  rule union _:CId ; => . [structural]

  rule 
    <k> struct X:CId { VDs:VarDecls } ; => declStruct(X, VDs, 0, 0) ...</k>
    (. => <aggregate>... <agg-id> struct X </agg-id> ...</aggregate>)
       
  rule declStruct(_, (VD:VarDecl VDs:VarDecls => VD ~> VDs), _, _) 
    [structural]
  rule declStruct(_, (.VarDecls => .) , _, _) 
    [structural]

  rule 
     <k> declStruct(X:CId, TS:TypeSpec D:Declarator; ~> VDs:VarDecls, Offset:TypedValue, Pos:Int) 
     => declStruct(X, VDs, (size_t) Offset + sizeof'(normType(TS D)), Pos +Int 1) ...</k>
     <agg-id> struct X </agg-id>
     <fields>...
        (. => <field>...
          <field-id> getId(D) </field-id>
          <field-pos> Pos </field-pos>
          <field-type> normType(TS D) </field-type>
          <offset> mival(Offset) </offset>
        ...</field>)
     ...</fields>
    [structural]
     
  rule 
     <k> declStruct(X:CId, .K, Offset:TypedValue, _) => . ...</k>
     <agg-id> struct X </agg-id>
     <size> _ => mival(Offset) </size>
    [structural]

  syntax K ::= maxK(K, K) [strict]
  rule maxK(X:TypedValue, Y:TypedValue) => X 
    when mival(X) >=Int mival(Y)
  rule maxK(X:TypedValue, Y:TypedValue) => Y 
    when mival(X) <Int mival(Y)

  rule 
    <k> union X:CId { VDs:VarDecls } ; => declUnion(X, VDs, 0, 0) ...</k>
    (. => <aggregate>... <agg-id> union X </agg-id> ...</aggregate>)
       
  rule declUnion(_, (VD:VarDecl VDs:VarDecls => VD ~> VDs), _, _) 
    [structural]
  rule declUnion(_, (.VarDecls => .), _, _) 
    [structural]

  rule 
     <k> declUnion(X:CId, TS:TypeSpec D:Declarator; ~> VDs:VarDecls, Size:TypedValue, Pos:Int)
     => declUnion(X, VDs, maxK(Size, sizeof'(normType(TS D))), Pos +Int 1) ...</k>
     <agg-id> union X </agg-id>
     <fields>...
        (. => <field>...
          <field-id> getId(D) </field-id>
          <field-pos> Pos </field-pos>
          <field-type> normType(TS D) </field-type>
          <offset> 0 </offset>
        ...</field>)
     ...</fields>
    [structural]
     
  rule 
     <k> declUnion(X:CId, .K, Size:TypedValue, _) => . ...</k>
     <agg-id> union X </agg-id>
     <size> _ => mival(Size) </size>
    [structural]

endmodule
