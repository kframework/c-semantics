module C-NATIVE-BRIDGE-SYNTAX
     imports LIST
     imports STRING-SYNTAX

     syntax KItem ::= nativeCall(String, List, List)
     syntax KItem ::= nativeCall(Int, List, List)
endmodule

module C-NATIVE-BRIDGE
     imports C-CONFIGURATION
     imports C-DYNAMIC-SYNTAX
     imports C-NATIVE-BRIDGE-SYNTAX
     imports COMMON-BUILTIN-SYNTAX
     imports C-TYPING-SORTS
     imports LIBC-BUILTIN-SYNTAX
     imports LIBC-SYNTAX

     syntax K ::= #nativeCall(String, Type, List, List, K) [function, hook(C_SEMANTICS.nativeCall), impure]
     rule <generatedTop>... 
            <k> nativeCall(S:String, Args:List, VarArgs:List) ~> Rest:K </k>
            <types>... Identifier(S) |-> T:Type ...</types>
          ...</generatedTop> => #nativeCall(S, T, Args, VarArgs, Rest)

     syntax K ::= #nativeCall(Int, Type, List, List, K) [function, hook(C_SEMANTICS.nativeCall), impure]
     rule <generatedTop>... 
            <k> nativeCall(I:Int, Args:List, VarArgs:List) ~> Rest:K </k>
            <types>... nativeFunction(I) |-> T:Type ...</types>
          ...</generatedTop> => #nativeCall(I, T, Args, VarArgs, Rest)

     syntax Map ::= "nativeFunctions" [function, memo]
     rule nativeFunctions => removeAll(nativeDefinedBuiltins, keys(builtins))

     rule builtin(S:String) => nativeCall(S, .List, .List)
          requires Identifier(S) in_keys(nativeFunctions) [native-call]

     rule builtin(S:String) => nativeCall(S, .List, .List)
          requires Identifier(S) in_keys(nativeFunctions) [native-call]
     rule builtin(S:String, A1:RValue)
          => nativeCall(S, ListItem(A1), .List)
          requires Identifier(S) in_keys(nativeFunctions) [native-call]
     rule builtin(S:String, A1:RValue, A2:RValue)
          => nativeCall(S, ListItem(A1) ListItem(A2), .List)
          requires Identifier(S) in_keys(nativeFunctions) [native-call]
     rule builtin(S:String, A1:RValue, A2:RValue, A3:RValue)
          => nativeCall(S, ListItem(A1) ListItem(A2) ListItem(A3),
               .List)
          requires Identifier(S) in_keys(nativeFunctions) [native-call]
     rule builtin(S:String, A1:RValue, A2:RValue, A3:RValue, A4:RValue)
          => nativeCall(S, ListItem(A1) ListItem(A2) ListItem(A3)
               ListItem(A4), .List)
          requires Identifier(S) in_keys(nativeFunctions) [native-call]
     rule builtin(S:String, A1:RValue, A2:RValue, A3:RValue, A4:RValue,
               A5:RValue)
          => nativeCall(S, ListItem(A1) ListItem(A2) ListItem(A3)
               ListItem(A4) ListItem(A5), .List)
          requires Identifier(S) in_keys(nativeFunctions) [native-call]
     rule builtin(S:String, A1:RValue, A2:RValue, A3:RValue, A4:RValue,
               A5:RValue, A6:RValue)
          => nativeCall(S, ListItem(A1) ListItem(A2) ListItem(A3)
               ListItem(A4) ListItem(A5) ListItem(A6), .List)
          requires Identifier(S) in_keys(nativeFunctions) [native-call]

     rule builtin*(S:String, A1:RValue, VarArgs:List)
          => nativeCall(S, ListItem(A1), VarArgs)
          requires Identifier(S) in_keys(nativeFunctions) [native-call]
     rule builtin*(S:String, A1:RValue, A2:RValue, VarArgs:List)
          => nativeCall(S, ListItem(A1) ListItem(A2), VarArgs)
          requires Identifier(S) in_keys(nativeFunctions) [native-call]
     rule builtin*(S:String, A1:RValue, A2:RValue, A3:RValue, VarArgs:List)
          => nativeCall(S, ListItem(A1) ListItem(A2) ListItem(A3), VarArgs)
          requires Identifier(S) in_keys(nativeFunctions) [native-call]

     rule builtin*(S:String, Args:List, VarArgs:List)
          => nativeCall(S, Args, VarArgs)
          requires Identifier(S) in_keys(nativeFunctions) [native-call]

     rule builtin*(I:Int, Args:List, VarArgs:List)
          => nativeCall(I, Args, VarArgs) [native-call]

     // Memory allocated by the native heap needs to be freed by a call to
     // native free.
     rule builtin("free", tv(Loc:SymLoc, T::UType))
          => nativeCall("free", ListItem(tv(Loc, T)), .List)
          requires isNativeLoc(Loc)

endmodule
