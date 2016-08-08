module CPP-STMT-EXPR
     imports C-CONFIGURATION
     imports CPP-SYNTAX
     imports CPP-COMMON-STMT-EXPR-SYNTAX

     rule <k> ExpressionStmt(V:Val)  => .K ...</k>
          <elab>... .K => ExpressionStmt(V) </elab>
          requires isTExpr(V) andBool notBool isConvertableDiscardedExpr(V)

     rule ExpressionStmt(V:Val) => .K
          requires notBool isTExpr(V) andBool notBool isConvertableDiscardedExpr(V)

endmodule
