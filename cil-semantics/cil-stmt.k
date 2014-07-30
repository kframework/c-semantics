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
    <k> (. => make-goto-table ~> eval-case-labels) ~> goto _:Label ; ...</k>
    <frame-fun-id> F:Ptr </frame-fun-id>
    <fun-id> F </fun-id>
    <labels-generated> false => true </labels-generated>
  [structural]

  rule <k> goto $caseLabel(I:Int, V:TypedValue) ;
    => goto $defaultLabel(I) ; ...</k>
    <frame-fun-id> F:Ptr </frame-fun-id>
    <fun-id> F </fun-id>
    <labels> Lbls:Map </labels>
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
    <labels>... .Map => L |-> (S Ss1) @Stmts Cont ...</labels>
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
                 | "eval-case-labels0"
                 | "eval-case-label" "(" Label "," Stmts ")"

  rule <k> eval-case-labels => eval-case-labels0 ...</k>
    <frame-fun-id> F:Ptr </frame-fun-id>
    <fun-id> F </fun-id>
    <labels> Lbls:Map => .Map </labels>
    <make-case-labels> .Map => Lbls </make-case-labels>
  rule <k> eval-case-labels0 => .K ...</k>
    <make-case-labels> .Map </make-case-labels>
    [structural]

  // TODO(AndreiS): eval-case-labels mentioned for better indexing
  rule
    <k> (.K => eval-case-label(L, Ss)) ~> eval-case-labels0 ...</k>
    <make-case-labels>... L:Label |-> Ss:Stmts => .Map ...</make-case-labels>
  rule
    <k> eval-case-label(L:Label, Ss:Stmts) => .K ...</k>
    <frame-fun-id> F:Ptr </frame-fun-id>
    <fun-id> F </fun-id>
    <labels>... .Map => L |-> Ss ...</labels>
    when getKLabel(L) =/=KLabel '$caseLabel
    [structural]
  context eval-case-label($caseLabel(_:Int, HOLE:>Exp), _:Stmts)
  rule
    <k> eval-case-label($caseLabel(I:Int, E:KResult), Ss:Stmts) => .K ...</k>
    <frame-fun-id> F:Ptr </frame-fun-id>
    <fun-id> F </fun-id>
    <labels>... .Map => $caseLabel(I, E) |-> Ss ...</labels>
    [structural]


  rule if (E:Exp) S1:Stmt else S2:Stmt
    => $exp2bool(E) ~> if (HOLE) S1 else S2
    [heat]
  rule
    TV:TypedValue ~> if (HOLE) S1:Stmt else S2:Stmt => if (TV) S1 else S2
    [cool]

  rule if (tv(_, MI:MInt)) S:Stmt else _:Stmt => S
  when uvalueMInt(MI) ==K 1
  [computational]
  rule if (tv(_, MI:MInt)) _:Stmt else S:Stmt => S
  when uvalueMInt(MI) ==K 0
  [computational]
  
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
        <env> GEnv TuEnv </env>
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
        <locals> S:Set </locals>
        <frame-fun-id> F:Ptr </frame-fun-id>
      ...</frame>
    =>
      <frame>
        <k> deleteLocals(S) ~> tv(T, V) ~> K </k>
        Cells
      </frame>
    )
    <frame-stack>...
      <stacked-frame> <k> K:K </k> Cells:Bag </stacked-frame> => .
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
    => <result-value> ###result-value(uvalueMInt(I)) </result-value>)
    <phase> _ => terminated </phase>
  [structural]

  syntax KItem ::= initializeParams(Params, TypedValues)
                 | deleteLocals(Set)
  rule
    initializeParams(
        ((DS:DeclSpecs D:Declarator), Ps:Params),
        (TV:TypedValue, TVs:TypedValues))
  =>
    (DS D;) ~> (getId(D) = TV;) ~> initializeParams(Ps, TVs)
  [structural]

  //rule initializeParams(.Params, .TypedValues) => .   [structural]
  rule initializeParams(.Params, _:TypedValues) => .   [structural]

  rule <k> initializeParams(( ... ), TVs:TypedValues) => . ...</k>   
    <frame-fun-va-args> _ => TVs </frame-fun-va-args>
    [structural]

  // TODO(chathhorn): could probably be handled better.
  //rule initializeParams(((void, .Params) => .Params), _:TypedValues)
  //  [structural]
  rule initializeParams((void, .Params), _:TypedValues) => .    [structural]

  rule
    deleteLocals(SetItem(P:Ptr) S:Set)
  =>
    deleteObject(P) ~> deleteLocals(S)
  [structural]
  rule deleteLocals(.Set) => .K   [structural] 

  rule 
    <k> # pragma KCIL_TU Filename:String => . ...</k>
    <tus>...
      (. => <tu>... <tu-id> tu(Filename) </tu-id> ...</tu>)
    ...</tus>
    <phase> _ => tu(Filename) </phase>
    [structural]

endmodule

