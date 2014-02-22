// vim: set ts=2 sw=2:
require "builtins/list.k"
require "builtins/map.k"
require "builtins/set.k"

require "cil-common.k"
require "cil-decl.k"
require "cil-exp.k"

module CIL-STMT
  imports LIST
  imports MAP
  imports SET
  imports CIL-COMMON
  imports CIL-DECL
  imports CIL-EXP

  rule { VDs:VarDecls B:Block } => VDs ~> B   [structural]

  syntax Type ::= typeof(Exp) [strict]
  rule typeof(tv(T:Type, _)) => T

  context goto $caseLabel(_, HOLE) ;
  rule
    <k> goto L:Label; ~> _ => Ss </k>
    <frame-fun-id> F:Ptr </frame-fun-id>
    <fun-id> F </fun-id>
    <labels>... L |-> Ss:Stmts ...</labels>
  [computational]

  rule 
    // TODO(AndreiS): fix implementation of case labels
    // <k> (. => make-goto-table ~> eval-case-labels) ~> goto _:Label ; ...</k>
    <k> (. => make-goto-table) ~> goto _:Label ; ...</k>
    <frame-fun-id> F:Ptr </frame-fun-id>
    <fun-id> F </fun-id>
    <labels-generated> false => true </labels-generated>
  [structural]

  rule <k> goto $caseLabel(I:Int, V:TypedValue) ;
    => goto $defaultLabel(I) ; ...</k>
    <frame-fun-id> F:Ptr </frame-fun-id>
    <fun-id> F </fun-id>
    <labels> Lbls:MyMap </labels>
    <labels-generated> true </labels-generated>
    when notBool ($caseLabel(I, V) in keys(Lbls))
  [structural]

  /*
   * Compute the goto table (Map{Label, Stmt}). We do this at "runtime" to
   * improve the performance of the interpreter.
   */
  syntax KItem ::= "make-goto-table"
  rule
    <k> make-goto-table ...</k>
    <frame-fun-id> F:Ptr </frame-fun-id>
    <fun-id> F </fun-id>
    <body> { _:VarDecls { Ss:Stmts } } </body>
    <make-goto-table-enabled> false => true </make-goto-table-enabled>
    <make-goto-table-tasks>
      (.Bag => 
        <make-goto-table-task>
          <make-goto-table-stmts> Ss </make-goto-table-stmts>
          <make-goto-table-cont> .Stmts </make-goto-table-cont>
        </make-goto-table-task>
      )
    </make-goto-table-tasks>
  [structural]
  rule
    <make-goto-table-tasks>...
      <make-goto-table-task>...
        <make-goto-table-stmts> .Stmts </make-goto-table-stmts>
      ...</make-goto-table-task>
      => .Bag
    ...</make-goto-table-tasks>
  [structural]
  rule
    <k> make-goto-table => . ...</k>
    <make-goto-table-enabled> true => false </make-goto-table-enabled>
    <make-goto-table-tasks> .Bag </make-goto-table-tasks>
  [structural]

  rule
    <frame-fun-id> F:Ptr </frame-fun-id>
    <fun-id> F </fun-id>
    <labels>... .MyMap => L |-> (S Ss1) @Stmts Cont ...</labels>
    <make-goto-table-task>
      <make-goto-table-stmts>
        L:Label : S:Stmt Ss1:Stmts => S Ss1
      </make-goto-table-stmts>
      <make-goto-table-cont>
        Cont:Stmts
      </make-goto-table-cont>
    </make-goto-table-task>
  [structural]

  rule
    <make-goto-table-tasks>...
      <make-goto-table-task>
        <make-goto-table-stmts>
          (if ( _ ) S1:Stmt else S2:Stmt) Ss:Stmts => Ss
        </make-goto-table-stmts>
        <make-goto-table-cont> 
          Cont:Stmts
        </make-goto-table-cont>
      </make-goto-table-task>
      (.Bag =>
        <make-goto-table-task>
          <make-goto-table-stmts> S1 (.Stmts) </make-goto-table-stmts>
          <make-goto-table-cont> Ss @Stmts Cont </make-goto-table-cont>
        </make-goto-table-task>
        <make-goto-table-task>
          <make-goto-table-stmts> S2 (.Stmts) </make-goto-table-stmts>
          <make-goto-table-cont> Ss @Stmts Cont </make-goto-table-cont>
        </make-goto-table-task>
      )
    ...</make-goto-table-tasks>
  [structural]
  rule
    <make-goto-table-tasks>...
      <make-goto-table-task>
        <make-goto-table-stmts>
          while (E:Exp) S:Stmt Ss:Stmts => Ss
        </make-goto-table-stmts>
        <make-goto-table-cont>
          Cont:Stmts
        </make-goto-table-cont>
      </make-goto-table-task>
      (.Bag =>
        <make-goto-table-task>
          <make-goto-table-stmts> S (.Stmts) </make-goto-table-stmts>
          <make-goto-table-cont>
            (while (E) S Ss) @Stmts Cont
          </make-goto-table-cont>
        </make-goto-table-task>
      )
    ...</make-goto-table-tasks>
  [structural]
  rule
    <make-goto-table-stmts>
      { Ss1:Stmts } Ss2:Stmts => Ss1 @Stmts Ss2
    </make-goto-table-stmts>
  [structural]
  rule
    <make-goto-table-stmts>
      S:Stmt Ss:Stmts => Ss
    </make-goto-table-stmts>
  when getKLabel(S) =/=KLabel '_:_ 
    andBool getKLabel(S) =/=KLabel 'if`(_`)_else_ 
    andBool getKLabel(S) =/=KLabel 'while`(_`)_ 
    andBool getKLabel(S) =/=KLabel '`{_`}
  [structural]

  // This is a somewhat hackish method for evaluating the constant expressions
  // in the case labels of switch statements. It seems to slow things down
  // quite a bit too.
  syntax KItem ::= "eval-case-labels"
                 | "eval-case-labels" "(" MyMap "," MyMap ")"
                 | "case-label-freezer" "(" Int "," Stmts ")"

  rule <k> eval-case-labels => eval-case-labels(Lbls, .MyMap) ...</k>
    <frame-fun-id> F:Ptr </frame-fun-id>
    <fun-id> F </fun-id>
    <labels> Lbls:MyMap </labels>

  // TODO(AndreiS): fix getKLabel
//  rule eval-case-labels(
//    (_:MyMap, (L:Label |-> Ss:Stmts => .MyMap)), 
//    (_:MyMap, (.MyMap => L |-> Ss)))
//    when getKLabel(L) =/=KLabel '$caseLabel
//    [structural]
  rule (. => (E ~> case-label-freezer(I, Ss))) 
    ~> eval-case-labels(
      (_:MyMap, ($caseLabel(I:Int, E:Exp) |-> Ss:Stmts => .MyMap)), _:MyMap) 
    [structural]
  rule (E:KResult ~> case-label-freezer(I:Int, Ss:Stmts) => .)
    ~> eval-case-labels(
      _:MyMap, (_:MyMap, (.MyMap => $caseLabel(I, E) |-> Ss)))
    [structural]

  rule <k> eval-case-labels(.MyMap, Lbls:MyMap) => . ...</k>
    <frame-fun-id> F:Ptr </frame-fun-id>
    <fun-id> F </fun-id>
    <labels> _ => Lbls </labels>
    [structural]

  rule if (E:Exp) S1:Stmt else S2:Stmt
    => $exp2bool(E) ~> if (HOLE) S1 else S2
  [heat]
  rule
    TV:TypedValue ~> if (HOLE) S1:Stmt else S2:Stmt => if (TV) S1 else S2
  [cool]

  rule if (tv(_, mi(_, 1))) S:Stmt else _:Stmt => S   [computational]
  rule if (tv(_, mi(_, 0))) _:Stmt else S:Stmt => S   [computational]
  
  rule while(E:Exp) S:Stmt => if (E) { S while(E) S }   [structural]

  rule { Stmts:Stmts } => Stmts   [structural]
  rule S:Stmt Ss:Stmts => S ~> Ss   [structural]
  rule .Stmts => .K    [structural]
  rule ; => .K    [structural]

  rule _:Label : S:Stmt => S    [structural]

  /*
   * Function call/return
   */
  rule 
     <k> callMain => main(0, (char**) 0) </k>
     <env> _ => GEnv </env>
     <global-env> GEnv:MyMap </global-env>
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
        <env> GEnv, TuEnv </env>
      ...</frame>
    )
    // TODO(AndreiS): rename k cell to prevent failed attempts at rewriting
    // inside stacked k
    <frame-stack>...
      . => <stacked-frame> <k> K </k> Cells </stacked-frame>
    </frame-stack>
    <fun>...
      <fun-id> FunPtr(F, Tu) </fun-id>
      <formals> Ps:Params </formals>
      <body> FB:FunBody </body>
    ...</fun>
    <global-env> GEnv:MyMap </global-env>
    <tu>...
      <tu-id> Tu </tu-id>
      <tu-env> TuEnv:MyMap </tu-env>
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
        <k> tv(T, V) ~> K:K </k> // TODO(AndreiS): deleteLocals
        Cells:Bag
      </frame>
    )
    <frame-stack>...
      <stacked-frame> <k> K </k> Cells </stacked-frame> => .
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
      <stacked-frame> <k> K </k> Cells </stacked-frame> => .
    </frame-stack>   
    <fun>...
      <fun-id> F </fun-id>
      <fun-type> void </fun-type>
    ...</fun>
  [computational]

  syntax Stmt ::= TypedValue ";"
  rule tv(_, _) ; => .

  rule 
    (<frame>...
    <k> tv(int, I:MInt) </k>
    <frame-fun-id> Null </frame-fun-id>
    ...</frame> 
    => <result-value> iMInt(I) </result-value>)
    <phase> _ => terminated </phase>
  [structural]

  syntax KItem ::= initializeParams(Params, TypedValues)
                 | deleteLocals(MySet)
  rule
    initializeParams(
        ((DS:DeclSpecs D:Declarator), Ps:Params),
        (TV:TypedValue, TVs:TypedValues))
  =>
    (DS D;) ~> (getId(D) = TV;) ~> initializeParams(Ps, TVs)
  [structural]

  rule initializeParams(.Params, TVs:TypedValues) => .

  rule <k> initializeParams(( ... ), TVs:TypedValues) => . ...</k>   
    <frame-fun-va-args> _ => TVs </frame-fun-va-args>
    [structural]

  // TODO(chathhorn): could probably be handled better.
  rule initializeParams((void, .Params), _:TypedValues) => .K   [structural]

  // TODO(chathhorn): delete stuff.
  // rule
  //   deleteLocals(MySetItem(P:Ptr) S:MySet) => deleteObject(P) ~> deleteLocals(S)
  // [structural]
  // rule deleteLocals(.MySet) => .K   [structural] 

  rule 
    <k> # pragma KCIL_TU Filename:String => . ...</k>
    <tus>...
      (. => <tu>... <tu-id> tu(Filename) </tu-id> ...</tu>)
    ...</tus>
    <phase> _ => tu(Filename) </phase>
    [structural]

endmodule

