module COMMON-BUILTIN-SYNTAX
     imports SYMLOC-SORTS

     syntax Map ::= "nativeDefinedBuiltins" [function, memo]
     syntax KItem ::= "callBuiltin"
     syntax KItem ::= handleBuiltin(SymLoc)

endmodule

module COMMON-BUILTIN
     imports COMMON-BUILTIN-SYNTAX
     imports MAP

     syntax Map ::= #nativeDefinedBuiltins() [function, hook(C_SEMANTICS.nativeFunctions), impure]
     rule nativeDefinedBuiltins => #nativeDefinedBuiltins()

     // defined as a K rule for if the hook is not defined
     rule #nativeDefinedBuiltins() => .Map

endmodule
