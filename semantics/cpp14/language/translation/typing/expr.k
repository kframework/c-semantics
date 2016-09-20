module CPP-TYPING-EXPR-SORTS
     syntax TypeExpr
endmodule

module CPP-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-EXPR-SORTS
     imports COMPAT-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-SORTS
     imports CPP-TYPING-SORTS

     syntax StrictList ::= types(StrictList)
     syntax TypeExpr ::= typeof(TypeExpr)
     syntax TypeExpr ::= Expr | CPPType | Typed

endmodule

module CPP-TYPING-EXPR
     imports CPP-TYPING-EXPR-SYNTAX
     imports K-REFLECTION
     imports STRING
     imports COMPAT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-EXPR-CONDITIONAL-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-SYNTAX
     imports CPP-VALUE-CATEGORY-SYNTAX

     syntax STypeList ::= toSTypeList(List) [function]
     syntax List ::= ofSTypeList(STypeList) [function]
     syntax KItem ::= "types()"
     rule types(list(HOLE:List)) => toSTypeList(HOLE) ~> types() [heat]
     rule HOLE:STypeList ~> types() => types(krlist(ofSTypeList(HOLE))) [cool]

     syntax STypeList ::= K "types::" STypeList
                     | ".STypeList"
     rule isKResult(.STypeList) => true
     rule isKResult(S1::STypeList types:: S2::STypeList) => isKResult(S1) andBool isKResult(S2)
     rule toSTypeList(ListItem(K:K) L::List) => K types:: toSTypeList(L)
     rule toSTypeList(.List) => .STypeList
     rule ofSTypeList(krlist(L1::List) types:: L2::STypeList) => L1 ofSTypeList(L2)
     rule ofSTypeList(.STypeList) => .List
     rule ofSTypeList(K:K types:: L::STypeList) => ListItem(K) ofSTypeList(L) [owise]

     context (HOLE:TypeExpr => typeof(HOLE)) types:: _ [result(CPPType)]
     context K:KResult types:: HOLE:STypeList

     // ----------------------------------

     rule typeof(StringLiteral(Ascii(), S::String) => type(arrayType(const(char), lengthString(S) +Int 1)))
     rule typeof(BoolLiteral(_) => type(bool))
     rule typeof(CharacterLiteral(Ascii(), _) => type(char))
     context typeof(IntegerLiteral(_, HOLE:AType))
     rule typeof(IntegerLiteral(_, T:CPPType) => T)
     rule typeof(NullPointerLiteral() => type(nullptr_t))
     context typeof(HOLE:TypeExpr)
             requires getKLabel(HOLE) ==K #klabel(`Name`)
                  orBool getKLabel(HOLE) ==K #klabel(`CallExpr`) [result(Val)]
     rule typeof(T:Typed => type(T))

     rule typeof(SizeofExpr(_) => type(size_t))
     rule typeof(SizeofType(_) => type(size_t))
     rule typeof(SizeofPack(_) => type(size_t))

     context typeof(ParenthesizedCast(HOLE:AType, _))
     rule typeof(ParenthesizedCast(T:CPPType, _) => T)

     rule typeof(ConditionalOperator(_, E2::Expr, E3::Expr))
          => typeofConditional(E2, E3)

     rule typeof(BinaryOperator(O::OpId, E1::Expr, E2::Init))
          => typeofOperator(O, E1, E2)
     syntax KItem ::= typeofOperator(OpId, TypeExpr, K)
                    | typeofBuiltinOperator(OpId, TypeExpr, TypeExpr)
                    | typeofConditional(Expr, Expr)
     context typeofOperator(_, (HOLE:TypeExpr => typeof(HOLE)), _) [result(CPPType)]
     context typeofOperator(_, _, (HOLE:TypeExpr => typeof(HOLE))) [result(CPPType)]
     rule typeofOperator(O::OpId, T1:CPPType, T2:CPPType)
          => typeofBuiltinOperator(O, T1, T2)
          requires notBool isCPPClassType(T1) andBool notBool isCPPClassType(T2)
               andBool notBool isCPPEnumType(T1) andBool notBool isCPPEnumType(T2)

     rule typeofBuiltinOperator(operator=, T::CPPType, _)
          => typeof(T)
     rule typeofBuiltinOperator(operator||, _, _)
          => typeof(type(bool))
     rule typeofBuiltinOperator(operator==, _, _)
          => typeof(type(bool))
     rule typeofBuiltinOperator(operator!=, _, _)
          => typeof(type(bool))
     rule typeofBuiltinOperator(operator*, T1::CPPType, T2::CPPType)
          => typeof(usualArithmeticConversions(T1, T2))
     rule typeofBuiltinOperator(operator/, T1::CPPType, T2::CPPType)
          => typeof(usualArithmeticConversions(T1, T2))
     rule typeofBuiltinOperator(operator%, T1::CPPType, T2::CPPType)
          => typeof(usualArithmeticConversions(T1, T2))
     rule typeofBuiltinOperator(operator[], T:CPPArrayType, _)
          => typeof(innerType(T))
     rule typeofBuiltinOperator(operator[], T:CPPPointerType, _)
          => typeof(innerType(T))

     rule (.K => typeAndCatOfConditional(E2, E2, E2, E3, E3, E3)) ~> typeofConditional(E2::Expr, E3::Expr)
     rule typeAndCat(T:CPPType, _) ~> typeofConditional(_, _) => typeof(T)

endmodule
