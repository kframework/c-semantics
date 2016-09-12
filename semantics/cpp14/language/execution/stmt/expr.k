module CPP-STMT-EXPR
     imports CPP-COMMON-STMT-EXPR-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports BOOL
     imports CPP-SYNTAX

     // TODO(dwightguth): destroy temporaries
     rule ExpressionStmt(V:Val) => fullExpression
          requires notBool isConvertableDiscardedExpr(V)

endmodule
