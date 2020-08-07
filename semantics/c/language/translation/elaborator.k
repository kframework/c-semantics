module C-ELABORATOR-SYNTAX
     imports BASIC-K
     imports C-ABSTRACT-SORTS

     syntax KItem ::= elaborate(K) [klabel(elaborate1)]
     syntax KItem ::= elaborate(K, K)
     syntax KItem ::= elaboratePostponed(K, K)

     syntax KItem ::= elaborateDone(K)  [klabel(elaborateDone1)]
     syntax KItem ::= elaborateDone(K, K)

     // Elaboration for initializers -- copies up the environment.
     syntax KItem ::= elaborateInit(K)

     // Converts nclv back to lv, so lvalues are re-evaluated during execution.
     syntax KItem ::= nclvToLV(Nclv) [function]
endmodule

module C-ELABORATOR
     imports C-ELABORATOR-SYNTAX
     imports C-CONFIGURATION
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     syntax KItem ::= elabFrame(K, K)
                    | elabInitFrame(K, K, K)

     rule (.K => K) ~> compoundExp(K:K)
     rule R:KResult ~> compoundExp(K:K)
          => te(compoundExp(K), utype(R))
     rule toRVal(R:RValue) ~> compoundExp(K:K)
          => te(compoundExp(K), utype(R))

     rule <k> elaborate(K:K) ~> Cont:K => K </k>
          <elab> OldElab:K => .K </elab>
          <elab-stack>
               .List => ListItem(elabFrame(Cont, OldElab))
          ...</elab-stack>
     rule <k> .K => elaborateDone(K) ~> Cont </k>
          <elab> K:K => OldElab </elab>
          <elab-stack>
               ListItem(elabFrame(Cont:K, OldElab:K)) => .List
          ...</elab-stack>

     rule <k> elaborateInit(K:K) ~> Cont:K => K </k>
          <elab> OldElab:K => .K </elab>
          (I:InitCalcCell
               => <init-calc>... .Bag ...</init-calc>)
          <elab-stack>
               .List => ListItem(elabInitFrame(Cont, OldElab, I))
          ...</elab-stack>
     rule <k> .K => elaborateDone(K) ~> Cont </k>
          <elab> K:K => OldElab </elab>
          (_:InitCalcCell => I)
          <elab-stack>
               ListItem(elabInitFrame(Cont:K, OldElab:K, I:InitCalcCell)) => .List
          ...</elab-stack>

     rule elaborate(K1:K, K2:K) => elaborate(K1) ~> elaborate(K2)
     rule elaborateDone(K1:K) ~> elaborate(K2:K)
          => elaborate(K2) ~> elaborateDone(K1)
     rule elaborateDone(K2:K) ~> elaborateDone(K1:K)
          => elaborateDone(K1:K, K2:K)

     rule nclvToLV(nclv(Loc::SymLoc, T::Type)) => lv(Loc, T)
     rule nclvToLV(ncle(K:KItem, _)) => K

endmodule
