module CPP-TRANSLATION-EXPR-CAST
     imports CPP-EXPR-CAST-SYNTAX
     imports BOOL
     imports K-EQUAL
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-COMMON-STMT-EXPR-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-TRANSLATION-DECL-INITIALIZER-SYNTAX
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

     rule FunctionalCast(T:CPPType, ListItem(E1::Expr) ListItem(E2::Expr) L::List)
          => makePRVal(figureInit(le(temp(!I:Int, T), noTrace, T), T, ExpressionList(ListItem(E1) ListItem(E2) L), DirectInit()))

     //5.2.3:2
     rule FunctionalCast(T:CPPType, .List)
          => makePRVal(valueInit(le(temp(!I:Int, T), noTrace, T), T))
          requires notBool isCPPArrayType(T)

     // TODO(dwightguth): 5.4:4.3-5
     rule ParenthesizedCast(T:CPPType, V:Val)
          => tryConvert(ConstCast(T, V)
           , tryConvert(convertStatic(T, V, hasTrace(ParenthesizedCast(T, V)))
           , tryConvert(ConstCast(T, tryConvert(convertStatic(getStaticThenConstIntermediateType(T), V, hasTrace(ParenthesizedCast(T, V))), V))
           , tryConvert(ReinterpretCast(T, V)
           , tryConvert(.K, .K)))))

     // TODO(dwightguth): is this actually sufficient to catch all cases where a static + const cast would succeed? This seems
     // to be equivalent to what clang does internally, but the standard also does not appear to provide any obvious
     // examples for what it describes or even provide an algorithm that might encompass said description. If we're serious
     // about doing exactly what the standard says, we would have to exhaustively consider all intermediate types, which seems
     // very strange and is definitely /not/ what clang does.
     syntax CPPType ::= getStaticThenConstIntermediateType(CPPType) [function]

     rule getStaticThenConstIntermediateType(t(Q::Quals, Mods::Set, pointerType(t(Q'::Quals, Mods::Set, T::CPPSimpleType))))
          => t(Q, Mods, pointerType(t(Q' +Qual Const() +Qual Volatile(), Mods, T)))

     rule getStaticThenConstIntermediateType(t(Q::Quals, Mods::Set, memberPointerType(C::CPPClassType, t(Q'::Quals, Mods::Set, T::CPPSimpleType))))
          => t(Q, Mods, memberPointerType(C, t(Q' +Qual Const() +Qual Volatile(), Mods, T)))

     rule getStaticThenConstIntermediateType(T::CPPType) => T [owise]

     syntax Expr ::= tryConvert(Expr, Expr) [strict(1)]

     rule tryConvert(cannot-convert, E::Expr) => E

     rule tryConvert(V:Val, _) => V
          requires V =/=K cannot-convert

     rule StaticCast(T:CPPType, V:Val)
          => convertStatic(T, V, hasTrace(StaticCast(T, V)))

     syntax Expr ::= tryInit(CPPType, Val, K) [strict(3)]

     // this is needed to be able to treat certain expressions as constant expressions.
     // it should be safe since the side condition guarantees that the initialization
     // we are conceptually performing is well formed and would simply perform this conversion
     rule convertStatic(T::CPPType, V:PRVal, Tr2::Trace)
          => convertType(T, V)
          requires canConvertWithStandardConversion(T, type(V), prvalue)
               andBool notBool isCPPRefType(T) andBool notBool isCPPArrayType(T)
               andBool notBool isCPPClassType(T) andBool notBool isCPPClassType(type(V))

     rule convertStatic(T::CPPType, V::Val, Tr::Trace)
          => tryInit(T, V, figureInit(le(temp(!I:Int, T), Tr, T), T, V, DirectInit())) [owise]

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

     rule convertReinterpret(T2::CPPType, V:PRExpr)
          => pre(ReinterpretCast(T2, stripHold(V)), trace(V), T2)
          requires (isCPPIntegerType(T2) andBool isCPPPointerType(type(V))
                    andBool byteSizeofType(T2) >=Int byteSizeofType(type(V)))

     rule convertReinterpret(t(... st: pointerType(t(Q::Quals, _, _))) #as T::CPPType, V:PRVal)
          => StaticCast(T, StaticCast(type(pointerType(t(Q, .Set, void))), V))
          requires isCPPPointerType(type(V)) andBool isObjectType(innerType(T))
               andBool isObjectType(innerType(type(V)))


endmodule
