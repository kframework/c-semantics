module C-NATIVE-BRIDGE
  imports LIBC-BOOTSTRAP-SYNTAX

  imports C-SYNTAX
  imports C-BUILTIN-SYNTAX
  imports C-CONFIGURATION

  syntax K ::= #nativeCall(String, Type, List) [function, hook(C_SEMANTICS.nativeCall), impure]

  rule <k> prepareBuiltin(Identifier(S:String), H:HeatList) => #nativeCall(S, T, hListToList(H)) ...</k>
       <types>... Identifier(S) |-> T:Type ...</types>
     requires S in_keys(nativeDefinedBuiltins) andBool isKResult(H) [native-call]

endmodule
