module CPP-EXECUTION-STMT-EXPR
     imports CPP-COMMON-STMT-EXPR-SYNTAX
     imports C-SEQUENCE-POINT-SYNTAX
     imports BOOL
     imports COMPAT-SYNTAX
     imports CPP-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-REFERENCE-SYNTAX

     rule ExpressionStmt(V:Val) => fullExpression
          requires Execution() andBool
          (isEvalVal(V) orBool referenceBindingResult(_) :=K V)

endmodule
