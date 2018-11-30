module CPP-COMMON-STMT-EXPR-SYNTAX
     imports CPP-DYNAMIC-SORTS
     syntax Bool ::= isConvertableDiscardedExpr(Val) [function]

     syntax Expr ::= prDiscardedExpr(Expr) [strict]
                   | glDiscardedExpr(Expr) [strict]
endmodule

module CPP-COMMON-STMT-EXPR
     imports CPP-COMMON-STMT-EXPR-SYNTAX
     imports BOOL
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule prDiscardedExpr(V:GLVal => convertLVal(V))

     rule prDiscardedExpr(prv(_, Tr::Trace, _)) => prv(voidVal, Tr, type(void))

     rule glDiscardedExpr(V:Val) => prv(voidVal, trace(V), type(void))

     rule isConvertableDiscardedExpr(V::Val)
          => isGLVal(V) andBool isVolatileType(type(V))
               andBool #isConvertableDiscardedExpr(trace(V))

     syntax Bool ::= #isConvertableDiscardedExpr(Trace) [function]

     rule #isConvertableDiscardedExpr(hasTrace(Name(_, _))) => true

     // subscripting will get rewritten to an indirection, which is also a convertable discarded expression
     rule #isConvertableDiscardedExpr(hasTrace(_ . _ _::Name)) => true

     rule #isConvertableDiscardedExpr(hasTrace(_ -> _ _)) => true

     rule #isConvertableDiscardedExpr(hasTrace(* _)) => true

     rule #isConvertableDiscardedExpr(hasTrace(_ .* _)) => true

     rule #isConvertableDiscardedExpr(hasTrace(_ ->* _)) => true

     rule #isConvertableDiscardedExpr(hasTrace(ConditionalOp(_, E1::Expr, E2::Expr, _, _)))
          => #isConvertableDiscardedExpr(hasTrace(E1))
               andBool #isConvertableDiscardedExpr(hasTrace(E2))

     rule #isConvertableDiscardedExpr(hasTrace(Comma(_, E::Expr)))
          => #isConvertableDiscardedExpr(hasTrace(E))

     rule #isConvertableDiscardedExpr(hasTrace(_)) => false [owise]


endmodule
