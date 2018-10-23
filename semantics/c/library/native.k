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
     imports LIBC-TYPES-SYNTAX

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

     // Memory allocated by the native heap needs to be freed by a call to
     // native free.
     rule builtin("free", tv(Loc:SymLoc, T::UType))
          => nativeCall("free", ListItem(tv(Loc, T)), .List)
          requires isNativeLoc(Loc)

endmodule
