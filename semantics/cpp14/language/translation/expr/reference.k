module CPP-EXPR-REFERENCE
     imports C-CONFIGURATION
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule bindReference(L:LExpr, R:Val) => pre(bindReference(L, R), trace(L), type(L))

endmodule
