module CPP-STMT-EXPR
     imports C-CONFIGURATION
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule ExpressionStmt(V:GLVal => convertLVal(V))
          requires isVolatileType(type(V)) andBool isConvertableDiscardedExpr(V)

     syntax Bool ::= isConvertableDiscardedExpr(GLVal) [function]

     rule <k> ExpressionStmt(V:Val)  => .K ...</k>
          <elab>... .K => ExpressionStmt(V) </elab>
          requires isTExpr(V) andBool notBool (isGLVal(V) andBool isVolatileType(type(V)) andBool isConvertableDiscardedExpr(V:>GLVal))

     rule ExpressionStmt(V:Val) => .K
          requires notBool isTExpr(V) andBool notBool (isGLVal(V) andBool isVolatileType(type(V)) andBool isConvertableDiscardedExpr(V:>GLVal))

endmodule
