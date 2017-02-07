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

     rule convertConst(T2::CPPType, pre(V::Expr, Tr::Trace, T1::CPPType))
          => pre(ConstCast(T2, V), Tr, T2)
          requires isSimilar(T2, T1)
     rule convertConst(T2:CPPLVRefType, le(Loc::Expr, Tr::Trace, T1::CPPType))
          => le(Loc, Tr, innerType(T2))
          requires isObjectType(T1) andBool isObjectType(innerType(T2))
               andBool isSimilar(type(pointerType(innerType(T2))),
                                 type(pointerType(T1)))

     rule convertConst(T2:CPPRVRefType, V:TExpr)
          => xe(ConstCast(T2, stripHold(V)), trace(V), innerType(T2))
          requires isObjectType(type(V)) andBool isObjectType(innerType(T2))
               andBool isSimilar(type(pointerType(innerType(T2))),
                                 type(pointerType(type(V))))
     //5.2.3:1
     rule FunctionalCast(T:CPPType, ListItem(E::Expr)) => ParenthesizedCast(T, E)
     //5.2.3:2
     rule FunctionalCast(T:CPPType, .List)
          => makePRVal(valueInit(le(temp(!I:Int, T), noTrace, T), T))
          requires notBool isCPPArrayType(T)

     // TODO(dwightguth): 5.4:4.3-5
     rule ParenthesizedCast(T:CPPType, V:Val)
          => tryConvert(convertConst(T, V)
           , tryConvert(convertStatic(T, V, hasTrace(ParenthesizedCast(T, V)))
           , tryConvert(.K, .K)))

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

     rule convertReinterpret(T2:CPPRefType, V:GLExpr)
          => le(ReinterpretCast(T2, stripHold(V)), trace(V), innerType(T2))
          requires ((isObjectType(innerType(T2)) andBool isObjectType(type(V)))
               orBool (isCPPFunctionType(innerType(T2)) andBool isCPPFunctionType(type(V))))
               andBool isUnnamedLValue(T2)
     rule convertReinterpret(T2:CPPRefType, V:GLExpr)
          => xe(ReinterpretCast(T2, stripHold(V)), trace(V), innerType(T2))
          requires ((isObjectType(innerType(T2)) andBool isObjectType(type(V)))
               orBool (isCPPFunctionType(innerType(T2)) andBool isCPPFunctionType(type(V))))
               andBool isUnnamedXValue(T2)

endmodule
