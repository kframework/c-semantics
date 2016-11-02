module CPP-STMT-GOTO
     imports C-CONFIGURATION
     imports BOOL
     imports CPP-SYNTAX
     imports CPP-DYNAMIC-SYNTAX

     rule <k> GotoStmt(Lbl::CId) ~> _:K => preprocessGoto(K, Lbl) </k>
          <curr-scope> blockScope(_, Base::SymBase, _) </curr-scope>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <goto-map>...
               Base |-> (_::Map Lbl |-> K:K)
          ...</goto-map>

     syntax KItem ::= "preprocessGoto" "(" K "," CId ")" [function]
     rule preprocessGoto(gotoObject(_, _, Blk:K, _, _), funLabel(_))
          => Blk
     rule preprocessGoto(GotoInfo:K, _) => processGoto(GotoInfo) [owise]

     syntax Bool ::= isGotoKLabel(K) [function, klabelPredicate, klabel(isGotoKLabelCpp)]
     rule isGotoKLabel(#klabel(`processGotoCpp`)) => true
     rule isGotoKLabel(#klabel(`processGotoDownCpp`)) => true
     rule isGotoKLabel(_) => false [owise]

     syntax KItem ::= processGoto(K) [klabel(processGotoCpp)]
                    | processGotoDown(K) [klabel(processGotoDownCpp)]

endmodule
