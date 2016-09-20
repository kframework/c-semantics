module CPP-STMT-EXPR
     imports C-CONFIGURATION
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-SYNTAX
     imports CPP-COMMON-STMT-EXPR-SYNTAX

     rule <k> ExpressionStmt(V:Val)  => .K ...</k>
          <elab>... .K => ExpressionStmt(V) </elab>
          requires isTExpr(V) andBool notBool isConvertableDiscardedExpr(V)

     rule ExpressionStmt(V::GLVal) => PRValExpressionStmt(V)
          requires isConvertableDiscardedExpr(V)

     rule ExpressionStmt(V:Val) => .K
          requires notBool isTExpr(V) andBool notBool isConvertableDiscardedExpr(V)

     rule <k> PRValExpressionStmt(V:PRVal) => .K ...</k>
          <elab>... .K => PRValExpressionStmt(V) </elab>

     rule PRValExpressionStmt(V:PRVal) => .K
          requires notBool isTExpr(V)

     rule NullStmt() => .K

endmodule
