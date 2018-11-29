module CPP-BUILTIN-SYNTAX
     imports COMMON-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS
     syntax K ::= "weakCppBuiltins" [function]
                | "cppBuiltins" [function]

     syntax CPPType ::= func(CPPTypes) [function, klabel(funcCpp)]

     syntax CPPType ::= func(CPPTypes, ExceptionSet) [function, klabel(funcExcCpp)]

     syntax CPPType ::= func(CPPTypes, LanguageLinkage) [function, klabel(funcLinkCpp)]

     syntax CPPType ::= ptr(CPPType) [function, klabel(ptrCpp)]

     syntax NameTypePairs ::= List{NameTypePair,";"}

     syntax NameTypePair ::= QualId "->" CPPType
endmodule

module CPP-BUILTIN
     imports CPP-BUILTIN-SYNTAX
     imports MAP
     imports COMMON-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule cppBuiltins
       => GlobalNamespace() :: Namespace(Identifier("std")) :: Identifier("terminate") -> func(type(void))
       ~> GlobalNamespace() :: Identifier("__cpp_abort") -> func(type(void))

     rule func(T::CPPType, Ts::CPPTypes) => type(functionType(T, Ts, noMethod, CPPLinkage, noexcept(false)))

     rule func(T::CPPType, Ts::CPPTypes, E::ExceptionSet) => type(functionType(T, Ts, noMethod, CPPLinkage, E))

     rule func(T::CPPType, Ts::CPPTypes, L::LanguageLinkage) => type(functionType(T, Ts, noMethod, L, noexcept(false)))

     rule ptr(T::CPPType) => type(pointerType(T))

     rule weakCppBuiltins
       => GlobalNamespace() :: operatornew -> func(ptr(type(void)), type(size_t))
       ~> GlobalNamespace() :: operatornew[] -> func(ptr(type(void)), type(size_t))
       ~> GlobalNamespace() :: operatordelete -> func(type(void), ptr(type(void)), noexcept(true))
       ~> GlobalNamespace() :: operatordelete[] -> func(type(void), ptr(type(void)), noexcept(true))
       ~> GlobalNamespace() :: operatordelete -> func(type(void), ptr(type(void)), type(size_t), noexcept(true))
       ~> GlobalNamespace() :: operatordelete[] -> func(type(void), ptr(type(void)), type(size_t), noexcept(true))

endmodule
