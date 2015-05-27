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

     syntax KItem ::= waitingOn(CId)
     syntax CId ::= elab(Int)

     rule (.K => K) ~> compoundExp(K:K)
     rule R:KResult ~> compoundExp(K:K)
          => te(compoundExp(K), type(R))

     rule <k> (.K => waitingOn(elab(!E:Int))) ~> elaborate(K:K) ...</k>
          <local> L:Bag </local>
          (.Bag => <elaborator>...
               <elab-id> elab(!E) </elab-id>
               <k> K </k>
               <local> L </local>
          ...</elaborator>)
     rule <k> waitingOn(elab(E:Int)) ~> elaborate(_) => elaborateDone(K:K) ...</k>
          (<elaborator>...
               <elab-id> elab(E) </elab-id>
               <k> .K </k>
               <elab> K:K </elab>
          ...</elaborator> => .Bag)
     rule <k> (.K => waitingOn(elab(!E:Int))) ~> elaborateInit(K:K) ...</k>
          <local> L:Bag </local>
          (.Bag => <elaborator>...
               <elab-id> elab(!E) </elab-id>
               <k> K </k>
               <initializing> 1 </initializing>
               <local> L </local>
          ...</elaborator>)
     rule <k> waitingOn(elab(E:Int)) ~> elaborateInit(_) => elaborateInitDone(K:K) ...</k>
          <local> _ => L </local>
          (<elaborator>...
               <elab-id> elab(E) </elab-id>
               <k> .K </k>
               <elab> K:K </elab>
               <local> L:Bag </local>
          ...</elaborator> => .Bag)
     rule <k> (.K => waitingOn(elab(!E:Int))) ~> runInit(K:K) ...</k>
          <local> L:Bag </local>
          (.Bag => <elaborator>...
               <elab-id> elab(!E) </elab-id>
               <k> K </k>
               <initializing> 1 </initializing>
               <local> L </local>
          ...</elaborator>)
     rule <k> waitingOn(elab(E:Int)) ~> runInit(_) => .K ...</k>
          <local> _ => L </local>
          (<elaborator>...
               <elab-id> elab(E) </elab-id>
               <k> .K </k>
               <elab> _ </elab>
               <local> L:Bag </local>
          ...</elaborator> => .Bag)

     syntax KItem ::= waitingOn(CId, CId)

     rule <k> elaborate(K1:K, K2:K) => waitingOn(elab(!E1:Int), elab(!E2:Int)) ...</k>
          <local> L:Bag </local>
          (.Bag => <elaborator>...
               <elab-id> elab(!E1) </elab-id>
               <k> K1 </k>
               <local> L </local>
          ...</elaborator>)
          (.Bag => <elaborator>...
               <elab-id> elab(!E2) </elab-id>
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

     rule typeof(V:KResult) => type(V)

endmodule
