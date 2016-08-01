module CPP-COMMON-STMT-EXPR-SYNTAX
     imports CPP-DYNAMIC-SORTS
     syntax Bool ::= isConvertableDiscardedExpr(Val) [function]
endmodule

module CPP-COMMON-STMT-EXPR
     imports CPP-COMMON-STMT-EXPR-SYNTAX
     imports BOOL
     imports CPP-CONVERSION-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule ExpressionStmt(V::GLVal => convertLVal(V))
          requires isConvertableDiscardedExpr(V)

     rule isConvertableDiscardedExpr(V::Val) 
          => isGLVal(V) andBool isVolatileType(type(V))
               andBool #isConvertableDiscardedExpr({V}:>GLVal)

     syntax Bool ::= #isConvertableDiscardedExpr(GLVal) [function]

endmodule
