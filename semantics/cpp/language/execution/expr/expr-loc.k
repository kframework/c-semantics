module CPP-EXECUTION-EXPR-EXPRLOC-SYNTAX
     imports CPP-SYNTAX
     imports COMMON-SORTS

     syntax Expr ::= #ExecExprLoc(CabsLoc, Expr) [strict(c; 2)]
endmodule

module CPP-EXECUTION-EXPR-EXPRLOC
     imports CPP-EXECUTION-EXPR-EXPRLOC-SYNTAX
     imports C-CONFIGURATION
     imports CPP-DYNAMIC-SYNTAX // Execution()

     rule <k> ExprLoc(L::CabsLoc, E:Expr) => #ExecExprLoc(L, E) ...</k>
          <curr-program-loc> _ => L </curr-program-loc>
          requires Execution()

     rule <k> #ExecExprLoc(L::CabsLoc, V:Val) => V ...</k>
          <curr-program-loc> _ => L </curr-program-loc>

endmodule
