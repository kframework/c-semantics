module C-ELABORATOR-SYNTAX
     imports C-SYNTAX

     syntax KItem ::= elaborate(K)
     syntax KItem ::= elaborate(K, K)

     syntax KItem ::= elaborateDone(K)
     syntax KItem ::= elaborateDone(K, K)

     // Elaboration for initializers -- copies up the environment.
     syntax KItem ::= elaborateInit(K)
     syntax KItem ::= elaborateInitDone(K)

     syntax KItem ::= typeof(K) [strict]

     syntax KItem ::= runInit(K)
endmodule

module C-ELABORATOR
     imports C-ELABORATOR-SYNTAX

     imports C-DYNAMIC-SYNTAX

     syntax KItem ::= elabFrame(K, K, Bag)
                    | elabInitFrame(K, K, Int)
                    | runInitFrame(K, K, Int)

     rule (.K => K) ~> compoundExp(K:K)
     rule R:KResult ~> compoundExp(K:K)
          => te(compoundExp(K), type(R))

     rule <k> elaborate(K:K) ~> Cont:K => K </k>
          <elab> OldElab:K => .K </elab>
          <local> L:Bag </local>
          <elabStack>
               .List => ListItem(elabFrame(Cont, OldElab, L))
          ...</elabStack>
     rule <k> .K => elaborateDone(K) ~> Cont </k>
          <elab> K:K => OldElab </elab>
          <local> _ => L </local>
          <elabStack>
               ListItem(elabFrame(Cont:K, OldElab:K, L:Bag)) => .List
          ...</elabStack>

     rule <k> elaborateInit(K:K) ~> Cont:K => K </k>
          <elab> OldElab:K => .K </elab>
          <initializing> I:Int => 1 </initializing>
          <elabStack>
               .List => ListItem(elabInitFrame(Cont, OldElab, I))
          ...</elabStack>
     rule <k> .K => elaborateInitDone(K) ~> Cont </k>
          <elab> K:K => OldElab </elab>
          <initializing> _ => I </initializing>
          <elabStack>
               ListItem(elabInitFrame(Cont:K, OldElab:K, I:Int)) => .List
          ...</elabStack>

     rule <k> runInit(K:K) ~> Cont:K => K </k>
          <elab> OldElab:K => .K </elab>
          <initializing> I:Int => 1 </initializing>
          <elabStack>
               .List => ListItem(runInitFrame(Cont, OldElab, I))
          ...</elabStack>
     rule <k> .K => Cont </k>
          <elab> _ => OldElab </elab>
          <initializing> _ => I </initializing>
          <elabStack>
               ListItem(runInitFrame(Cont:K, OldElab:K, I:Int)) => .List
          ...</elabStack>

     rule elaborate(K1:K, K2:K) => elaborate(K1) ~> elaborate(K2)
     rule elaborateDone(K1:K) ~> elaborate(K2:K)
          => elaborate(K2) ~> elaborateDone(K1)
     rule elaborateDone(K2:K) ~> elaborateDone(K1:K)
          => elaborateDone(K1:K, K2:K)

     rule typeof(V:KResult) => type(V)

endmodule
