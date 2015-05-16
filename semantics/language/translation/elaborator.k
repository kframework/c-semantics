module C-ELABORATOR-SYNTAX
     imports C-SYNTAX

     syntax KItem ::= elaborate(K)
     syntax KItem ::= elaborate(K, K)

     syntax KItem ::= elaborateDone(K)
     syntax KItem ::= elaborateDone(K, K)
endmodule

module C-ELABORATOR
     imports C-ELABORATOR-SYNTAX

     syntax KItem ::= waitingOn(CId)
     syntax CId ::= subElab(Int)

     rule <k> elaborate(K:K) => waitingOn(subElab(!E:Int)) ...</k>
          <control-details> C:Bag </control-details>
          (.Bag => <elaborator>...
               <elab-id> subElab(!E) </elab-id>
               <k> K </k>
               <control-details> C </control-details>
          ...</elaborator>)
     rule <k> waitingOn(E:CId) => elaborateDone(K:K) ...</k>
          (<elaborator>...
               <elab-id> E </elab-id>
               <k> .K </k>
               <elab> K:K </elab>
          ...</elaborator> => .Bag)

     syntax KItem ::= waitingOn(CId, CId)

     rule <k> elaborate(K1:K, K2:K)
               => waitingOn(subElab(!E1:Int), subElab(!E2:Int)) ...</k>
          <control-details> C:Bag </control-details>
          (.Bag => <elaborator>...
               <elab-id> subElab(!E1) </elab-id>
               <k> K1 </k>
               <control-details> C </control-details>
          ...</elaborator>)
          (.Bag => <elaborator>...
               <elab-id> subElab(!E2) </elab-id>
               <k> K2 </k>
               <control-details> C </control-details>
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
