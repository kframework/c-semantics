module CPP-TRANSLATION-TYPING-CANONICALIZATION
     imports C-CONFIGURATION
     imports COLLECTIONS
     imports K-REFLECTION
     imports ERROR-SYNTAX
     imports SYMLOC-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-TRANSLATION-ELABORATOR-SYNTAX
     imports CPP-TRANSLATION-ENV-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TRANSLATION-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-TRANSLATION-VALUE-CATEGORY-SYNTAX

     rule BuiltinType(Void()) => type(void)

     rule BuiltinType(Bool()) => type(bool)

     rule BuiltinType(Char()) => type(char)

     rule BuiltinType(WChar()) => type(wchar_t)

     rule BuiltinType(Char16()) => type(char16_t)

     rule BuiltinType(Char32()) => type(char32_t)

     rule BuiltinType(UChar()) => type(unsigned-char)

     rule BuiltinType(UShort()) => type(unsigned-short)

     rule BuiltinType(UInt()) => type(unsigned)

     rule BuiltinType(ULong()) => type(unsigned-long)

     rule BuiltinType(ULongLong()) => type(unsigned-long-long)

     rule BuiltinType(OversizedUInt()) => type(unsigned-oversized)

     rule BuiltinType(SChar()) => type(signed-char)

     rule BuiltinType(Short()) => type(short)

     rule BuiltinType(Int()) => type(int)

     rule BuiltinType(Long()) => type(long)

     rule BuiltinType(LongLong()) => type(long-long)

     rule BuiltinType(OversizedInt()) => type(oversized)

     rule BuiltinType(Float()) => type(float)

     rule BuiltinType(Double()) => type(double)

     rule BuiltinType(LongDouble()) => type(long-double)

     rule PointerType(T:CPPTypeExpr) => t(noQuals, .Set, pointerType(T))

     rule MemberPointerType(D:CPPClassType, T:CPPType) => t(noQuals, .Set, memberPointerType(D, T))

     rule ArrayType(T:CPPTypeExpr, NoExpression()) => t(noQuals, .Set, incompleteArrayType(T))

     rule ArrayType(T:CPPTypeExpr, I:Int) => t(noQuals, .Set, arrayType(T, I))

     rule LValRefType(T:CPPTypeExpr) => t(noQuals, .Set, lvRefType(T))

     rule RValRefType(T:CPPTypeExpr) => t(noQuals, .Set, rvRefType(T))

     rule Qualifier(Q::Qualifier, t(Quals::Quals, Mods::Set, S::CPPSimpleType)) => t(Quals +Qual Q, Mods, S)

     rule RefQualifier(Q::RefQualifier, T:CPPFunctionType) => setRefQualifier(T, Q)

     rule FunctionPrototype(T:CPPTypeExpr, krlist(Args::List), E::ExceptionSpec, true) => FunctionPrototype(T, krlist(Args ListItem(variadic)), E, false)

     context FunctionPrototype(_, _, HOLE:ExceptionSpec, _)

     rule <k> FunctionPrototype(T:CPPTypeExpr, krlist(Args::List), E:ExceptionSet, false)
               => adjustFunctionType(t(noQuals, .Set, functionType(T, toCPPTypes(Args), noMethod, L, E)))
          ...</k>
          <curr-lang-linkage> L::LanguageLinkage </curr-lang-linkage>

     rule MethodPrototype(IsUserProvided::Bool, IsConstructor::Bool, t(_, _, pointerType(t(CVS::Quals, _, classType(C::Class)))), T:CPPFunctionType) => setMethodConstructor(setMethodUserProvided(setMethodClass(setCVSQuals(setMethod(T), CVS), C), IsUserProvided), IsConstructor)

     rule StaticMethodPrototype(T:CPPFunctionType) => setMethodStatic(setMethod(T))

     rule Virtual(T:CPPFunctionType) => setMethodVirtual(T)

     rule Pure(T:CPPFunctionType) => setMethodPure(T)

     rule Explicit(T:CPPFunctionType) => setMethodExplicit(T)

     rule ThrowSpec(krlist(L::List)) => exSet(List2Set(adjustExcTypes(L)))

     rule NoExceptionSpec() => noexcept(false)

     rule NoexceptSpec(NoExpression()) => noexcept(true)

     context NoexceptSpec(HOLE:Expr => reval(HOLE)) [result(PRVal)]

     rule NoexceptSpec(V:PRVal => convertType(type(bool), V))
          requires notBool(isCPPBoolType(type(V)))

     rule NoexceptSpec(prv(0, _, _:CPPBoolType)) => noexcept(false)

     rule NoexceptSpec(prv(1, _, _:CPPBoolType)) => noexcept(true)

     syntax List ::= adjustExcTypes(List) [function]

     rule adjustExcTypes(ListItem(T:CPPArrayType) L::List) => ListItem(type(pointerType(innerType(T)))) adjustExcTypes(L)

     rule adjustExcTypes(ListItem(T:CPPFunctionType) L::List) => ListItem(type(pointerType(T))) adjustExcTypes(L)

     rule adjustExcTypes(ListItem(T::CPPType) L::List) => ListItem(utype(T)) adjustExcTypes(L) [owise]

     rule adjustExcTypes(.List) => .List

     rule QualifiedTypeName(NoTag(), N::NNS, Name(NoNNS(), X::CId))
          => Name(N, X)

     rule QualifiedTypeName(NoTag(), N::NNS, TypedefType(X::CId))
          => Name(N, X)

     rule QualifiedTypeName(NoTag(), N::NNS, TemplateParameterType(X::CId))
          => Name(N, X)

     rule QualifiedTypeName(T::Tag, N::NNS, Name(NoNNS(), X::CId))
          => ElaboratedTypeSpecifier(T, X, N)
          requires T =/=K NoTag()

     rule QualifiedTypeName(T::Tag, N::NNS, TemplateSpecializationType(X::CId, L::List))
          => ElaboratedTypeSpecifier(T, X, N, L)

     rule TypedefType(X::CId) => Name(NoNNS(), X)

     rule TemplateParameterType(X::CId) => Name(NoNNS(), X)

     rule AutoType(false) => t(noQuals, .Set, auto)

     rule AutoType(true) => t(noQuals, .Set, decltype(auto))

     rule (.K => typeof(E)) ~> Decltype(E::Expr)

     rule (.K => catof(E)) ~> typeof(T:CPPType) ~> Decltype(E::Expr)
          requires getKLabel(E) =/=K #klabel(`Name`)

     rule typeof(T:CPPType) ~> Decltype(Name(_, _)) => T

     rule catof(xvalue) ~> typeof(T:CPPType) ~> Decltype(E::Expr) => type(rvRefType(T))

     rule catof(lvalue) ~> typeof(T:CPPType) ~> Decltype(E::Expr) => type(lvRefType(T))

     rule catof(prvalue) ~> typeof(T:CPPType) ~> Decltype(E::Expr) => T

     syntax KItem ::= elabResult(K)

     context elabResult(HOLE:KItem)

     rule <k> elabResult(V:Val) => .K ...</k>
          <elab> .K => V ...</elab>

     rule <k> EXIT(_) => skipToScopeEnd ...</k>
          <curr-eval-context> noEval </curr-eval-context>

     rule isAdjustedType(t(_, _, functionType(... paramTypes: (T::CPPType, _)))) => false
          requires isCPPFunctionTypeExpr(T) orBool isCPPArrayTypeExpr(T) orBool (isCPPTypeExpr(T) andBool getQuals(T) =/=K noQuals)

     rule isAdjustedType(t(_, _, functionType(... paramTypes: (_, Ts::CPPTypes => Ts)))) [owise]

     rule isAdjustedType(t(_, _, functionType(... paramTypes: .CPPTypes))) => true

     syntax CPPFunctionType ::= #adjustFunctionType(CPPFunctionTypeExpr, List) [function]

     rule adjustFunctionType(T::CPPFunctionType) => #adjustFunctionType(T, .List)

     rule #adjustFunctionType(t(_, _, functionType(... paramTypes: (t(Q::Quals, Mods::Set, T:CPPSimpleArrayTypeExpr), Ts::CPPTypeExprs => Ts))), _::List (.List => ListItem(t(noQuals, Mods, pointerType(innerType(t(Q, Mods, T)))))))

     rule #adjustFunctionType(t(_, _, functionType(... paramTypes: (variadic, Ts::CPPTypeExprs => Ts))), _::List (.List => ListItem(variadic)))

     rule #adjustFunctionType(t(_, _, functionType(... paramTypes: (T:CPPFunctionTypeExpr, Ts::CPPTypeExprs => Ts))), _::List (.List => ListItem(t(noQuals, .Set, pointerType(T)))))

     rule #adjustFunctionType(t(_, _, functionType(... paramTypes: (t(_, Mods::Set, T::CPPSimpleType), Ts::CPPTypeExprs => Ts))), _::List (.List => ListItem(t(noQuals, Mods, T)))) [owise]

     rule #adjustFunctionType(t(... st: functionType(... paramTypes: .CPPTypeExprs)) #as T::CPPFunctionType, Params::List) => #fun(t(... st: functionType(... paramTypes: _ => toCPPTypes(Params))))(T)

endmodule
