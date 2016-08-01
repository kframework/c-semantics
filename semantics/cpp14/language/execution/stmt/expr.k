module CPP-STMT-EXPR
     imports CPP-COMMON-STMT-EXPR-SYNTAX
     imports BOOL
     imports CPP-SYNTAX

     // TODO(dwightguth): destroy temporaries
     rule ExpressionStmt(V:Val) => .K
          requires notBool isConvertableDiscardedExpr(V)

endmodule
