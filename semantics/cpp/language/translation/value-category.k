module CPP-TRANSLATION-VALUE-CATEGORY-SORTS
     syntax CatExpr
endmodule

module CPP-TRANSLATION-VALUE-CATEGORY-SYNTAX
     imports CPP-TRANSLATION-VALUE-CATEGORY-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS

     syntax CatExpr ::= catof(CatExpr)

     syntax CatExpr ::= Expr | ValueCategory | Typed

     syntax Val ::= makeVal(ValueCategory, CPPType, CPPValue, Trace) [function]

     syntax Val ::= makeExpr(ValueCategory, CPPType, Expr, Trace) [function]

     syntax StrictList ::= cats(StrictList)

     syntax ValueCategory ::= unnamedCat(CPPType) [function]
endmodule

module CPP-TRANSLATION-VALUE-CATEGORY
     imports CPP-TRANSLATION-VALUE-CATEGORY-SYNTAX
     imports BOOL-SYNTAX
     imports K-REFLECTION
     imports COMPAT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TRANSLATION-EXPR-CONDITIONAL-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TRANSLATION-NAME-SYNTAX
     imports CPP-TRANSLATION-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SYNTAX

     syntax SCatList ::= toSCatList(List) [function]

     syntax List ::= ofSCatList(SCatList) [function]

     syntax KItem ::= "cats()"

     rule cats(list(HOLE:List)) => toSCatList(HOLE) ~> cats() [heat]

     rule HOLE:SCatList ~> cats() => cats(krlist(ofSCatList(HOLE))) [cool]

     syntax SCatList ::= K "cats::" SCatList
                     | ".SCatList"

     rule isKResult(.SCatList) => true

     rule isKResult(S1:K cats:: S2::SCatList) => isValueCategory(S1) andBool isKResult(S2)

     rule toSCatList(ListItem(K:KItem) L::List) => K cats:: toSCatList(L)

     rule toSCatList(.List) => .SCatList

     rule ofSCatList(krlist(L1::List) cats:: L2::SCatList) => L1 ofSCatList(L2)

     rule ofSCatList(.SCatList) => .List

     rule ofSCatList(K:K cats:: L::SCatList) => ListItem(K) ofSCatList(L) [owise]

     rule (ExprLoc(_, BraceInit(L::List)) => BraceInit(L)) cats:: _

     rule (.K => cats(list(L))) ~> BraceInit(L::List) cats:: _

     rule (cats(krlist(L::List)) => .K) ~> (BraceInit(_) => initListCat(L)) cats:: _

     rule (NoInit() => NoInitCat()) cats:: _

     context (HOLE:CatExpr => catof(HOLE)) cats:: _ [result(ValueCategory)]

     context K:KResult cats:: HOLE:SCatList

     // --------------------------------

     rule makeVal(lvalue, T::CPPType, V::SymLoc, Tr::Trace) => lv(V, Tr, T)

     rule makeVal(xvalue, T::CPPType, V::SymLoc, Tr::Trace) => xv(V, Tr, T)

     rule makeVal(prvalue, T::CPPType, V::CPPValue, Tr::Trace) => prv(V, Tr, T)

     rule makeExpr(lvalue, T::CPPType, V::Expr, Tr::Trace) => le(V, Tr, T)

     rule makeExpr(xvalue, T::CPPType, V::Expr, Tr::Trace) => xe(V, Tr, T)

     rule makeExpr(prvalue, T::CPPType, V::Expr, Tr::Trace) => pre(V, Tr, T)

     rule catof(ExprLoc(_, E::Expr) => E)

     rule catof(StringLiteral(_, _) => lvalue)

     rule catof(CharacterLiteral(_, _) => prvalue)

     rule catof(FloatingLiteral(_, _) => prvalue)

     rule catof(IntegerLiteral(_, _) => prvalue)

     rule catof(BoolLiteral(_) => prvalue)

     rule catof(NullPointerLiteral() => prvalue)

     context catof(HOLE:CatExpr)
             requires getKLabel(HOLE) ==K #klabel(`Name`)
                  orBool getKLabel(HOLE) ==K #klabel(`CallExpr`) //[result(Val)]
                  orBool getKLabel(HOLE) ==K #klabel(`_.___CPP-SYNTAX`)

     rule catof(L:LVal => lvalue)

     rule catof(X:XVal => xvalue)

     rule catof(PR:PRVal => prvalue)

     rule catof(AlignofExpr(_) => prvalue)

     rule catof(AlignofType(_) => prvalue)

     rule catof(NewExpr(...) => prvalue)

     rule catof(DeleteExpr(_, _, _) => prvalue)

     rule catof(SizeofType(_) => prvalue)

     rule catof(SizeofExpr(_) => prvalue)

     context catof(ParenthesizedCast(HOLE:AType, _))

     rule catof(ParenthesizedCast(T:CPPType, _) => unnamedCat(T))

     context catof(ReinterpretCast(HOLE:AType, _))

     rule catof(ReinterpretCast(T:CPPType, _) => unnamedCat(T))

     context catof(StaticCast(HOLE:AType, _))

     rule catof(StaticCast(T:CPPType, _) => unnamedCat(T))

     // 5.2.3:2
     rule catof(FunctionalCast(_, .List) => prvalue)

     // 5.2.3:1
     rule catof(FunctionalCast(T::AType, ListItem(A::Expr)) => ParenthesizedCast(T, A))

     rule catof(FunctionalCast(_, ListItem(_) ListItem(_) _::List) => prvalue)

     rule unnamedCat(T::CPPType) => #if isUnnamedLValue(T) #then lvalue #else #if isUnnamedXValue(T) #then xvalue #else prvalue #fi #fi

     rule catof(Throw(_) => prvalue)

     rule catof(exceptionObject(_) => lvalue)

     rule (.K => catofOperator(O, E1, E1, E2)) ~> catof(BinaryOperator(O::OpId, E1::Expr, E2::Init))

     rule (.K => catofOperator(O, E1)) ~> catof(UnaryOperator(O::OpId, E1::Expr))

     rule catof(ConditionalOperator(_, E2::Expr, E3::Expr))
          => catofConditional(E2, E3)

     syntax KItem ::= catofOperator(OpId, TypeExpr, CatExpr, K)
                    | catofOperator(OpId, TypeExpr)
                    | catofBuiltinOperator(OpId, TypeExpr)
                    | catofBuiltinOperator(OpId, TypeExpr, CatExpr, K)
                    | #catofBuiltinOperator(OpId, TypeExpr)
                    | #catofBuiltinOperator(OpId, TypeExpr, CatExpr, TypeExpr)
                    | catofConditional(Expr, Expr)

     context catofOperator(_, (HOLE:TypeExpr => typeof(HOLE)), _, _) [result(CPPDType)]

     context catofOperator(O::OpId, _, _, (HOLE:TypeExpr => typeof(HOLE)))
             requires O =/=K operator-> [result(CPPDType)]

     context catofOperator(O::OpId, _, (HOLE:CatExpr => catof(HOLE)), _)
             requires O =/=K operator-> [result(ValueCategory)]

     context catofOperator(_, (HOLE:TypeExpr => typeof(HOLE))) [result(CPPDType)]

     context catofBuiltinOperator(_, (HOLE:TypeExpr => typeof(HOLE)), _, _) [result(CPPDType)]

     context catofBuiltinOperator(O::OpId, _, _, (HOLE:TypeExpr => typeof(HOLE)))
             requires O =/=K operator-> [result(CPPDType)]

     context catofBuiltinOperator(O::OpId, _, (HOLE:CatExpr => catof(HOLE)), _)
             requires O =/=K operator-> [result(ValueCategory)]

     context catofBuiltinOperator(_, (HOLE:TypeExpr => typeof(HOLE))) [result(CPPDType)]

     rule catofOperator(O::OpId, T1:CPPDType, C:ValueCategory, T2:CPPDType) ~> catof(_)
          => #catofBuiltinOperator(O, T1, C, T2)
          requires notBool isCPPClassType(T1) andBool notBool isCPPClassType(T2)
               andBool notBool isCPPEnumType(T1) andBool notBool isCPPEnumType(T2)

     rule catofOperator(O::OpId, T1:CPPDType) ~> catof(_)
          => #catofBuiltinOperator(O, T1)
          requires notBool isCPPClassType(T1) andBool notBool isCPPEnumType(T1)

     rule catofOperator(operator->, T1:CPPDType, E1::Expr, E2::Expr) ~> catof(_)
          => #catofBuiltinOperator(operator->, T1, E1, E2)
          requires notBool isCPPClassType(T1) andBool notBool isCPPEnumType(T1)

     rule catofOperator(O::OpId, T1:CPPDType) ~> catof(UnaryOperator(_, E1::Expr))
          => catof(resolveOverloadedOperator(O, E1, T1))
          requires isCPPClassType(T1) orBool isCPPEnumType(T1)

     rule catofOperator(O::OpId, T1:CPPDType, _, T2:CPPDType) ~> catof(BinaryOperator(_, E1::Expr, E2::Expr))
          => catof(resolveOverloadedOperator(O, E1, T1, E2, T2))
          requires isCPPClassType(T1) orBool isCPPClassType(T2)
               orBool isCPPEnumType(T1) orBool isCPPEnumType(T2)

     // these contexts require the structural attribute to ensure that they always apply prior to the rules
     // for evaluating expressions. Otherwise we might evaluate too far even though this expression
     // is not potentially evaluated in this context.
     context catof(resolveOverloadedOperator(_, _, _) #as HOLE:Expr) [result(ResolvedExpr), structural]

     context catof(resolveOverloadedOperator(_, _, _, _, _) #as HOLE:Expr) [result(ResolvedExpr), structural]

     rule catofBuiltinOperator(O::OpId, T1:CPPDType, C:ValueCategory, T2:CPPDType)
          => #catofBuiltinOperator(O, T1, C, T2)

     rule catofBuiltinOperator(O::OpId, T1:CPPDType)
          => #catofBuiltinOperator(O, T1)

     rule #catofBuiltinOperator(operator=, _, _, _) => catof(lvalue)

     rule #catofBuiltinOperator(operator+=, _, _, _) => catof(lvalue)

     rule #catofBuiltinOperator(operator-=, _, _, _) => catof(lvalue)

     rule #catofBuiltinOperator(operator*=, _, _, _) => catof(lvalue)

     rule #catofBuiltinOperator(operator/=, _, _, _) => catof(lvalue)

     rule #catofBuiltinOperator(operator%=, _, _, _) => catof(lvalue)

     rule #catofBuiltinOperator(operator<<=, _, _, _) => catof(lvalue)

     rule #catofBuiltinOperator(operator>>=, _, _, _) => catof(lvalue)

     rule #catofBuiltinOperator(operator&=, _, _, _) => catof(lvalue)

     rule #catofBuiltinOperator(operator^=, _, _, _) => catof(lvalue)

     rule #catofBuiltinOperator(operator|=, _, _, _) => catof(lvalue)

     rule #catofBuiltinOperator(operator||, _, _, _) => catof(prvalue)

     rule #catofBuiltinOperator(operator&&, _, _, _) => catof(prvalue)

     rule #catofBuiltinOperator(operator==, _, _, _) => catof(prvalue)

     rule #catofBuiltinOperator(operator!=, _, _, _) => catof(prvalue)

     rule #catofBuiltinOperator(operator<, _, _, _) => catof(prvalue)

     rule #catofBuiltinOperator(operator<=, _, _, _) => catof(prvalue)

     rule #catofBuiltinOperator(operator>, _, _, _) => catof(prvalue)

     rule #catofBuiltinOperator(operator>=, _, _, _) => catof(prvalue)

     rule #catofBuiltinOperator(operator[], _:CPPPointerType, _, _) => catof(lvalue)

     rule #catofBuiltinOperator(operator[], _:CPPArrayType, lvalue, _) => catof(lvalue)

     rule #catofBuiltinOperator(operator[], _:CPPArrayType, _:RValueCategory, _) => catof(xvalue)

     rule #catofBuiltinOperator(operator->, _, E1::Expr, E2::Name)
          => catof((* E1) . no-template E2)

     rule #catofBuiltinOperator(operator+, _, _, _) => catof(prvalue)

     rule #catofBuiltinOperator(operator-, _, _, _) => catof(prvalue)

     rule #catofBuiltinOperator(operator*, _, _, _) => catof(prvalue)

     rule #catofBuiltinOperator(operator/, _, _, _) => catof(prvalue)

     rule #catofBuiltinOperator(operator%, _, _, _) => catof(prvalue)

     rule #catofBuiltinOperator(operator&, _, _, _) => catof(prvalue)

     rule #catofBuiltinOperator(operator|, _, _, _) => catof(prvalue)

     rule #catofBuiltinOperator(operator^, _, _, _) => catof(prvalue)

     rule #catofBuiltinOperator(operator<<, _, _, _) => catof(prvalue)

     rule #catofBuiltinOperator(operator>>, _, _, _) => catof(prvalue)

     rule #catofBuiltinOperator(operator-, _) => catof(prvalue)

     rule #catofBuiltinOperator(operator+, _) => catof(prvalue)

     rule #catofBuiltinOperator(operator++_, _) => catof(lvalue)

     rule #catofBuiltinOperator(operator--_, _) => catof(lvalue)

     rule #catofBuiltinOperator(operator_++, _) => catof(prvalue)

     rule #catofBuiltinOperator(operator_--, _) => catof(prvalue)

     rule #catofBuiltinOperator(operator&, _) => catof(prvalue)

     rule #catofBuiltinOperator(operator*, _) => catof(lvalue)

     rule #catofBuiltinOperator(operator!, _) => catof(prvalue)

     rule (.K => typeAndCatOfConditional(E2, E3)) ~> catofConditional(E2::Expr, E3::Expr)

     rule typeAndCat(_, V:ValueCategory) ~> catofConditional(_, _) => catof(V)

     // boilerplate rules for computing value category when the C++ semantics
     // references a builtin construct directly
     rule catof(E1::Expr := E2::Init) => catofBuiltinOperator(operator=, E1, E1, E2)

     rule catof(E1::Expr[E2::Expr]) => catofBuiltinOperator(operator[], E1, E1, E2)

     rule catof(E1::Expr-> _ E2::Name) => catofBuiltinOperator(operator->, E1, E1, E2)

     rule catof(E1::Expr + E2::Expr) => catofBuiltinOperator(operator+, E1, E1, E2)

     rule catof(E1::Expr - E2::Expr) => catofBuiltinOperator(operator-, E1, E1, E2)

     rule catof(E1::Expr * E2::Expr) => catofBuiltinOperator(operator*, E1, E1, E2)

     rule catof(E1::Expr / E2::Expr) => catofBuiltinOperator(operator/, E1, E1, E2)

     rule catof(E1::Expr % E2::Expr) => catofBuiltinOperator(operator%, E1, E1, E2)

     rule catof(E1::Expr || E2::Expr) => catofBuiltinOperator(operator||, E1, E1, E2)

     rule catof(E1::Expr && E2::Expr) => catofBuiltinOperator(operator&&, E1, E1, E2)

     rule catof(E1::Expr & E2::Expr) => catofBuiltinOperator(operator&, E1, E1, E2)

     rule catof(E1::Expr | E2::Expr) => catofBuiltinOperator(operator|, E1, E1, E2)

     rule catof(E1::Expr ^ E2::Expr) => catofBuiltinOperator(operator^, E1, E1, E2)

     rule catof(E1::Expr == E2::Expr) => catofBuiltinOperator(operator==, E1, E1, E2)

     rule catof(E1::Expr != E2::Expr) => catofBuiltinOperator(operator!=, E1, E1, E2)

     rule catof(E1::Expr < E2::Expr) => catofBuiltinOperator(operator<, E1, E1, E2)

     rule catof(E1::Expr <= E2::Expr) => catofBuiltinOperator(operator<=, E1, E1, E2)

     rule catof(E1::Expr > E2::Expr) => catofBuiltinOperator(operator>, E1, E1, E2)

     rule catof(E1::Expr >= E2::Expr) => catofBuiltinOperator(operator>=, E1, E1, E2)

     rule catof(E1::Expr += E2::Expr) => catofBuiltinOperator(operator+=, E1, E1, E2)

     rule catof(E1::Expr -= E2::Expr) => catofBuiltinOperator(operator-=, E1, E1, E2)

     rule catof(E1::Expr *= E2::Expr) => catofBuiltinOperator(operator*=, E1, E1, E2)

     rule catof(E1::Expr /= E2::Expr) => catofBuiltinOperator(operator/=, E1, E1, E2)

     rule catof(E1::Expr %= E2::Expr) => catofBuiltinOperator(operator%=, E1, E1, E2)

     rule catof(E1::Expr ^= E2::Expr) => catofBuiltinOperator(operator^=, E1, E1, E2)

     rule catof(E1::Expr &= E2::Expr) => catofBuiltinOperator(operator&=, E1, E1, E2)

     rule catof(E1::Expr |= E2::Expr) => catofBuiltinOperator(operator|=, E1, E1, E2)

     rule catof(E1::Expr << E2::Expr) => catofBuiltinOperator(operator<<, E1, E1, E2)

     rule catof(E1::Expr >> E2::Expr) => catofBuiltinOperator(operator>>, E1, E1, E2)

     rule catof(E1::Expr <<= E2::Expr) => catofBuiltinOperator(operator<<=, E1, E1, E2)

     rule catof(E1::Expr >>= E2::Expr) => catofBuiltinOperator(operator>>=, E1, E1, E2)

     rule catof(Comma(E1::Expr, E2::Expr)) => catofBuiltinOperator(operator,, E1, E1, E2)

     rule catof(E1::Expr ++) => catofBuiltinOperator(operator_++, E1)

     rule catof(E1::Expr --) => catofBuiltinOperator(operator_--, E1)

     rule catof(++ E1::Expr) => catofBuiltinOperator(operator++_, E1)

     rule catof(-- E1::Expr) => catofBuiltinOperator(operator--_, E1)

     rule catof(! E1::Expr) => catofBuiltinOperator(operator!, E1)

     rule catof(- E1::Expr) => catofBuiltinOperator(operator-, E1)

     rule catof(& E1::Expr) => catofBuiltinOperator(operator&, E1)

     rule catof(* E1::Expr) => catofBuiltinOperator(operator*, E1)



endmodule
