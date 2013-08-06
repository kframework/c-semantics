// vim: set ts=2 sw=2:
require "cil-common.k"
require "cil-decl.k"

module CIL-STMT
  imports CIL-COMMON
  imports CIL-DECL
  imports CIL-EXP

  rule { VDs:VarDecls B:Block } => VDs ~> B   [structural]

  rule
    <k> goto L:Label; ~> _ => Ss </k>
    <frame-fun-id> F:Ptr </frame-fun-id>
    <fun>...
      <fun-id> F </fun-id>
      <labels>... L |-> Ss:Stmts ...</labels>
    ...</fun>
  [computational]

  syntax K ::= "$exp2bool" "(" Exp ")"    [strict]
  rule
    if (E:Exp) S1:Stmt else S2:Stmt
  =>
    $exp2bool(E) ~> if (HOLE) S1 else S2
  [heat]
  rule
    $exp2bool(tv(_:IntType, MI:MInt))
  =>
    bool2mint(notBool isZero(MI))
  [structural]
  rule
    TV:TypedValue ~> if (HOLE) S1:Stmt else S2:Stmt => if (TV) S1 else S2
  [cool]

  //syntax K ::= "$bool-ctx" "(" K ")"
  //rule $bool-ctx(K:K) => K ~> $bool-ctx(HOLE) [heat]
  //rule MI:MInt ~> $bool-ctx(HOLE) => $bool-ctx(MI) [cool]
/*
  rule
    tv(_:IntType, MI:MInt) ~> $bool-ctx(HOLE)
  =>
    $bool-ctx(bool2mint(notBool isZero(MI)))
  [cool]
*/

  rule if (tv(_, mi(_, 1))) S:Stmt else _:Stmt => S   [computational]
  rule if (tv(_, mi(_, 0))) _:Stmt else S:Stmt => S   [computational]
  
  // TODO: switch

  rule while(E:Exp) S:Stmt => if (E) { S while(E) S }   [structural]

  rule { Stmts:Stmts } => Stmts   [structural]
  rule S:Stmt Ss:Stmts => S ~> Ss   [structural]
  rule .Stmts => .K    [structural]
  rule ; => .K    [structural]

  rule _:Label : S:Stmt => S    [structural]

  /*
   * Function call/return
   */
  syntax K ::= "callMain"
  rule 
     <k> callMain => main(.Exps) </k>
     <env> _ => GEnv </env>
     <global-env> GEnv:Map </global-env>
     <phase> _ => executing </phase>
     [structural]

  context (HOLE => HOLE ~> noLeftValueConversion)(_:Exps)
  rule
    (
      <frame>
        <k> (nclv(FunType, FunPtr(F:CId, Tu:TransUnit)))(TVs:TypedValues) ~> K:K </k>
        Cells:Bag
      </frame>
    =>
      <frame>...
        <k> initializeParams(Ps, TVs) ~> FB </k>
        <frame-fun-id> FunPtr(F, Tu) </frame-fun-id>
        //TODO(chathhorn): does this work right?
        <env> GEnv TuEnv </env>
        <type-env> GTypeEnv TuTypeEnv </type-env>
      ...</frame>
    )
    <frame-stack>...
      .List => ListItem(<frame> <k> K </k> Cells </frame>)
    </frame-stack>
    <fun>...
      <fun-id> FunPtr(F, Tu) </fun-id>
      <formals> Ps:Params </formals>
      <body> FB:FunBody </body>
    ...</fun>
    <global-env> GEnv:Map </global-env>
    <global-type-env> GTypeEnv:Map </global-type-env>
    <tu>...
      <tu-id> Tu </tu-id>
      <tu-env> TuEnv:Map </tu-env>
      <tu-type-env> TuTypeEnv:Map </tu-type-env>
    ...</tu>
  [computational]
  rule
    (
      <frame>...
        <k> return (tv(T:Type, V:Value)); ...</k>
        <frame-fun-id> F:Ptr </frame-fun-id>
      ...</frame>
    =>
      <frame>
        <k> tv(T, V) ~> K:K </k> // TODO: deleteLocals
        Cells:Bag
      </frame>
    )
    <frame-stack>...
       ListItem(<frame> <k> K </k> Cells </frame>) => .List
    </frame-stack>   
    <fun>...
      <fun-id> F </fun-id>
      <fun-type> T </fun-type>
    ...</fun>
  [computational]
  rule
    (
      <frame>...
        <k> return ; ...</k>
        <frame-fun-id> F:Ptr </frame-fun-id>
      ...</frame>
    =>
      <frame>
        <k> K:K </k>
        Cells:Bag
      </frame>
    )
    <frame-stack>...
       ListItem(<frame> <k> K </k> Cells </frame>) => .List
    </frame-stack>   
    <fun>...
      <fun-id> F </fun-id>
      <fun-type> T </fun-type>
    ...</fun>
  [computational]

  rule 
    (<frame>...
    <k> tv(int, mi(_, I:Int)) </k>
    <frame-fun-id> Null </frame-fun-id>
    ...</frame> 
    => <resultValue> I </resultValue>)
    <phase> _ => terminated </phase>
  [structural]

  syntax K ::= initializeParams(Params, TypedValues)
             | deleteLocals(Set)
  // TODO(chathhorn): POINTERS
  rule
    initializeParams(
        ((TS:TypeSpec X:CId), Ps:Params),
        (TV:TypedValue, TVs:TypedValues))
  =>
    TS X; ~> X = TV; ~> initializeParams(Ps, TVs)
  [structural]
  rule initializeParams(.Params, .TypedValues) => .K   [structural]

  // rule
  //   deleteLocals(SetItem(P:Ptr) S:Set) => deleteObject(P) ~> deleteLocals(S)
  // [structural]
  // rule deleteLocals(.Set) => .K   [structural] 

  rule 
    <k> # pragma KCIL_TU Filename:String => . ...</k>
    <tus>...
      (. => <tu>... <tu-id> tu(Filename) </tu-id> ...</tu>)
    ...</tus>
    <phase> _ => tu(Filename) </phase>
    [structural]

endmodule

