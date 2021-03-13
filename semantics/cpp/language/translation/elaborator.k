module CPP-TRANSLATION-ELABORATOR-SYNTAX
     imports BASIC-K

     syntax KItem ::= elaborate(K) [klabel(elaborate1)]
                    | elaborate(K, K)
                    | elaborateDone(K) [klabel(elaborateDone1)]
                    | elaborateDone(K, K)
                    | elaborateTemplateBody(K)
                    | elaborateThen(K)

     syntax KItem ::= runInit(K)

     syntax K ::= toExecution(K) [function]
endmodule

module CPP-TRANSLATION-ELABORATOR
     imports CPP-TRANSLATION-DECL-TEMPLATE-SORTS
     imports CPP-TRANSLATION-ELABORATOR-SYNTAX
     imports C-CONFIGURATION

     syntax KItem ::= elabFrame(K, K)
                    | elabTemplateFrame(K, K, TemplateInfo)

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

     rule <k> elaborateTemplateBody(K:K) ~> Cont:K => K </k>
          <curr-template-context> I::TemplateInfo => noTemplate </curr-template-context>
          <elab> OldElab:K => .K </elab>
          <elab-stack>
               .List => ListItem(elabTemplateFrame(Cont, OldElab, I))
          ...</elab-stack>

     rule <k> .K => elaborateDone(K) ~> Cont </k>
          <curr-template-context> _ => I </curr-template-context>
          <elab> K:K => OldElab </elab>
          <elab-stack>
               ListItem(elabTemplateFrame(Cont:K, OldElab:K, I::TemplateInfo)) => .List
          ...</elab-stack>

     syntax K ::= #toExecution(Int, K) [function]

     rule #toExecution(0, K::K) => toExecution(K)

     rule #toExecution(_, K::K) => K [owise]

     rule <k> elaborateThen(K::K) => .K ...</k>
          <elab>... .K => #toExecution(Depth, K) </elab>
          <curr-template-depth> Depth::Int </curr-template-depth>

     rule (.K => K) ~> runInit(K:K)

     rule _:Val ~> runInit(_) => .K

     rule elaborate(K1:K, K2:K) => elaborate(K1) ~> elaborate(K2)

     rule elaborateDone(K1:K) ~> elaborate(K2:K)
          => elaborate(K2) ~> elaborateDone(K1)

     rule elaborateDone(K2:K) ~> elaborateDone(K1:K)
          => elaborateDone(K1:K, K2:K)

endmodule
