module C-ELABORATOR-SYNTAX
     imports C-SYNTAX

     syntax KItem ::= elaborate(K)
     syntax KItem ::= elaborate(K, K)

     syntax KItem ::= elaborateDone(K)
     syntax KItem ::= elaborateDone(K, K)

     // Elaboration for initializers -- copies up the environment.
     syntax KItem ::= elaborateInit(K)
     syntax KItem ::= elaborateInitDone(K)

     syntax KItem ::= elabExp(K)
endmodule

module C-ELABORATOR
     imports C-ELABORATOR-SYNTAX

     imports C-DYNAMIC-SYNTAX

     syntax KItem ::= waitingOn(CId)
     syntax CId ::= subElab(Int)
     syntax CId ::= initElab(Int)

     context elabExp((HOLE => reval(HOLE))) [result(RValue)]

     rule (.K => K) ~> compoundExp(K:K)
     rule R:KResult ~> compoundExp(K:K)
          => te(compoundExp(K), type(R))

     rule <k> elaborate(K:K) => waitingOn(subElab(!E:Int)) ...</k>
          <local> L:Bag </local>
          (.Bag => <elaborator>...
               <elab-id> subElab(!E) </elab-id>
               <k> K </k>
               <local> L </local>
          ...</elaborator>)
     rule <k> waitingOn(subElab(E:Int)) => elaborateDone(K:K) ...</k>
          (<elaborator>...
               <elab-id> subElab(E) </elab-id>
               <k> .K </k>
               <elab> K:K </elab>
          ...</elaborator> => .Bag)
     rule <k> elaborateInit(K:K) => waitingOn(initElab(!E:Int)) ...</k>
          <local> L:Bag </local>
          (.Bag => <elaborator>...
               <elab-id> initElab(!E) </elab-id>
               <k> K </k>
               <local> L </local>
          ...</elaborator>)
     rule <k> waitingOn(initElab(E:Int)) => elaborateInitDone(K:K) ...</k>
          <local> _ => L </local>
          (<elaborator>...
               <elab-id> initElab(E) </elab-id>
               <k> .K </k>
               <elab> K:K </elab>
               <local> L:Bag </local>
          ...</elaborator> => .Bag)


     syntax KItem ::= waitingOn(CId, CId)

     rule <k> elaborate(K1:K, K2:K)
               => waitingOn(subElab(!E1:Int), subElab(!E2:Int)) ...</k>
          <local> L:Bag </local>
          (.Bag => <elaborator>...
               <elab-id> subElab(!E1) </elab-id>
               <k> K1 </k>
               <local> L </local>
          ...</elaborator>)
          (.Bag => <elaborator>...
               <elab-id> subElab(!E2) </elab-id>
               <k> K2 </k>
               <local> L </local>
          ...</elaborator>)
     rule <k> waitingOn(E1:CId, E2:CId) => elaborateDone(K1:K, K2:K) ...</k>
          (<elaborator>...
               <elab-id> E1 </elab-id>
               <k> .K </k>
               <elab> K1:K </elab>
          ...</elaborator> => .Bag)
          (<elaborator>...
               <elab-id> E2 </elab-id>
               <k> .K </k>
               <elab> K2:K </elab>
          ...</elaborator> => .Bag)

endmodule
