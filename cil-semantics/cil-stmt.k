require "cil-common.k"
require "cil-decl.k"


module CIL-STMT
  imports CIL-COMMON
  imports CIL-DECL

  rule { VDs:VarDecls B:Block } => VDs ~> B   [structural]

  rule
    <k> goto L:Label; ~> _ => Ss </k>
    <frame-fun-id> F:CId </frame-fun-id>
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

  rule { Stmts } => Stmts   [structural]
  rule S:Stmt Ss:Stmts => S ~> Ss   [structural]
  rule .Stmts => .K    [structural]
  rule ; => .K    [structural]

  rule L:Label : S:Stmt => S    [structural]


  /*
   * Function call/return (function pointers not supported yet).
   */
  /*TODO: support return for void functions and void functions without return. */
  rule
    (
      <frame>
        <k> F:CId(TVs:TypedValues) ~> K:K </k>
        Cells:Bag
      </frame>
    =>
      <frame>...
        <k> initializeParams(Ps, TVs) ~> FB </k>
        <frame-fun-id> F </frame-fun-id>
      ...</frame>
    )
    <frame-stack>...
      .List => ListItem(<frame> <k> K </k> Cells </frame>)
    </frame-stack>
    <fun>...
      <fun-id> F </fun-id>
      <formals> Ps:Params </formals>
      <body> FB:FunBody </body>
    ...</fun>
  [computational]
  rule
    (
      <frame>...
        <k> return tv(T:Type, V:Value); ...</k>
        <frame-fun-id> F:CId </frame-fun-id>
        <env> Env:Map </env>
      ...</frame>
    =>
      <frame>
        <k> deleteLocals(values(Env)) ~> tv(T, V) ~> K:K </k>
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
  syntax K ::= initializeParams(Params, TypedValues)
             | deleteLocals(Set)
  rule
    initializeParams(
        ((T:Type X:CId), Ps:Params),
        (TV:TypedValue, TVs:TypedValues))
  =>
    T X; ~> X = TV; ~> initializeParams(Ps, TVs)
  [structural]
  rule initializeParams(.Params, .TypedValues) => .K   [structural]
  rule
    deleteLocals(SetItem(P:Ptr) S:Set) => deleteObject(P) ~> deleteLocals(S)
  [structural]
  rule deleteLocals(.Set) => .K   [structural] 
endmodule

