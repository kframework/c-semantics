module CPP-TRANSLATION-EXPR-CONDITIONAL-SYNTAX
    imports CPP-DYNAMIC-SORTS
    imports CPP-TRANSLATION-VALUE-CATEGORY-SORTS
    imports CPP-TRANSLATION-TYPING-EXPR-SORTS
    imports CPP-TYPING-SORTS

    syntax KItem ::= typeAndCatOfConditional(Expr, Expr) [function]

    syntax KResult ::= typeAndCat(CPPType, ValueCategory)

endmodule

module CPP-TRANSLATION-EXPR-CONDITIONAL
     imports CPP-TRANSLATION-EXPR-CONDITIONAL-SYNTAX
     imports K-REFLECTION
     imports COMMON-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TRANSLATION-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-TRANSLATION-VALUE-CATEGORY-SYNTAX

     context ConditionalOperator((HOLE:Expr => reval(HOLE)), _, _) [result(PRVal)]

     rule ConditionalOperator((V:PRVal => convertType(type(bool), V)), _, _)
          requires notBool isCPPBoolType(type(V))

     syntax Expr ::= makeCondOp(PRVal, Expr, Expr, KItem) [strict(4)]

     rule ConditionalOperator(V1:PRVal, E2::Expr, E3::Expr) => makeCondOp(V1, E2, E3, typeAndCatOfConditional(E2, E3))
          requires isCPPBoolType(type(V1))

     context makeCondOp(_, HOLE:Expr, _, typeAndCat(_, _))

     context makeCondOp(_, _, HOLE:Expr, typeAndCat(_, _))

     rule makeCondOp(V1:PRExpr, V2:Val, V3:Val, typeAndCat(T::CPPType, V::ValueCategory)) => makeExpr(V, ConditionalOp(V1, V2, V3, V, T), combine(trace(V1), trace(V2), trace(V3), V, T), T)

     rule makeCondOp(prv(0, _, _), _, V:Val, typeAndCat(T::CPPType, prvalue)) => ConvertType(T, makePRVal(V))

     rule makeCondOp(prv(1, _, _), V:Val, _, typeAndCat(T::CPPType, prvalue)) => ConvertType(T, makePRVal(V))

     syntax KItem ::= typeAndCatOfConditional(Expr, TypeExpr, CatExpr, Expr, TypeExpr, CatExpr) [klabel(typeAndCatOfConditional0)]

     rule typeAndCatOfConditional(ExprLoc(_, E:Expr) => E, _)

     rule typeAndCatOfConditional(_, ExprLoc(_, E:Expr) => E)

     rule typeAndCatOfConditional(E1::Expr, E2::Expr) => typeAndCatOfConditional(E1, E1, E1, E2, E2, E2) [owise]


     context typeAndCatOfConditional(_, (HOLE:TypeExpr => typeof(HOLE)), _, _, _, _) [result(CPPType)]

     context typeAndCatOfConditional(_, _, _, _, (HOLE:TypeExpr => typeof(HOLE)), _) [result(CPPType)]

     context typeAndCatOfConditional(_, _, (HOLE:CatExpr => catof(HOLE)), _, _, _) [result(ValueCategory)]

     context typeAndCatOfConditional(_, _, _, _, _, (HOLE:CatExpr => catof(HOLE))) [result(ValueCategory)]

     // @ref n4296 5.16:2.1
     rule typeAndCatOfConditional(Throw(_), _, _, E::Expr, T:CPPType, V:ValueCategory)
          => typeAndCat(T, V)
          requires Throw(...) :/=K E

     rule typeAndCatOfConditional(E::Expr, T:CPPType, V:ValueCategory, Throw(_), _, _)
          => typeAndCat(T, V)
          requires Throw(...) :/=K E

     // @ref n4296 5.16:2.2
     rule typeAndCatOfConditional(_, t(... st: void) #as T::CPPType, _, _, t(... st: void), _)
          => typeAndCat(T, prvalue)

     // TODO(dwightguth): n4296 5.16:3
     rule typeAndCatOfConditional(E1::Expr, T1:CPPType, V1:ValueCategory, E2::Expr, T2:CPPType, V2:ValueCategory)
          => typeAndCatOfConditional3(E1, T1, V1, E2, T2, V2)
          requires notBool (T1 =/=Type T2 andBool
               (isCPPClassType(T1) orBool isCPPClassType(T2) orBool
                    (isGLValueCategory(V1) andBool V1 ==K V2
                         andBool utype(T1) ==Type utype(T2))))
               andBool notBool isCPPVoidType(T1) andBool notBool isCPPVoidType(T2)

     syntax KItem ::= typeAndCatOfConditional3(Expr, CPPType, ValueCategory, Expr, CPPType, ValueCategory) [function]

     rule typeAndCatOfConditional3(_, T1:CPPType, V:GLValueCategory, _, T2:CPPType, V)
          => typeAndCat(T1, V)
          requires T1 ==Type T2 andBool (isCPPBitfieldType(T1) orBool notBool isCPPBitfieldType(T2))

     rule typeAndCatOfConditional3(_, T1:CPPType, V:GLValueCategory, _, T2:CPPType, V)
          => typeAndCat(T2, V)
          requires T1 ==Type T2 andBool (isCPPBitfieldType(T2) orBool notBool isCPPBitfieldType(T1))

     // TODO(dwightguth): n4296 5.16:5
     rule typeAndCatOfConditional3(E1::Expr, T1:CPPType, _, E2::Expr, T2:CPPType, _)
          => typeAndCatOfConditional5(E1, T1, E2, T2)
          requires notBool (T1 =/=Type T2 andBool (isCPPClassType(T1) orBool isCPPClassType(T2))) [owise]

     syntax KItem ::= typeAndCatOfConditional5(Expr, CPPType, Expr, CPPType) [function]

     rule typeAndCatOfConditional5(E1::Expr, T1::CPPType, E2::Expr, T2::CPPType)
          => typeAndCatOfConditional6(E1, prvalType(T1), E2, prvalType(T2))

     syntax KItem ::= typeAndCatOfConditional6(Expr, CPPType, Expr, CPPType) [function]

     rule typeAndCatOfConditional6(_, T1::CPPType, _, T2::CPPType)
          => typeAndCat(T1, prvalue)
          requires T1 ==Type T2

     rule typeAndCatOfConditional6(_, T1::CPPType, _, T2::CPPType)
          => typeAndCat(usualArithmeticConversions(T1, T2), prvalue)
          requires (isCPPArithmeticType(T1) orBool isCPPEnumType(T1)) andBool (isCPPArithmeticType(T2) orBool isCPPEnumType(T2))

     rule typeAndCatOfConditional6(E1::Expr, T1::CPPType, E2::Expr, T2::CPPType)
          => typeAndCat(compositePointerType(E1, T1, E2, T2), prvalue)
          requires isCPPPointerType(T1) orBool isCPPPointerType(T2)

     rule typeAndCatOfConditional6(E1::Expr, T1::CPPType, E2::Expr, T2::CPPType)
          => typeAndCat(compositePointerType(E1, T1, E2, T2), prvalue)
          requires isCPPMemberPointerType(T1) orBool isCPPMemberPointerType(T2)

     rule typeAndCatOfConditional6(_, t(... st: nullptr_t) #as T::CPPType, _, t(... st: nullptr_t))
          => typeAndCat(T, prvalue)

     rule typeAndCatOfConditional6(_, t(... st: nullptr_t) #as T::CPPType, IntegerLiteral(0, _), _)
          => typeAndCat(T, prvalue)

     rule typeAndCatOfConditional6(IntegerLiteral(0, _), _, _, t(... st: nullptr_t) #as T::CPPType)
          => typeAndCat(T, prvalue)

endmodule
