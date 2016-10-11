module CPP-TRANSLATION-EXPR-CAST
     imports CPP-EXPR-CAST-SYNTAX
     imports BOOL
     imports K-EQUAL
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-COMMON-STMT-EXPR-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DECL-INITIALIZER-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     // TODO(dwightguth): 5.4:4.3-5
     rule ParenthesizedCast(T:CPPType, V:Val) => tryConvert(convertConst(T, V), tryConvert(convertStatic(T, V, hasTrace(ParenthesizedCast(T, V))), tryConvert(.K, .K)))

     syntax Expr ::= tryConvert(Expr, Expr) [strict(1)]
     rule tryConvert(cannot-convert, E::Expr) => E
     rule tryConvert(V:Val, _) => V
          requires V =/=K cannot-convert

     syntax Expr ::= tryInit(CPPType, Val, K) [strict(3)]

     rule convertStatic(T::CPPType, V::Val, Tr::Trace)
          => tryInit(T, V, figureInit(le(temp(!I:Int, T), Tr, T), T, AutoStorage, V, V)) [owise]

     rule tryInit(T::CPPType, V::Val, ill-formed) => #convertStatic(T, makePRVal(V))
     rule tryInit(_, _, V:Val) => V

     rule convertStatic(_:CPPVoidType, V::Val, _)
          => prDiscardedExpr(V)
          requires isConvertableDiscardedExpr(V)
     rule convertStatic(_:CPPVoidType, V::Val, _)
          => glDiscardedExpr(V)
          requires notBool isConvertableDiscardedExpr(V)

endmodule
