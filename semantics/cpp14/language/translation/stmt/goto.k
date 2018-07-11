module CPP-TRANSLATION-STMT-GOTO
     imports CPP-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports C-CONFIGURATION

     rule <k> TGotoStmt(Lbl::CId) => .K ...</k>
          <elab>... .K => GotoStmt(Lbl) </elab>

endmodule
