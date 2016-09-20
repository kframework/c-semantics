module CPP-EXPR-REFERENCE
     imports C-CONFIGURATION
     imports CPP-DYNAMIC-SYNTAX

     rule <k> bindReference(L:LExpr, R:Val) => .K ...</k>
          <elab>... .K => bindReference(L, R) </elab>

endmodule
