module CPP-TRANSLATION-EXPR-CAST
     imports CPP-EXPR-CAST-SYNTAX
     imports BOOL
     imports LIST
     imports K-EQUAL
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-COMMON-STMT-EXPR-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-TRANSLATION-DECL-INITIALIZER-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-REFERENCE-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule convertConst(T2::CPPType, pre(V::Expr, Tr::Trace, T1::CPPType))
          => pre(ConstCast(T2, V), Tr, T2)
          requires isSimilar(T2, T1)

     rule convertConst(t(... st: lvRefType(...)) #as T2::CPPType, le(Loc::Expr, Tr::Trace, T1::CPPType))
          => le(Loc, Tr, innerType(T2))
          requires isObjectType(T1) andBool isObjectType(innerType(T2))
               andBool isSimilar(type(pointerType(innerType(T2))),
                                 type(pointerType(T1)))

     rule convertConst(t(... st: rvRefType(...)) #as T2::CPPType, V:TExpr)
          => xe(ConstCast(T2, stripHold(V)), trace(V), innerType(T2))
          requires isObjectType(type(V)) andBool isObjectType(innerType(T2))
               andBool isSimilar(type(pointerType(innerType(T2))),
                                 type(pointerType(type(V))))

     // @ref n4296 5.2.3:1-2
     // <quote>
     // A simple-type-specifier (7.1.6.2) or typename-specifier (14.6)
     // followed by a parenthesized expression-list constructs a value
     // of the specified type given the expression list.
     // </quote>
     rule FunctionalCast(T:CPPType, L::List)
          =>
          // <quote>
          // If the expression list is a single expression,
          // </quote>
          #if size(L) ==Int 1
          #then
               // <quote>
               // the type conversion expression is equivalent (in definedness,
               // and if defined in meaning) to the corresponding cast expres-
               // sion (5.4). If the type specified is a class type, the class
               // type shall be complete.
               // </quote>
               #if isCPPClassType(T) andBool notBool isCompleteType(T)
               #then ill-formed
               #else ParenthesizedCast(T, {L[0]}:>Expr)
               #fi
          #else
               // <quote>
               // If the expression list specifies more than a single value,
               // </quote>
          #if size(L) >Int 1
          #then
               // <quote>
               // the type shall be a class with a suitably declared constructor
               // (8.5, 12.1), and the expression `T(x1, x2, ...)` is equivalent
               // in effect to the declaration `T t(x1, x2, ...);` for some
               // invented temporary variable t, with the result being the value
               // of t as a prvalue.
               // </quote>
               #if notBool isCPPClassType(T)
               #then ill-formed
               #else makePRVal(figureInit(le(temp(!I:Int, T), noTrace, T),
                         T, ExpressionList(L), DirectInit(), AutoStorage))
               #fi
          #else
          // <quote>
          // The expression T(), where T is a simple-type-specifier or
          // typename-specifier for a non-array complete object type or the
          // (possibly cv-qualified) void type,
          // </quote>
          #if size(L) ==Int 0 andBool
               ((notBool isCPPArrayType(T) andBool isCompleteType(T))
                    orBool isCPPVoidType(T))
          #then
               // <quote>
               // creates a prvalue of the
               // specified type, whose value is that produced by value-initi-
               // alizing (8.5) an object of type T; no initialization is done
               // for the void() case. [ Note: if T is a non-class type that is
               // cv-qualified, the cv-qualifiers are discarded when determining
               // the type of the resulting prvalue (Clause 5). -- end note ]
               // </quote>
               #if isCPPVoidType(T)
               #then prv(voidVal, noTrace, T)
               #else makePRVal(valueInit(le(temp(!I:Int, T), noTrace, T), T))
               #fi
          #else ill-formed
          #fi #fi #fi


     // TODO(dwightguth): 5.4:4.3-5
     rule ParenthesizedCast(T:CPPType, V:Val)
          => tryConvert(ConstCast(T, V)
           , tryConvert(convertStatic(T, V, hasTrace(ParenthesizedCast(T, V)))
           , tryConvert(ConstCast(T, tryConvert(convertStatic(getStaticThenConstIntermediateType(T), V, hasTrace(ParenthesizedCast(T, V))), V))
           , tryConvert(ReinterpretCast(T, V)
           , stuck))))

     // TODO(dwightguth): is this actually sufficient to catch all cases where a static + const cast would succeed? This seems
     // to be equivalent to what clang does internally, but the standard also does not appear to provide any obvious
     // examples for what it describes or even provide an algorithm that might encompass said description. If we're serious
     // about doing exactly what the standard says, we would have to exhaustively consider all intermediate types, which seems
     // very strange and is definitely /not/ what clang does.
     syntax CPPType ::= getStaticThenConstIntermediateType(CPPType) [function]

     rule getStaticThenConstIntermediateType(t(Q::Quals, Mods::Set, pointerType(t(Q'::Quals, Mods::Set, T::CPPSimpleType))))
          => t(Q, Mods, pointerType(t(Q' +Qual Const() +Qual Volatile(), Mods, T)))

     rule getStaticThenConstIntermediateType(t(Q::Quals, Mods::Set, memberPointerType(C::CPPType, t(Q'::Quals, Mods::Set, T::CPPSimpleType))))
          => t(Q, Mods, memberPointerType(C, t(Q' +Qual Const() +Qual Volatile(), Mods, T)))

     rule getStaticThenConstIntermediateType(T::CPPType) => T [owise]

     syntax Expr ::= tryConvert(Expr, Expr) [strict(c; 1)]
     syntax Expr ::= "stuck"

     rule tryConvert(cannot-convert, E::Expr) => E

     rule tryConvert(V:Val, _) => V
          requires V =/=K cannot-convert

     rule StaticCast(T:CPPType, V:Val)
          => convertStatic(T, V, hasTrace(StaticCast(T, V)))

     syntax Expr ::= tryInit(CPPType, Val, KItem) [strict(c; 3)]

     // this is needed to be able to treat certain expressions as constant expressions.
     // it should be safe since the side condition guarantees that the initialization
     // we are conceptually performing is well formed and would simply perform this conversion
     rule convertStatic(T::CPPType, V:PRVal, _)
          => convertType(T, V)
          requires canConvertWithStandardConversion(T, type(V), prvalue)
               andBool notBool isCPPRefType(T) andBool notBool isCPPArrayType(T)
               andBool notBool isCPPClassType(T) andBool notBool isCPPClassType(type(V))

     // @ref n4800 7.6.1.8:3
     rule convertStatic(t(... st: rvRefType(...)) #as T::CPPType, V:LVal, Tr::Trace)
          =>
          #if notBool isCPPBitfieldType(type(V)) #then
               xe(makeXVal(stripHold(V)), Tr, T)
          #else
               not-implemented // TODO (h0nzZik)
          #fi
          requires isReferenceCompatible(innerType(T), type(V))

     // @ref n4800 7.6.1.8:4
     rule convertStatic(T::CPPType, V::Val, Tr::Trace)
          => tryInit(T, V, figureInit(le(temp(!I:Int, T), Tr, T), T, V, DirectInit(), AutoStorage)) [owise]

     rule tryInit(_, _, V:Val) => V

     // @ref n4800 7.6.1.8:5
     rule tryInit(T::CPPType, V::Val, ill-formed) => #convertStatic(T, makePRVal(V))


     // @ref n4800 7.6.1.8:6
     rule convertStatic(t(... st: void), V::Val, _)
          =>
          #if isConvertableDiscardedExpr(V) #then
               prDiscardedExpr(V)
          #else
               glDiscardedExpr(V)
          #fi

     // @ref n4800 7.6.1.9:11
     // glvalue (lvalue) to reference
     rule convertReinterpret(cppRefType #as T2::CPPType, V:GLExpr)
          => le(ReinterpretCast(T2, stripHold(V)), trace(V), innerType(T2))
          requires ((isObjectType(innerType(T2)) andBool isObjectType(type(V)))
               orBool (isCPPFunctionType(innerType(T2)) andBool isCPPFunctionType(type(V))))
               andBool isUnnamedLValue(T2)

     // @ref n4800 7.6.1.9:11
     // glvalue (xvalue) to reference
     rule convertReinterpret(cppRefType #as T2::CPPType, V:GLExpr)
          => xe(ReinterpretCast(T2, stripHold(V)), trace(V), innerType(T2))
          requires ((isObjectType(innerType(T2)) andBool isObjectType(type(V)))
               orBool (isCPPFunctionType(innerType(T2)) andBool isCPPFunctionType(type(V))))
               andBool isUnnamedXValue(T2)

     // @ref n4800 7.6.1.9:4
     // pointer to integer
     rule convertReinterpret(T2::CPPType, V:PRExpr)
          => pre(ReinterpretCast(T2, stripHold(V)), trace(V), T2)
          requires (isCPPIntegerType(T2) andBool isCPPPointerType(type(V))
                    andBool byteSizeofType(T2) >=Int byteSizeofType(type(V)))

     // @ref n4800 7.6.1.9:7
     // pointer to pointer
     rule convertReinterpret(T::CPPType, V:PRVal)
          => StaticCast(T, StaticCast(type(pointerType(t(getQuals(innerType(T)), .Set, void))), V))
          requires isPointerToObjectType(T)
           andBool isPointerToObjectType(type(V))


endmodule
