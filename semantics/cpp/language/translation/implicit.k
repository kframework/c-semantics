module CPP-TRANSLATION-IMPLICIT-SYNTAX
     syntax KItem ::= "implicitDecls"
endmodule

module CPP-TRANSLATION-IMPLICIT
     imports CPP-TRANSLATION-IMPLICIT-SYNTAX
     imports COMMON-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-BUILTIN-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TRANSLATION-DECL-DECLARATOR-SYNTAX
     imports CPP-TYPING-SYNTAX

     syntax KItem ::= "func" "(" Namespace "," CId "," CPPType "," CPPTypes "," ExceptionSet ")" [function]

     rule implicitDecls
          => func(GlobalNamespace(), operatornew, ptr(type(void)), type(size_t), noexcept(false))
          ~> func(GlobalNamespace(), operatornew[], ptr(type(void)), type(size_t), noexcept(false))
          ~> func(GlobalNamespace(), operatordelete, type(void), ptr(type(void)), noexcept(true))
          ~> func(GlobalNamespace(), operatordelete[], type(void), ptr(type(void)), noexcept(true))
          ~> func(GlobalNamespace(), operatordelete, type(void), ptr(type(void)), type(size_t), noexcept(true))
          ~> func(GlobalNamespace(), operatordelete[], type(void), ptr(type(void)), type(size_t), noexcept(true))
          ~> TypedefDecl(Identifier("__builtin_va_list"), type(ptrdiff_t))

     rule func(N::Namespace, X::CId, Ret::CPPType, Args::CPPTypes, E::ExceptionSet)
          => declareObject(N, N, X, X, type(functionType(Ret, Args, noMethod, CPPLinkage, E)), NoInit(), makeFunctionDeclarationType(N, Args), ExternalLinkage, StaticStorage, .Set)
endmodule
