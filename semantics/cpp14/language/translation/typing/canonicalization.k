module CPP-TYPING-CANONICALIZATION
     imports C-CONFIGURATION
     imports K-REFLECTION
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-ELABORATOR-SYNTAX
     imports CPP-ENV-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SYNTAX
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

     rule PointerType(T:CPPType) => t(noQuals, .Set, pointerType(T))

     rule Qualifier(Q::Qualifier, t(Quals::Quals, Mods::Set, S::CPPSimpleType)) => t(Quals +Qual Q, Mods, S)

     rule FunctionPrototype(T:CPPType, krlist(Args::List), NoExceptionSpec(), true) => FunctionPrototype(T, krlist(Args ListItem(variadic)), NoExceptionSpec(), false)
     rule <k> FunctionPrototype(T:CPPType, krlist(Args::List), NoExceptionSpec(), false) => t(noQuals, .Set, functionType(T, Args, L)) ...</k>
          <curr-lang-linkage> L::LanguageLinkage </curr-lang-linkage>

     rule QualifiedTypeName(NoTag(), N::NNS, TypedefType(X::CId))
          => Name(N, X)
     rule TypedefType(X::CId) => Name(NoNNS(), X)

     rule (.K => typeof(Name(N, X))) ~> Decltype(Name(N::Namespace, X::CId))
     rule typeof(T:CPPType) ~> Decltype(_) => T

     rule (.K => elaborate(noEval(elabResult(E)))) ~> Decltype(E::Expr)
          requires getKLabel(E) =/=K #klabel(`Name`)
     rule elaborateDone(X:XVal) ~> Decltype(_) => type(rvRefType(type(X)))
     rule elaborateDone(L:LVal) ~> Decltype(_) => type(lvRefType(type(L)))
     rule elaborateDone(PR:PRVal) ~> Decltype(_) => type(PR)


     syntax KItem ::= elabResult(K)
     context elabResult(HOLE:KItem)

     rule <k> elabResult(V:Val) => .K ...</k>
          <elab> .K => V ...</elab>

     rule <k> EXIT(_) => recover ...</k>
          <curr-eval-context> noEval </curr-eval-context>

endmodule
