module CPP-TYPING-CANONICALIZATION
     imports C-CONFIGURATION
     imports K-REFLECTION
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-ELABORATOR-SYNTAX
     imports CPP-ENV-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-VALUE-CATEGORY-SYNTAX
     imports ERROR-SYNTAX

     rule BuiltinType(Void()) => type(void)
     rule BuiltinType(Char()) => type(char)
     rule BuiltinType(WChar()) => type(wchar_t)
     rule BuiltinType(Char16()) => type(char16_t)
     rule BuiltinType(Char32()) => type(char32_t)
     rule BuiltinType(UChar()) => type(unsigned-char)
     rule BuiltinType(UShort()) => type(unsigned-short)
     rule BuiltinType(UInt()) => type(unsigned)
     rule BuiltinType(ULong()) => type(unsigned-long)
     rule BuiltinType(ULongLong()) => type(unsigned-long-long)
     rule BuiltinType(SChar()) => type(signed-char)
     rule BuiltinType(Short()) => type(short)
     rule BuiltinType(Int()) => type(int)
     rule BuiltinType(Long()) => type(long)
     rule BuiltinType(LongLong()) => type(long-long)
     rule BuiltinType(Float()) => type(float)
     rule BuiltinType(Double()) => type(double)
     rule BuiltinType(LongDouble()) => type(long-double)

     rule PointerType(T:CPPTypeExpr) => t(noQuals, .Set, pointerType(T))

     rule Qualifier(Q::Qualifier, t(Quals::Quals, Mods::Set, S::CPPSimpleType)) => t(Quals +Qual Q, Mods, S)

     rule FunctionPrototype(T:CPPTypeExpr, krlist(Args::List), NoExceptionSpec(), true) => FunctionPrototype(T, krlist(Args ListItem(variadic)), NoExceptionSpec(), false)
     rule <k> FunctionPrototype(T:CPPTypeExpr, krlist(Args::List), NoExceptionSpec(), false) => adjustFunctionType(t(noQuals, .Set, functionType(T, toCPPTypes(Args), L))) ...</k>
          <curr-lang-linkage> L::LanguageLinkage </curr-lang-linkage>

     rule QualifiedTypeName(NoTag(), N::NNS, TypedefType(X::CId))
          => Name(N, X)
     rule QualifiedTypeName(NoTag(), N::NNS, TemplateParameterType(X::CId))
          => Name(N, X)
     rule QualifiedTypeName(T::Tag, N::NNS, TemplateSpecializationType(X::CId, L::List))
          => ElaboratedTypeSpecifier(T, X, N, L)
     rule TypedefType(X::CId) => Name(NoNNS(), X)
     rule TemplateParameterType(X::CId) => Name(NoNNS(), X)

     rule (.K => typeof(E)) ~> Decltype(E::Expr)
     rule typeof(T:CPPType) ~> Decltype(Name(_, _)) => T
     rule typeof(T:CPPType) ~> Decltype(E::Expr) => type(rvRefType(T))
          requires getKLabel(E) =/=K #klabel(`Name`)
               andBool isExprXValue(E)
     rule typeof(T:CPPType) ~> Decltype(E::Expr) => type(lvRefType(T))
          requires getKLabel(E) =/=K #klabel(`Name`)
               andBool isExprLValue(E)
     rule typeof(T:CPPType) ~> Decltype(E::Expr) => T
          requires getKLabel(E) =/=K #klabel(`Name`)
               andBool isExprPRValue(E)

     syntax KItem ::= elabResult(K)
     context elabResult(HOLE:KItem)
     rule <k> elabResult(V:Val) => .K ...</k>
          <elab> .K => V ...</elab>
     rule <k> EXIT(_) => recover ...</k>
          <curr-eval-context> noEval </curr-eval-context>

     rule isAdjustedType(t(_, _, functionType(_, (T::CPPType, _), _))) => false
          requires isCPPFunctionTypeExpr(T) orBool isCPPArrayTypeExpr(T) orBool (isCPPTypeExpr(T) andBool getQuals(T) =/=K noQuals)
     rule isAdjustedType(t(_, _, functionType(_, (_, Ts::CPPTypes => Ts), _))) [owise]
     rule isAdjustedType(t(_, _, functionType(_, .CPPTypes, _))) => true

     syntax CPPFunctionType ::= #adjustFunctionType(CPPFunctionTypeExpr, List) [function]
     rule adjustFunctionType(T::CPPFunctionType) => #adjustFunctionType(T, .List)
     rule #adjustFunctionType(t(_, _, functionType(_, (t(Q::Quals, Mods::Set, T:CPPSimpleArrayTypeExpr), Ts::CPPTypeExprs => Ts), _)), _::List (.List => ListItem(t(noQuals, Mods, pointerType(innerType(t(Q, Mods, T)))))))
     rule #adjustFunctionType(t(_, _, functionType(_, (variadic, Ts::CPPTypeExprs => Ts), _)), _::List (.List => ListItem(variadic)))
     rule #adjustFunctionType(t(_, _, functionType(_, (T:CPPFunctionTypeExpr, Ts::CPPTypeExprs => Ts), _)), _::List (.List => ListItem(t(noQuals, .Set, pointerType(T)))))
     rule #adjustFunctionType(t(_, _, functionType(_, (t(_, Mods::Set, T::CPPSimpleType), Ts::CPPTypeExprs => Ts), _)), _::List (.List => ListItem(t(noQuals, Mods, T)))) [owise]
     rule #adjustFunctionType(t(Q::Quals, Mods::Set, functionType(Ret::CPPTypeExpr, .CPPTypeExprs, L::LanguageLinkage)), Params::List) => t(Q, Mods, functionType(Ret, toCPPTypes(Params), L))

endmodule
