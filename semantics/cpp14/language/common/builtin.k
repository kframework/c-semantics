module CPP-BUILTIN-SYNTAX
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS
     syntax K ::= "weakCppBuiltins" [function]
                | "cppBuiltins" [function]
     syntax CPPType ::= func(CPPTypes) [function, klabel(funcCpp)]
     syntax CPPType ::= func(CPPTypes, ExceptionSet) [function, klabel(funcExcCpp)]
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

     rule cppBuiltins => .K

     rule func(T::CPPType, Ts::CPPTypes) => type(functionType(T, Ts, noMethod, CPPLinkage, noexcept(false)))
     rule func(T::CPPType, Ts::CPPTypes, E::ExceptionSet) => type(functionType(T, Ts, noMethod, CPPLinkage, E))
     rule ptr(T::CPPType) => type(pointerType(T))

     rule weakCppBuiltins => GlobalNamespace() :: operatornew -> func(ptr(type(void)), type(size_t))
                          ~> GlobalNamespace() :: operatornew[] -> func(ptr(type(void)), type(size_t))
                          ~> GlobalNamespace() :: operatordelete -> func(type(void), ptr(type(void)), noexcept(true))
                          ~> GlobalNamespace() :: operatordelete[] -> func(type(void), ptr(type(void)), noexcept(true))
                          ~> GlobalNamespace() :: operatordelete -> func(type(void), ptr(type(void)), type(size_t), noexcept(true))
                          ~> GlobalNamespace() :: operatordelete[] -> func(type(void), ptr(type(void)), type(size_t), noexcept(true))

endmodule
