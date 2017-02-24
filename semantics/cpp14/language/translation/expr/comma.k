module CPP-EXPR-COMMA
     imports CPP-COMMON-STMT-EXPR-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     context Comma(V:Val, HOLE:Expr)
             requires isTExpr(V) andBool notBool isConvertableDiscardedExpr(V)

     rule Comma(V1:TExpr, V2:Val) => pre(Comma(stripHold(V1), stripHold(V2)), combine(trace(V1), trace(V2), #klabel(`Comma`)), type(V2))

     rule Comma(V::GLVal => prDiscardedExpr(V), _)
          requires isConvertableDiscardedExpr(V)

     rule Comma(V:Val, E::Expr) => E
          requires notBool isTExpr(V) andBool notBool isConvertableDiscardedExpr(V)

endmodule
