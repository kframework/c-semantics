module CPP-EXPR-CONDITIONAL-SYNTAX
    imports CPP-DYNAMIC-SORTS
    imports CPP-VALUE-CATEGORY-SORTS
    imports CPP-TYPING-EXPR-SORTS
    imports CPP-TYPING-SORTS

    syntax KItem ::= typeAndCatOfConditional(Expr, TypeExpr, CatExpr, Expr, TypeExpr, CatExpr)
                   | typeAndCat(CPPType, ValueCategory)

endmodule

module CPP-EXPR-CONDITIONAL
     imports CPP-EXPR-CONDITIONAL-SYNTAX
     imports K-REFLECTION
     imports COMMON-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-VALUE-CATEGORY-SYNTAX

     context ConditionalOperator((HOLE:Expr => reval(HOLE)), _, _) [result(PRVal)]

     rule ConditionalOperator((V:PRVal => convertType(type(bool), V)), _, _)
          requires notBool isCPPBoolType(type(V))

     context ConditionalOperator(_, HOLE:Expr, _)
     context ConditionalOperator(_, _, HOLE:Expr)

     rule (.K => typeof(ConditionalOperator(V1, V2, V3))) ~> ConditionalOperator(V1:PRVal, V2:Val, V3:Val)
          requires isCPPBoolType(type(V1))
     rule (.K => catof(ConditionalOperator(V1, V2, V3))) ~> typeof(T:CPPType) ~> ConditionalOperator(V1::PRVal, V2::Val, V3::Val)
     rule catof(V:ValueCategory) ~> typeof(T::CPPType) ~> ConditionalOperator(V1:PRExpr, V2::Val, V3::Val) => makeExpr(V, T, ConditionalOp(V1, V2, V3, V, T), combine(trace(V1), trace(V2), trace(V3), V, T))


     context typeAndCatOfConditional(_, (HOLE:TypeExpr => typeof(HOLE)), _, _, _, _) [result(CPPType)]
     context typeAndCatOfConditional(_, _, _, _, (HOLE:TypeExpr => typeof(HOLE)), _) [result(CPPType)]
     context typeAndCatOfConditional(_, _, (HOLE:CatExpr => catof(HOLE)), _, _, _) [result(ValueCategory)]
     context typeAndCatOfConditional(_, _, _, _, _, (HOLE:CatExpr => catof(HOLE))) [result(ValueCategory)]

     // 5.16:2.1
     rule typeAndCatOfConditional(Throw(_), _, _, E::Expr, T:CPPType, V:ValueCategory)
          => typeAndCat(T, V)
          requires getKLabel(E) =/=K #klabel(`Throw`)
     rule typeAndCatOfConditional(E::Expr, T:CPPType, V:ValueCategory, Throw(_), _, _)
          => typeAndCat(T, V)
          requires getKLabel(E) =/=K #klabel(`Throw`)

     // 5.16:2.2
     rule typeAndCatOfConditional(_, T:CPPVoidType, _, _, _:CPPVoidType, _)
          => typeAndCat(T, prvalue)

     // TODO(dwightguth): 5.16:3
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
          requires T1 ==Type T2
     // TODO(dwightguth): 5.16:5
     rule typeAndCatOfConditional3(E1::Expr, T1:CPPType, _, E2::Expr, T2:CPPType, _)
          => typeAndCatOfConditional5(E1, T1, E2, T2)
          requires notBool (T1 =/=Type T2 andBool (isCPPClassType(T1) orBool isCPPClassType(T2))) [owise]

     syntax KItem ::= typeAndCatOfConditional5(Expr, CPPType, Expr, CPPType) [function]
     rule typeAndCatOfConditional5(_, (T:CPPFunctionType => type(pointerType(T))), _, _)
     rule typeAndCatOfConditional5(_, _, _, (T:CPPFunctionType => type(pointerType(T))))
     rule typeAndCatOfConditional5(_, (T:CPPArrayType => type(pointerType(innerType(T)))), _, _)
     rule typeAndCatOfConditional5(_, _, _, (T:CPPArrayType => type(pointerType(innerType(T)))))
     rule typeAndCatOfConditional5(_, (T::CPPType => utype(T)), _, _)
          requires notBool isCPPClassType(T) andBool getQuals(T) =/=K noQuals
     rule typeAndCatOfConditional5(_, _, _, (T::CPPType => utype(T)))
          requires notBool isCPPClassType(T) andBool getQuals(T) =/=K noQuals
     rule typeAndCatOfConditional5(E1::Expr, T1::CPPType, E2::Expr, T2::CPPType)
          => typeAndCatOfConditional6(E1, T1, E2, T2) [owise]

     syntax KItem ::= typeAndCatOfConditional6(Expr, CPPType, Expr, CPPType) [function]
     rule typeAndCatOfConditional6(_, T1::CPPType, _, T2::CPPType)
          => typeAndCat(T1, prvalue)
          requires T1 ==Type T2
     rule typeAndCatOfConditional6(_, T1::CPPType, _, T2::CPPType)
          => typeAndCat(usualArithmeticConversions(T1, T2), prvalue)
          requires (isCPPArithmeticType(T1) orBool isCPPEnumType(T1)) andBool (isCPPArithmeticType(T2) orBool isCPPEnumType(T2))
     // TODO(dwightguth): 5.16:6.3-4
     rule typeAndCatOfConditional6(_, T:CPPNullPtrTType, _, _:CPPNullPtrTType)
          => typeAndCat(T, prvalue)
     rule typeAndCatOfConditional6(_, T:CPPNullPtrTType, IntegerLiteral(0, _), _)
          => typeAndCat(T, prvalue)
     rule typeAndCatOfConditional6(IntegerLiteral(0, _), _, _, T:CPPNullPtrTType)
          => typeAndCat(T, prvalue)

endmodule
