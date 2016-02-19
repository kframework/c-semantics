module C-NATIVE-BRIDGE
     imports LIBC-BOOTSTRAP-SYNTAX

     imports C-SYNTAX
     imports C-BUILTIN-SYNTAX
     imports C-CONFIGURATION

     syntax K ::= #nativeCall(String, Type, List) [function, hook(C_SEMANTICS.nativeCall), impure, canTakeSteps]

     rule <k> builtin(S:String) => #nativeCall(S, T, .List) ...</k>
          <types>... Identifier(S) |-> T:Type ...</types>
          requires S in_keys(nativeDefinedBuiltins) [native-call]
     rule <k> builtin(S:String, A1:RValue)
               => #nativeCall(S, T, ListItem(A1))
          ...</k>
          <types>... Identifier(S) |-> T:Type ...</types>
          requires S in_keys(nativeDefinedBuiltins) [native-call]
     rule <k> builtin(S:String, A1:RValue, A2:RValue)
               => #nativeCall(S, T, ListItem(A1) ListItem(A2))
          ...</k>
          <types>... Identifier(S) |-> T:Type ...</types>
          requires S in_keys(nativeDefinedBuiltins) [native-call]
     rule <k> builtin(S:String, A1:RValue, A2:RValue, A3:RValue)
               => #nativeCall(S, T, ListItem(A1) ListItem(A2) ListItem(A3))
          ...</k>
          <types>... Identifier(S) |-> T:Type ...</types>
          requires S in_keys(nativeDefinedBuiltins) [native-call]
     rule <k> builtin(S:String, A1:RValue, A2:RValue, A3:RValue, A4:RValue)
               => #nativeCall(S, T, ListItem(A1) ListItem(A2) ListItem(A3)
                    ListItem(A4))
          ...</k>
          <types>... Identifier(S) |-> T:Type ...</types>
          requires S in_keys(nativeDefinedBuiltins) [native-call]
     rule <k> builtin(S:String, A1:RValue, A2:RValue, A3:RValue, A4:RValue,
                    A5:RValue)
               => #nativeCall(S, T, ListItem(A1) ListItem(A2) ListItem(A3)
                    ListItem(A4) ListItem(A5))
          ...</k>
          <types>... Identifier(S) |-> T:Type ...</types>
          requires S in_keys(nativeDefinedBuiltins) [native-call]
     rule <k> builtin(S:String, A1:RValue, A2:RValue, A3:RValue, A4:RValue,
                    A5:RValue, A6:RValue)
               => #nativeCall(S, T, ListItem(A1) ListItem(A2) ListItem(A3)
                    ListItem(A4) ListItem(A5) ListItem(A6))
          ...</k>
          <types>... Identifier(S) |-> T:Type ...</types>
          requires S in_keys(nativeDefinedBuiltins) [native-call]
     rule <k> builtin*(S:String, Args:List) => #nativeCall(S, T, Args) ...</k>
          <types>... Identifier(S) |-> T:Type ...</types>
          requires S in_keys(nativeDefinedBuiltins) [native-call]

     // Memory allocated by the native heap needs to be freed by a call to
     // native free.
     rule <k> builtin("free", tv(Loc:SymLoc, T:Type))
               => #nativeCall("free", FunType, ListItem(tv(Loc, T)))
          ...</k>
          <types>... Identifier("free") |-> FunType:Type ...</types>
          requires isNativeLoc(Loc)

endmodule
