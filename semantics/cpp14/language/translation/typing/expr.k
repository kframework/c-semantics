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
     syntax TypeExpr ::= Expr | CPPDType | Typed

endmodule

module CPP-TYPING-EXPR
     imports CPP-TYPING-EXPR-SYNTAX
     imports K-REFLECTION
     imports STRING
     imports COMPAT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-EXPR-CONDITIONAL-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-SYNTAX
     imports CPP-VALUE-CATEGORY-SYNTAX
     imports C-CONFIGURATION
     imports CPP-CLASS-SYNTAX
     imports CPP-SYMLOC-SYNTAX

     syntax STypeList ::= toSTypeList(List) [function]
     syntax List ::= ofSTypeList(STypeList) [function]
     syntax KItem ::= "types()"
     rule types(list(HOLE:List)) => toSTypeList(HOLE) ~> types() [heat]
     rule HOLE:STypeList ~> types() => types(krlist(ofSTypeList(HOLE))) [cool]

     syntax STypeList ::= K "types::" STypeList
                     | ".STypeList"
     rule isKResult(.STypeList) => true
     rule isKResult(S1:K types:: S2::STypeList) => isCPPType(S1) andBool isKResult(S2)
     rule toSTypeList(ListItem(K:K) L::List) => K types:: toSTypeList(L)
     rule toSTypeList(.List) => .STypeList
     rule ofSTypeList(krlist(L1::List) types:: L2::STypeList) => L1 ofSTypeList(L2)
     rule ofSTypeList(.STypeList) => .List
     rule ofSTypeList(K:K types:: L::STypeList) => ListItem(K) ofSTypeList(L) [owise]

     rule (I:Init => t(noQuals, .Set, no-type)) types:: _
          requires notBool isExpr(I)

     context (HOLE:TypeExpr => typeof(HOLE)) types:: _ [result(CPPType)]
     context K:KResult types:: HOLE:STypeList

     // ----------------------------------

     rule typeof(ExprLoc(_, E::Expr) => E)

     rule typeof(StringLiteral(Ascii(), S::String) => type(arrayType(const(char), lengthString(S) +Int 1)))
     rule typeof(StringLiteral(UTF8(), S::String) => type(arrayType(const(char), lengthString(S) +Int 1)))
     rule typeof(StringLiteral(UTF16(), S::String) => type(arrayType(const(char16_t), lengthString(S) /Int byteSizeofType(type(char16_t)) +Int 1)))
     rule typeof(StringLiteral(UTF32(), S::String) => type(arrayType(const(char32_t), lengthString(S) /Int byteSizeofType(type(char32_t)) +Int 1)))
     rule typeof(StringLiteral(Wide(), S::String) => type(arrayType(const(wchar_t), lengthString(S) /Int byteSizeofType(type(wchar_t)) +Int 1)))
     rule typeof(BoolLiteral(_) => type(bool))
     rule typeof(CharacterLiteral(Ascii(), _) => type(char))
     rule typeof(CharacterLiteral(UTF8(), _) => type(char))
     rule typeof(CharacterLiteral(UTF16(), _) => type(char16_t))
     rule typeof(CharacterLiteral(UTF32(), _) => type(char32_t))
     rule typeof(CharacterLiteral(Wide(), _) => type(wchar_t))
     context typeof(IntegerLiteral(_, HOLE:AType))
     rule typeof(IntegerLiteral(_, T:CPPType) => T)
     context typeof(FloatingLiteral(_, HOLE:AType))
     rule typeof(FloatingLiteral(_, T:CPPType) => T)
     rule typeof(NullPointerLiteral() => type(nullptr_t))
     context typeof(HOLE:TypeExpr)
             requires getKLabel(HOLE) ==K #klabel(`Name`)
                  orBool getKLabel(HOLE) ==K #klabel(`CallExpr`) //[result(Val)]
                  orBool getKLabel(HOLE) ==K #klabel(`_.___CPP-SYNTAX`)
     rule typeof(T:Typed => type(T))

     rule typeof(SizeofExpr(_) => type(size_t))
     rule typeof(SizeofType(_) => type(size_t))
     rule typeof(SizeofPack(_) => type(size_t))
     rule typeof(AlignofExpr(_) => type(size_t))
     rule typeof(AlignofType(_) => type(size_t))

     context typeof(ParenthesizedCast(HOLE:AType, _))
     rule typeof(ParenthesizedCast(T:CPPType, _) => T)
          requires notBool isCPPRefType(T)
     rule typeof(ParenthesizedCast(T:CPPRefType, _) => innerType(T))
     context typeof(ReinterpretCast(HOLE:AType, _))
     rule typeof(ReinterpretCast(T:CPPType, _) => T)
          requires notBool isCPPRefType(T)
     rule typeof(ReinterpretCast(T:CPPRefType, _) => innerType(T))

     context typeof(FunctionalCast(HOLE:AType, _))
     // 5.2.3:2
     rule typeof(FunctionalCast(T:CPPType, .List) => T)
     // 5.2.3:1
     rule typeof(FunctionalCast(T::CPPType, ListItem(A::K)) => ParenthesizedCast(T, A))
     rule typeof(FunctionalCast(T:CPPType, ListItem(_) ListItem(_) _::List) => T)

     syntax TypeExpr ::= typeofField(TypeExpr, CId)
     rule typeof(E::Expr . no-template Name(NoNNS(), X:CId)) => typeofField(E, X)
     context typeofField((HOLE:TypeExpr => typeof(HOLE)), _) [result(CPPType)]
     rule <k> typeofField(t(_, _, classType(C::Class)), X:CId) => typeof(T) ...</k>
          <class-id> C </class-id>
          <cenv>... X |-> (T::CPPType |-> _:ClassOffset) ...</cenv>

     context typeof(NewExpr(HOLE:AType, _, _, _))
     rule typeof(NewExpr(T:CPPType, _, _, _) => type(pointerType(T)))
          requires notBool isCPPArrayType(T)
     rule typeof(NewExpr(T:CPPArrayType, _, _, _) => type(pointerType(innerType(T))))

     rule typeof(ConditionalOperator(_, E2::Expr, E3::Expr))
          => typeofConditional(E2, E3)

     rule typeof(UnaryOperator(O::OpId, E1::Expr))
          => typeofOperator(O, E1)

     rule typeof(BinaryOperator(O::OpId, E1::Expr, E2::Init))
          => typeofOperator(O, E1, E2)
     syntax KItem ::= typeofOperator(OpId, TypeExpr, K)
                    | typeofOperator(OpId, TypeExpr)
                    | typeofBuiltinOperator(OpId, TypeExpr, TypeExpr)
                    | typeofBuiltinOperator(OpId, TypeExpr)
                    | typeofConditional(Expr, Expr)

     syntax CPPDType ::= dataMember(Class, CPPType)
     context typeofOperator(_, (HOLE:TypeExpr => typeof(HOLE)), _) [result(CPPDType)]
     context typeofOperator(_, (HOLE:TypeExpr => typeof(HOLE))) [result(CPPDType)]
     context typeofOperator(_, _, (HOLE:TypeExpr => typeof(HOLE))) [result(CPPDType)]
     rule typeofOperator(O::OpId, T1:CPPDType, T2:CPPDType)
          => typeofBuiltinOperator(O, T1, T2)
          requires notBool isCPPClassType(T1) andBool notBool isCPPClassType(T2)
               andBool notBool isCPPEnumType(T1) andBool notBool isCPPEnumType(T2)
     rule typeofOperator(O::OpId, T1:CPPDType)
          => typeofBuiltinOperator(O, T1)
          requires notBool isCPPClassType(T1) andBool notBool isCPPEnumType(T1)

     rule typeofBuiltinOperator(operator=, T::CPPType, _)
          => typeof(T)
     rule typeofBuiltinOperator(operator||, _, _)
          => typeof(type(bool))
     rule typeofBuiltinOperator(operator&&, _, _)
          => typeof(type(bool))
     rule typeofBuiltinOperator(operator==, _, _)
          => typeof(type(bool))
     rule typeofBuiltinOperator(operator!=, _, _)
          => typeof(type(bool))
     rule typeofBuiltinOperator(operator<, _, _)
          => typeof(type(bool))
     rule typeofBuiltinOperator(operator<=, _, _)
          => typeof(type(bool))
     rule typeofBuiltinOperator(operator>, _, _)
          => typeof(type(bool))
     rule typeofBuiltinOperator(operator>=, _, _)
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

     rule typeofBuiltinOperator(operator+, T1::CPPType, T2::CPPType)
          => typeof(usualArithmeticConversions(T1, T2))
          requires (isCPPArithmeticType(T1) orBool isCPPUnscopedEnumType(T1)) andBool (isCPPArithmeticType(T2) orBool isCPPUnscopedEnumType(T2))
     rule typeofBuiltinOperator(operator+, T:CPPPointerType, _)
          => typeof(T)
     rule typeofBuiltinOperator(operator+, T:CPPArrayType, _)
          => typeof(type(pointerType(innerType(T))))
     rule typeofBuiltinOperator(operator+, _, T:CPPPointerType)
          => typeof(T)
     rule typeofBuiltinOperator(operator+, _, T:CPPArrayType)
          => typeof(type(pointerType(innerType(T))))
     rule typeofBuiltinOperator(operator-, T1::CPPType, T2::CPPType)
          => typeof(usualArithmeticConversions(T1, T2))
          requires (isCPPArithmeticType(T1) orBool isCPPUnscopedEnumType(T1)) andBool (isCPPArithmeticType(T2) orBool isCPPUnscopedEnumType(T2))
     rule typeofBuiltinOperator(operator-, T:CPPPointerType, _)
          => typeof(T)
     rule typeofBuiltinOperator(operator-, _:CPPPointerType, _:CPPPointerType)
          => typeof(type(ptrdiff_t))
     rule typeofBuiltinOperator(operator&, T1::CPPType, T2::CPPType)
          => typeof(usualArithmeticConversions(T1, T2))
     rule typeofBuiltinOperator(operator|, T1::CPPType, T2::CPPType)
          => typeof(usualArithmeticConversions(T1, T2))
     rule typeofBuiltinOperator(operator^, T1::CPPType, T2::CPPType)
          => typeof(usualArithmeticConversions(T1, T2))
     rule typeofBuiltinOperator(operator<<, T:CPPType, _)
          => typeof(promote(T))
     rule typeofBuiltinOperator(operator>>, T:CPPType, _)
          => typeof(promote(T))

     rule typeofBuiltinOperator(operator-, T::CPPType)
          => typeof(promote(T))
     rule typeofBuiltinOperator(operator+, T::CPPType)
          => typeof(promote(T))
     rule typeofBuiltinOperator(operator++_, T::CPPType)
          => typeof(T)
     rule typeofBuiltinOperator(operator--_, T::CPPType)
          => typeof(T)
     rule typeofBuiltinOperator(operator_++, T::CPPType)
          => typeof(T)
     rule typeofBuiltinOperator(operator_--, T::CPPType)
          => typeof(T)
     rule typeofBuiltinOperator(operator&, T:CPPType)
          => typeof(type(pointerType(T)))
     rule typeofBuiltinOperator(operator*, T::CPPType)
          => typeof(innerType(T))
     rule typeofBuiltinOperator(operator&, dataMember(C::Class, T::CPPType))
          => typeof(type(memberPointerType(t(noQuals, .Set, classType(C)), T)))
     rule type(dataMemberValue(memberPointer(C::Class, _, T::CPPType), _, _)) => dataMember(C, T)

     rule (.K => typeAndCatOfConditional(E2, E2, E2, E3, E3, E3)) ~> typeofConditional(E2::Expr, E3::Expr)
     rule typeAndCat(T:CPPType, _) ~> typeofConditional(_, _) => typeof(T)

endmodule
