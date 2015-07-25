module C-NATIVE-BRIDGE
  imports LIBC-BOOTSTRAP-SYNTAX

  imports C-SYNTAX
  imports C-BUILTIN-SYNTAX
  imports COMPAT-SYNTAX

  syntax K ::= #nativeCall(String, List) [function, hook(C_SEMANTICS.nativeCall), impure]

  rule prepareBuiltin(Identifier(S:String), H:HeatList) => #nativeCall(S, hListToList(H))
     requires S in_keys(nativeDefinedBuiltins) andBool isKResult(H) [native-call]

endmodule
