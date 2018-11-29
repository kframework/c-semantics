module CPP-EXECUTION-STMT-GOTO
     imports C-CONFIGURATION
     imports BOOL
     imports CPP-SYNTAX
     imports CPP-DYNAMIC-SYNTAX

     rule <k> GotoStmt(Lbl::CId) ~> _:K => preprocessGoto(K, Lbl) </k>
          <curr-scope> blockScope(_, Base::SymBase, _) </curr-scope>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <goto-map>...
               Base |-> (_::Map Lbl |-> K:KItem)
          ...</goto-map>

     syntax KItem ::= "preprocessGoto" "(" KItem "," CId ")" [function]

     rule preprocessGoto(gotoObject(_, _, Blk:K, _, _), funLabel(_))
          => Blk

     rule preprocessGoto(GotoInfo:KItem, _) => processGoto(GotoInfo) [owise]

     syntax Bool ::= isGotoKLabel(K) [function, klabelPredicate, klabel(isGotoKLabelCpp)]

     rule isGotoKLabel(#klabel(`processGotoCpp`)) => true

     rule isGotoKLabel(#klabel(`processGotoDownCpp`)) => true

     rule isGotoKLabel(_) => false [owise]

     syntax KItem ::= processGoto(KItem) [klabel(processGotoCpp)]
                    | processGotoDown(KItem) [klabel(processGotoDownCpp)]

endmodule
