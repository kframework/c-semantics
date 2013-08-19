// vim: set ts=2 sw=2:
require "cil-common.k"
require "cil-decl.k"

module CIL-STMT
  imports CIL-COMMON
  imports CIL-DECL
  imports CIL-EXP

  rule { VDs:VarDecls B:Block } => VDs ~> B   [structural]

  context goto $caseLabel(_, HOLE) ;
  rule
    <k> goto L:Label; ~> _ => Ss </k>
    <frame-fun-id> F:Ptr </frame-fun-id>
    <fun>...
      <fun-id> F </fun-id>
      <labels>... L |-> Ss:Stmts ...</labels>
    ...</fun>
  [computational]

  rule <k> (. => eval-case-labels)
    ~> goto $caseLabel(_, _) ; 
    ...</k>
    <frame-fun-id> F:Ptr </frame-fun-id>
    <fun-id> F </fun-id>
    <labels-evaluated> false </labels-evaluated>
  [structural]

  rule <k> goto $caseLabel(I:Int, V:TypedValue) ;
    => goto $defaultLabel(I) ; ...</k>
    <frame-fun-id> F:Ptr </frame-fun-id>
    <fun-id> F </fun-id>
    <labels> Lbls:Map </labels>
    <labels-evaluated> true </labels-evaluated>
    when notBool ($caseLabel(I, V) in keys Lbls)
  [structural]

  // This is a somewhat hackish method for evaluating the constant expressions
  // in the case labels of switch statements. It seems to slow things down
  // quite a bit too.
  syntax K ::= "eval-case-labels"
             | "eval-case-labels" "(" Map "," Map ")"
             | "case-label-freezer" "(" Int "," Stmts ")"
  rule <k> eval-case-labels => . ...</k>
    <frame-fun-id> F:Ptr </frame-fun-id>
    <fun-id> F </fun-id>
    <labels-evaluated> true </labels-evaluated>
  rule <k> eval-case-labels => eval-case-labels(Lbls, .Map) ...</k>
    <frame-fun-id> F:Ptr </frame-fun-id>
    <fun-id> F </fun-id>
    <labels> Lbls:Map </labels>
    <labels-evaluated> false </labels-evaluated>

  rule eval-case-labels(
    _:Map (L:Label |-> Ss:Stmts => .Map), 
    _:Map (.Map => L |-> Ss)) 
    when getKLabel(L) =/=KLabel '$caseLabel
    [structural]
  rule (. => E ~> case-label-freezer(I, Ss)) 
    ~> eval-case-labels(
      _:Map ($caseLabel(I:Int, E:Exp) |-> Ss:Stmts => .Map), _:Map) 
    [structural]
  rule (E:KResult ~> case-label-freezer(I:Int, Ss:Stmts) => .)
    ~> eval-case-labels(
      _:Map, _:Map (.Map => $caseLabel(I, E) |-> Ss))
    [structural]

  rule <k> eval-case-labels(.Map, Lbls:Map) => . ...</k>
    <frame-fun-id> F:Ptr </frame-fun-id>
    <fun-id> F </fun-id>
    <labels> _ => Lbls </labels>
    <labels-evaluated> false => true </labels-evaluated>
    [structural]

  syntax K ::= "$exp2bool" "(" Exp ")"    [strict]
  rule if (E:Exp) S1:Stmt else S2:Stmt
    => $exp2bool(E) ~> if (HOLE) S1 else S2
  [heat]
  rule $exp2bool(tv(_:IntType, MI:MInt))
    => norm(int, notBool isZero(MI))
  [structural]
  rule $exp2bool(tv(_, Null))
    => norm(int, false)
  [structural]
  rule $exp2bool(tv(_, P:Ptr))
    => norm(int, true)
    when P =/=K Null
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
    $bool-ctx(norm(int, notBool isZero(MI)))
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
     <k> callMain => main(0, (char**) 0) </k>
     <env> _ => GEnv </env>
     <global-env> GEnv:Map </global-env>
     <phase> _ => executing </phase>
     [structural]

  context (HOLE => HOLE ~> noLeftValueConversion)(_:Exps)
  rule
    (
      <frame>
        <k> (nclv(_, FunPtr(F:CId, Tu:TransUnit)))(TVs:TypedValues) ~> K:K </k>
        Cells:Bag
      </frame>
    =>
      <frame>...
        <k> initializeParams(Ps, TVs) ~> FB </k>
        <frame-fun-id> FunPtr(F, Tu) </frame-fun-id>
        //TODO(chathhorn): does this work right?
        <env> GEnv TuEnv </env>
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
    <tu>...
      <tu-id> Tu </tu-id>
      <tu-env> TuEnv:Map </tu-env>
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
        <k> tv(void, undef) ~> K:K </k>
        Cells:Bag
      </frame>
    )
    <frame-stack>...
       ListItem(<frame> <k> K </k> Cells </frame>) => .List
    </frame-stack>   
    <fun>...
      <fun-id> F </fun-id>
      <fun-type> void </fun-type>
    ...</fun>
  [computational]

  syntax Stmt ::= TypedValue ";"
  rule tv(void, undef) ; => .

  rule 
    (<frame>...
    <k> tv(int, I:MInt) </k>
    <frame-fun-id> Null </frame-fun-id>
    ...</frame> 
    => <result-value> iMInt(I) </result-value>)
    <phase> _ => terminated </phase>
  [structural]

  syntax K ::= initializeParams(Params, TypedValues)
             | deleteLocals(Set)
  rule
    initializeParams(
        ((DS:DeclSpecs D:Declarator), Ps:Params),
        (TV:TypedValue, TVs:TypedValues))
  =>
    DS D; ~> getId(D) = TV; ~> initializeParams(Ps, TVs)
  [structural]
  // TODO(chathhorn): we allow more arguments to be passed to a function than
  // that function has formal parameters just to make calling main easier.
  rule initializeParams(.Params, _:TypedValues) => .K   [structural]
  // TODO(chathhorn): could probably be handled better.
  rule initializeParams((void, .Params), _:TypedValues) => .K   [structural]

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

