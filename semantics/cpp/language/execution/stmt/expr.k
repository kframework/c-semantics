module CPP-EXECUTION-STMT-EXPR
     imports CPP-COMMON-STMT-EXPR-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports BOOL
     imports CPP-SYNTAX
     imports CPP-DYNAMIC-SYNTAX

     rule ExpressionStmt(V:Val) => fullExpression
          requires Execution() andBool isEvalVal(V)

endmodule
