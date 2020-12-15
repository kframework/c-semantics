module CPP-TRANSLATION-TYPING-EXPR-SORTS
     syntax TypeExpr
endmodule

module CPP-TRANSLATION-TYPING-EXPR-SYNTAX
     imports CPP-TRANSLATION-TYPING-EXPR-SORTS
     imports COMPAT-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-SORTS
     imports CPP-TYPING-SORTS

     syntax StrictList ::= types(StrictList)

     syntax TypeExpr ::= typeof(TypeExpr)

     syntax TypeExpr ::= Expr | CPPDType | Typed

endmodule

module CPP-TRANSLATION-TYPING-EXPR
     imports CPP-TRANSLATION-TYPING-EXPR-SYNTAX
     imports C-CONFIGURATION
     imports K-REFLECTION
     imports STRING
     imports COMPAT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-CLASS-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-TRANSLATION-EXPR-CONDITIONAL-SYNTAX
     imports CPP-TRANSLATION-OVERLOADING-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TRANSLATION-NAME-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-TRANSLATION-VALUE-CATEGORY-SYNTAX

     syntax STypeList ::= toSTypeList(List) [function]

     syntax List ::= ofSTypeList(STypeList) [function]

     syntax KItem ::= "types()"

     rule types(list(HOLE:List)) => toSTypeList(HOLE) ~> types() [heat]

     rule HOLE:STypeList ~> types() => types(krlist(ofSTypeList(HOLE))) [cool]

     syntax STypeList ::= K "types::" STypeList
                     | ".STypeList"

     rule isKResult(.STypeList) => true

     rule isKResult(S1:K types:: S2::STypeList) => isCPPDType(S1) andBool isKResult(S2)

     rule toSTypeList(ListItem(K:KItem) L::List) => K types:: toSTypeList(L)

     rule toSTypeList(.List) => .STypeList

     rule ofSTypeList(krlist(L1::List) types:: L2::STypeList) => L1 ofSTypeList(L2)

     rule ofSTypeList(.STypeList) => .List

     rule ofSTypeList(K:KItem types:: L::STypeList) => ListItem(K) ofSTypeList(L) [owise]

     rule (ExprLoc(_, BraceInit(L::List)) => BraceInit(L)) types:: _

     rule (.K => types(list(L))) ~> BraceInit(L::List) types:: _

     rule (types(krlist(L::List)) => .K) ~> (BraceInit(_) => initListType(L)) types:: _

     rule (NoInit() => NoInitType()) types:: _

     syntax KResult ::= NoInitType

     context (HOLE:TypeExpr => typeof(HOLE)) types:: _
          requires notBool isSpuriousExpr(HOLE) [result(CPPDType)]

     context _:KResult types:: HOLE:STypeList

     // ----------------------------------

     rule typeof(ExprLoc(_, E:Expr) => E)

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
             requires Name(_, _) :=K HOLE
                  orBool CallExpr(_, _, _) :=K HOLE
                  orBool _ . _ _ :=K HOLE
                  orBool & _ :=K HOLE

     rule typeof(T:Typed => type(T))

     rule <k> typeof(This() => type(V)) ...</k>
          <tr-this> V:PRVal </tr-this>

     rule typeof(SizeofExpr(_) => type(size_t))

     rule typeof(SizeofType(_) => type(size_t))

     rule typeof(SizeofPack(_) => type(size_t))

     rule typeof(AlignofExpr(_) => type(size_t))

     rule typeof(AlignofType(_) => type(size_t))

     context typeof(ParenthesizedCast(HOLE:AType, _))

     rule typeof(ParenthesizedCast(T:CPPType, _) => T)
          requires notBool isCPPRefType(T)

     rule typeof(ParenthesizedCast(cppRefType #as T::CPPType, _) => innerType(T))

     context typeof(ReinterpretCast(HOLE:AType, _))

     rule typeof(ReinterpretCast(T:CPPType, _) => T)
          requires notBool isCPPRefType(T)

     rule typeof(ReinterpretCast(cppRefType #as T::CPPType, _) => innerType(T))

     context typeof(StaticCast(HOLE:AType, _))

     rule typeof(StaticCast(T:CPPType, _) => T)
          requires notBool isCPPRefType(T)

     rule typeof(StaticCast(cppRefType #as T::CPPType, _) => innerType(T))

     context typeof(FunctionalCast(HOLE:AType, _))

     // @ref n4296 5.2.3:2
     rule typeof(FunctionalCast(T:CPPType, .List) => T)

     // @ref n4296 5.2.3:1
     rule typeof(FunctionalCast(T::CPPType, ListItem(A::Expr)) => ParenthesizedCast(T, A))

     rule typeof(FunctionalCast(T:CPPType, ListItem(_) ListItem(_) _::List) => T)

     context typeof(NewExpr(_, HOLE:AType, _, _, _))

     rule typeof(NewExpr(_, T:CPPType, _, _, _) => type(pointerType(T)))
          requires notBool isCPPArrayType(T)

     rule typeof(NewExpr(_, t(... st: _:CPPSimpleArrayType) #as T::CPPType, _, _, _) => type(pointerType(innerType(T))))

     rule typeof(Throw(_) => type(void))

     rule typeof(exceptionObject(T::CPPType) => T)

     rule typeof(ConditionalOperator(_, E2::Expr, E3::Expr))
          => typeofConditional(E2, E3)

     rule (.K => typeofOperator(O, E1, E1)) ~> typeof(UnaryOperator(O::OpId, E1::Expr))

     rule (.K => typeofOperator(O, E1, E1, E2)) ~> typeof(BinaryOperator(O::OpId, E1::Expr, E2::Init))

     syntax KItem ::= typeofOperator(OpId, TypeExpr, Expr, K)
                    | typeofOperator(OpId, TypeExpr, Expr)
                    | typeofBuiltinOperator(OpId, TypeExpr, Expr)
                    | typeofBuiltinOperator(OpId, TypeExpr, Expr, K)
                    | #typeofBuiltinOperator(OpId, TypeExpr, Expr)
                    | #typeofBuiltinOperator(OpId, TypeExpr, Expr, TypeExpr)
                    | typeofConditional(Expr, Expr)

     syntax CPPDType ::= dataMember(Class, CPPType)

     context typeofOperator(_, (HOLE:TypeExpr => typeof(HOLE)), _, _) [result(CPPDType)]

     context typeofOperator(O::OpId, _, _, (HOLE:TypeExpr => typeof(HOLE)))
             requires notBool O ==K operator-> [result(CPPDType)]

     context typeofOperator(_, (HOLE:TypeExpr => typeof(HOLE)), _) [result(CPPDType)]

     context typeofBuiltinOperator(_, (HOLE:TypeExpr => typeof(HOLE)), _, _) [result(CPPDType)]

     context typeofBuiltinOperator(O::OpId, _, _, (HOLE:TypeExpr => typeof(HOLE)))
             requires notBool O ==K operator-> [result(CPPDType)]

     context typeofBuiltinOperator(_, (HOLE:TypeExpr => typeof(HOLE)), _) [result(CPPDType)]

     rule typeofOperator(O::OpId, T1:CPPDType, E::Expr, T2:CPPDType) ~> typeof(_)
          => #typeofBuiltinOperator(O, T1, E, T2)
          requires notBool isCPPClassType(T1) andBool notBool isCPPClassType(T2)
               andBool notBool isCPPEnumType(T1) andBool notBool isCPPEnumType(T2)

     rule typeofOperator(O::OpId, T1:CPPDType, E::Expr) ~> typeof(_)
          => #typeofBuiltinOperator(O, T1, E)
          requires notBool isCPPClassType(T1) andBool notBool isCPPEnumType(T1)

     rule typeofOperator(operator->, T1:CPPDType, E1::Expr, E2::Expr) ~> typeof(_)
          => #typeofBuiltinOperator(operator->, T1, E1, E2)
          requires notBool isCPPClassType(T1) andBool notBool isCPPEnumType(T1)

     rule typeofOperator(O::OpId, T1:CPPDType, _) ~> typeof(UnaryOperator(_, E1::Expr))
          => typeof(resolveOverloadedOperator(O, E1, T1))
          requires isCPPClassType(T1) orBool isCPPEnumType(T1)

     rule typeofOperator(O::OpId, T1:CPPDType, _, T2:CPPDType) ~> typeof(BinaryOperator(_, E1::Expr, E2::Init))
          => typeof(resolveOverloadedOperator(O, E1, T1, E2, T2))
          requires isCPPClassType(T1) orBool isCPPClassType(T2)
               orBool isCPPEnumType(T1) orBool isCPPEnumType(T2)

     rule typeof(resolveOverloadedOperator(_, _, _) #as X:Expr)
          => X ~> typeofResolveOverloadedOperatorFreezer()

     rule typeof(resolveOverloadedOperator(_, _, _, _, _) #as X:Expr)
          => X ~> typeofResolveOverloadedOperatorFreezer()

     rule resolveOverloadResult(X:Expr) ~> typeofResolveOverloadedOperatorFreezer()
          => typeof(X)

     syntax KItem ::= typeofResolveOverloadedOperatorFreezer()

     rule typeofBuiltinOperator(O::OpId, T1:CPPDType, E::Expr, T2:CPPDType)
          => #typeofBuiltinOperator(O, T1, E, T2)

     rule typeofBuiltinOperator(O::OpId, T1:CPPDType, E::Expr)
          => #typeofBuiltinOperator(O, T1, E)

     rule #typeofBuiltinOperator(operator=, T::CPPType, _, _) => typeof(T)

     rule #typeofBuiltinOperator(operator||, _, _, _) => typeof(type(bool))

     rule #typeofBuiltinOperator(operator&&, _, _, _) => typeof(type(bool))

     rule #typeofBuiltinOperator(operator==, _, _, _) => typeof(type(bool))

     rule #typeofBuiltinOperator(operator!=, _, _, _) => typeof(type(bool))

     rule #typeofBuiltinOperator(operator<, _, _, _) => typeof(type(bool))

     rule #typeofBuiltinOperator(operator<=, _, _, _) => typeof(type(bool))

     rule #typeofBuiltinOperator(operator>, _, _, _) => typeof(type(bool))

     rule #typeofBuiltinOperator(operator>=, _, _, _) => typeof(type(bool))

     rule #typeofBuiltinOperator(operator+=, T::CPPType, _, _) => typeof(T)

     rule #typeofBuiltinOperator(operator-=, T::CPPType, _, _) => typeof(T)

     rule #typeofBuiltinOperator(operator*=, T::CPPType, _, _) => typeof(T)

     rule #typeofBuiltinOperator(operator/=, T::CPPType, _, _) => typeof(T)

     rule #typeofBuiltinOperator(operator%=, T::CPPType, _, _) => typeof(T)

     rule #typeofBuiltinOperator(operator^=, T::CPPType, _, _) => typeof(T)

     rule #typeofBuiltinOperator(operator&=, T::CPPType, _, _) => typeof(T)

     rule #typeofBuiltinOperator(operator|=, T::CPPType, _, _) => typeof(T)

     rule #typeofBuiltinOperator(operator<<=, T::CPPType, _, _) => typeof(T)

     rule #typeofBuiltinOperator(operator>>=, T::CPPType, _, _) => typeof(T)

     rule #typeofBuiltinOperator(operator[], t(... st: _:CPPSimpleArrayType) #as T::CPPType, _, _) => typeof(innerType(T))

     rule #typeofBuiltinOperator(operator[], t(... st: pointerType(...)) #as T::CPPType, _, _) => typeof(innerType(T))

     rule #typeofBuiltinOperator(operator[], _, _, t(... st: _:CPPSimpleArrayType) #as T::CPPType) => typeof(innerType(T))

     rule #typeofBuiltinOperator(operator[], _, _, t(... st: pointerType(...)) #as T::CPPType) => typeof(innerType(T))

     rule #typeofBuiltinOperator(operator->, t(... st: pointerType(...)) #as _::CPPType, E1::Expr, E2::Name)
          => typeof((* E1) . no-template E2)

     rule #typeofBuiltinOperator(operator+, T1::CPPType, _, T2::CPPType)
          => typeof(usualArithmeticConversions(T1, T2))
          requires (isCPPArithmeticType(T1) orBool isCPPUnscopedEnumType(T1)) andBool (isCPPArithmeticType(T2) orBool isCPPUnscopedEnumType(T2))

     rule #typeofBuiltinOperator(operator+, t(... st: pointerType(...)) #as T::CPPType, _, _) => typeof(T)

     rule #typeofBuiltinOperator(operator+, t(... st: _:CPPSimpleArrayType) #as T::CPPType, _, _) => typeof(revalType(T))

     rule #typeofBuiltinOperator(operator+, _, _, t(... st: pointerType(...)) #as T::CPPType) => typeof(T)

     rule #typeofBuiltinOperator(operator+, _, _, t(... st: _:CPPSimpleArrayType) #as T::CPPType) => typeof(revalType(T))

     rule #typeofBuiltinOperator(operator-, T1::CPPType, _, T2::CPPType)
          => typeof(usualArithmeticConversions(T1, T2))
          requires (isCPPArithmeticType(T1) orBool isCPPUnscopedEnumType(T1)) andBool (isCPPArithmeticType(T2) orBool isCPPUnscopedEnumType(T2))

     rule #typeofBuiltinOperator(operator-, t(... st: pointerType(...)) #as T::CPPType, _, _) => typeof(T)

     rule #typeofBuiltinOperator(operator-, t(... st: _:CPPSimpleArrayType) #as T::CPPType, _, _) => typeof(revalType(T))

     rule #typeofBuiltinOperator(operator-, t(... st: pointerType(...)), _, t(... st: pointerType(...)))
          => typeof(type(ptrdiff_t))

     rule #typeofBuiltinOperator(operator-, t(... st: pointerType(...)), _, t(... st: _:CPPSimpleArrayType))
          => typeof(type(ptrdiff_t))

     rule #typeofBuiltinOperator(operator-, t(... st: _:CPPSimpleArrayType), _, t(... st: pointerType(...)))
          => typeof(type(ptrdiff_t))

     rule #typeofBuiltinOperator(operator-, t(... st: _:CPPSimpleArrayType), _, t(... st: _:CPPSimpleArrayType))
          => typeof(type(ptrdiff_t))

     rule #typeofBuiltinOperator(operator*, T1::CPPType, _, T2::CPPType)
          => typeof(usualArithmeticConversions(T1, T2))

     rule #typeofBuiltinOperator(operator/, T1::CPPType, _, T2::CPPType)
          => typeof(usualArithmeticConversions(T1, T2))

     rule #typeofBuiltinOperator(operator%, T1::CPPType, _, T2::CPPType)
          => typeof(usualArithmeticConversions(T1, T2))

     rule #typeofBuiltinOperator(operator&, T1::CPPType, _, T2::CPPType)
          => typeof(usualArithmeticConversions(T1, T2))

     rule #typeofBuiltinOperator(operator|, T1::CPPType, _, T2::CPPType)
          => typeof(usualArithmeticConversions(T1, T2))

     rule #typeofBuiltinOperator(operator^, T1::CPPType, _, T2::CPPType)
          => typeof(usualArithmeticConversions(T1, T2))

     rule #typeofBuiltinOperator(operator<<, T:CPPType, _, _)
          => typeof(promote(promote(T)))

     rule #typeofBuiltinOperator(operator>>, T:CPPType, _, _)
          => typeof(promote(promote(T)))

     rule #typeofBuiltinOperator(operator,, _, _, T:CPPType)
          => typeof(T)

     rule #typeofBuiltinOperator(operator-, T::CPPType, _) => typeof(promote(T))

     rule #typeofBuiltinOperator(operator+, T::CPPType, _) => typeof(promote(T))

     rule #typeofBuiltinOperator(operator++_, T::CPPType, _) => typeof(T)

     rule #typeofBuiltinOperator(operator--_, T::CPPType, _) => typeof(T)

     rule #typeofBuiltinOperator(operator_++, T::CPPType, _) => typeof(revalType(T))

     rule #typeofBuiltinOperator(operator_--, T::CPPType, _) => typeof(revalType(T))

     rule #typeofBuiltinOperator(operator&, _, E::Expr) => typeof(& E)

     rule #typeofBuiltinOperator(operator*, T::CPPType, _) => typeof(innerType(T))

     rule #typeofBuiltinOperator(operator!, _, _) => typeof(type(bool))

     rule (.K => typeAndCatOfConditional(E2, E3)) ~> typeofConditional(E2::Expr, E3::Expr)

     rule typeAndCat(T:CPPType, _) ~> typeofConditional(_, _) => typeof(T)

     // boilerplate rules for computing type when the C++ semantics
     // references a builtin construct directly
     rule typeof(E1::Expr := E2::Init) => typeofBuiltinOperator(operator=, E1, E1, E2)

     rule typeof(E1::Expr[E2::Expr]) => typeofBuiltinOperator(operator[], E1, E1, E2)

     rule typeof(E1::Expr-> _ E2::Name) => typeofBuiltinOperator(operator->, E1, E1, E2)

     rule typeof(E1::Expr + E2::Expr) => typeofBuiltinOperator(operator+, E1, E1, E2)

     rule typeof(E1::Expr - E2::Expr) => typeofBuiltinOperator(operator-, E1, E1, E2)

     rule typeof(E1::Expr * E2::Expr) => typeofBuiltinOperator(operator*, E1, E1, E2)

     rule typeof(E1::Expr / E2::Expr) => typeofBuiltinOperator(operator/, E1, E1, E2)

     rule typeof(E1::Expr % E2::Expr) => typeofBuiltinOperator(operator%, E1, E1, E2)

     rule typeof(E1::Expr || E2::Expr) => typeofBuiltinOperator(operator||, E1, E1, E2)

     rule typeof(E1::Expr && E2::Expr) => typeofBuiltinOperator(operator&&, E1, E1, E2)

     rule typeof(E1::Expr & E2::Expr) => typeofBuiltinOperator(operator&, E1, E1, E2)

     rule typeof(E1::Expr | E2::Expr) => typeofBuiltinOperator(operator|, E1, E1, E2)

     rule typeof(E1::Expr ^ E2::Expr) => typeofBuiltinOperator(operator^, E1, E1, E2)

     rule typeof(E1::Expr == E2::Expr) => typeofBuiltinOperator(operator==, E1, E1, E2)

     rule typeof(E1::Expr != E2::Expr) => typeofBuiltinOperator(operator!=, E1, E1, E2)

     rule typeof(E1::Expr < E2::Expr) => typeofBuiltinOperator(operator<, E1, E1, E2)

     rule typeof(E1::Expr <= E2::Expr) => typeofBuiltinOperator(operator<=, E1, E1, E2)

     rule typeof(E1::Expr > E2::Expr) => typeofBuiltinOperator(operator>, E1, E1, E2)

     rule typeof(E1::Expr >= E2::Expr) => typeofBuiltinOperator(operator>=, E1, E1, E2)

     rule typeof(E1::Expr += E2::Expr) => typeofBuiltinOperator(operator+=, E1, E1, E2)

     rule typeof(E1::Expr -= E2::Expr) => typeofBuiltinOperator(operator-=, E1, E1, E2)

     rule typeof(E1::Expr *= E2::Expr) => typeofBuiltinOperator(operator*=, E1, E1, E2)

     rule typeof(E1::Expr /= E2::Expr) => typeofBuiltinOperator(operator/=, E1, E1, E2)

     rule typeof(E1::Expr %= E2::Expr) => typeofBuiltinOperator(operator%=, E1, E1, E2)

     rule typeof(E1::Expr ^= E2::Expr) => typeofBuiltinOperator(operator^=, E1, E1, E2)

     rule typeof(E1::Expr &= E2::Expr) => typeofBuiltinOperator(operator&=, E1, E1, E2)

     rule typeof(E1::Expr |= E2::Expr) => typeofBuiltinOperator(operator|=, E1, E1, E2)

     rule typeof(E1::Expr << E2::Expr) => typeofBuiltinOperator(operator<<, E1, E1, E2)

     rule typeof(E1::Expr >> E2::Expr) => typeofBuiltinOperator(operator>>, E1, E1, E2)

     rule typeof(E1::Expr <<= E2::Expr) => typeofBuiltinOperator(operator<<=, E1, E1, E2)

     rule typeof(E1::Expr >>= E2::Expr) => typeofBuiltinOperator(operator>>=, E1, E1, E2)

     rule typeof(Comma(E1::Expr, E2::Expr)) => typeofBuiltinOperator(operator,, E1, E1, E2)

     rule typeof(E1::Expr ++) => typeofBuiltinOperator(operator_++, E1, E1)

     rule typeof(E1::Expr --) => typeofBuiltinOperator(operator_--, E1, E1)

     rule typeof(++ E1::Expr) => typeofBuiltinOperator(operator++_, E1, E1)

     rule typeof(-- E1::Expr) => typeofBuiltinOperator(operator--_, E1, E1)

     rule typeof(! E1::Expr) => typeofBuiltinOperator(operator!, E1, E1)

     rule typeof(- E1::Expr) => typeofBuiltinOperator(operator-, E1, E1)

     // not used because we want to use name resolution mechanism to resolve builtin address operator
     //rule typeof(& E1::Expr) => typeofBuiltinOperator(operator&, E1)
     rule typeof(* E1::Expr) => typeofBuiltinOperator(operator*, E1, E1)

     context GnuEnumUnderlyingType2(HOLE:AType, _) [result(CPPType)]

     rule GnuEnumUnderlyingType2(cppEnumType #as T::CPPType, _) => underlyingType(T)

     rule TypeofExpression(E::Expr) => typeofExpr(E)

     context TypeofType(HOLE:AType) [result(CPPType)]

     rule TypeofType(T:CPPType) => T

     syntax Expr ::= typeofExpr(TypeExpr)

     context typeofExpr(HOLE:TypeExpr => typeof(HOLE)) [result(CPPType)]

     rule typeofExpr(T:CPPType) => T

endmodule
