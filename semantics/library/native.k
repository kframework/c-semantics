module C-NATIVE-BRIDGE
     imports LIBC-BOOTSTRAP-SYNTAX

     imports C-SYNTAX
     imports C-BUILTIN-SYNTAX
     imports C-CONFIGURATION

     syntax K ::= #nativeCall(String, Type, List, List) [function, hook(C_SEMANTICS.nativeCall), impure, canTakeSteps]
     syntax KItem ::= nativeCall(String, List, List)
     rule <generatedTop>... 
            <k> nativeCall(S:String, Args:List, VarArgs:List)
            ...</k>
            <types>... Identifier(S) |-> T:Type ...</types>
          ...</generatedTop> => #nativeCall(S, T, Args, VarArgs)

     rule builtin(S:String) => nativeCall(S, .List, .List)
          requires S in_keys(nativeDefinedBuiltins) [native-call]

     rule builtin(S:String) => nativeCall(S, .List, .List)
          requires S in_keys(nativeDefinedBuiltins) [native-call]
     rule builtin(S:String, A1:RValue)
          => nativeCall(S, ListItem(A1), .List)
          requires S in_keys(nativeDefinedBuiltins) [native-call]
     rule builtin(S:String, A1:RValue, A2:RValue)
          => nativeCall(S, ListItem(A1) ListItem(A2), .List)
          requires S in_keys(nativeDefinedBuiltins) [native-call]
     rule builtin(S:String, A1:RValue, A2:RValue, A3:RValue)
          => nativeCall(S, ListItem(A1) ListItem(A2) ListItem(A3),
               .List)
          requires S in_keys(nativeDefinedBuiltins) [native-call]
     rule builtin(S:String, A1:RValue, A2:RValue, A3:RValue, A4:RValue)
          => nativeCall(S, ListItem(A1) ListItem(A2) ListItem(A3)
               ListItem(A4), .List)
          requires S in_keys(nativeDefinedBuiltins) [native-call]
     rule builtin(S:String, A1:RValue, A2:RValue, A3:RValue, A4:RValue,
               A5:RValue)
          => nativeCall(S, ListItem(A1) ListItem(A2) ListItem(A3)
               ListItem(A4) ListItem(A5), .List)
          requires S in_keys(nativeDefinedBuiltins) [native-call]
     rule builtin(S:String, A1:RValue, A2:RValue, A3:RValue, A4:RValue,
               A5:RValue, A6:RValue)
          => nativeCall(S, ListItem(A1) ListItem(A2) ListItem(A3)
               ListItem(A4) ListItem(A5) ListItem(A6), .List)
          requires S in_keys(nativeDefinedBuiltins) [native-call]

     rule builtin*(S:String, A1:RValue, VarArgs:List)
          => nativeCall(S, ListItem(A1), VarArgs)
          requires S in_keys(nativeDefinedBuiltins) [native-call]
     rule builtin*(S:String, A1:RValue, A2:RValue, VarArgs:List)
          => nativeCall(S, ListItem(A1) ListItem(A2), VarArgs)
          requires S in_keys(nativeDefinedBuiltins) [native-call]
     rule builtin*(S:String, A1:RValue, A2:RValue, A3:RValue, VarArgs:List)
          => nativeCall(S, ListItem(A1) ListItem(A2) ListItem(A3), VarArgs)
          requires S in_keys(nativeDefinedBuiltins) [native-call]

     rule builtin*(S:String, Args:List, VarArgs:List)
          => nativeCall(S, Args, VarArgs)
          requires S in_keys(nativeDefinedBuiltins) [native-call]

     // Memory allocated by the native heap needs to be freed by a call to
     // native free.
     rule builtin("free", tv(Loc:SymLoc, T:Type))
          => nativeCall("free", ListItem(tv(Loc, T)), .List)
          requires isNativeLoc(Loc)

endmodule
