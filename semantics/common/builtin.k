module COMMON-BUILTIN-SYNTAX
     imports SYMLOC-SORTS

     syntax Map ::= "nativeDefinedBuiltins" [function]
     syntax KItem ::= "callBuiltin"
     syntax KItem ::= handleBuiltin(SymLoc)
     syntax KItem ::= "breakpoint" [klabel(breakpoint)]

endmodule

module COMMON-BUILTIN
     imports COMMON-BUILTIN-SYNTAX
     imports C-CONFIGURATION
     imports MAP
     imports K-REFLECTION
     imports C-TYPING-SYNTAX

     syntax Map ::= #nativeDefinedBuiltins() [function, hook(C_SEMANTICS.nativeFunctions)]
     rule nativeDefinedBuiltins => #nativeDefinedBuiltins()

     // defined as a K rule for if the hook is not defined
     rule [[ #nativeDefinedBuiltins() => .Map ]]
          <k> _ </k>

endmodule
