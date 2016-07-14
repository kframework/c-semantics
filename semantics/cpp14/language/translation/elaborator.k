module CPP-ELABORATOR-SYNTAX
     imports BASIC-K

     syntax KItem ::= elaborate(K)
                    | elaborateDone(K)

     syntax KItem ::= runInit(K)
endmodule

module CPP-ELABORATOR
     imports CPP-ELABORATOR-SYNTAX
     imports C-CONFIGURATION

     syntax KItem ::= elabFrame(K, K)

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

     rule (.K => elaborate(K)) ~> runInit(K:K)
     rule elaborateDone(_) ~> runInit(_) => .K

endmodule
