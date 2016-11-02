module CPP-STMT-GOTO
     imports CPP-SYNTAX
     imports C-CONFIGURATION

     rule <k> GotoStmt(Lbl::CId) => .K ...</k>
          <elab>... .K => GotoStmt(Lbl) </elab>

endmodule
