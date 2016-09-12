module CPP-BUILTIN-SYNTAX
     imports CPP-TYPING-SORTS
     syntax Map ::= "weakCppBuiltins" [function]
                  | "cppBuiltins" [function]
     syntax CPPType ::= func(CPPTypes) [function, klabel(funcCpp)]
     syntax CPPType ::= ptr(CPPType) [function, klabel(ptrCpp)]
endmodule

module CPP-BUILTIN
     imports CPP-BUILTIN-SYNTAX
     imports MAP
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule cppBuiltins => .Map

     rule func(T::CPPType, Ts::CPPTypes) => type(functionType(T, Ts, CPPLinkage))
     rule ptr(T::CPPType) => type(pointerType(T))

     rule weakCppBuiltins => GlobalNamespace() :: operatornew[] |-> func(ptr(type(void)), type(size_t))

endmodule
