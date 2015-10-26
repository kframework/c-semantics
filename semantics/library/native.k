module C-NATIVE-BRIDGE
  imports LIBC-BOOTSTRAP-SYNTAX

  imports C-SYNTAX
  imports C-BUILTIN-SYNTAX
  imports C-CONFIGURATION

  syntax K ::= #nativeCall(String, Type, List) [function, hook(C_SEMANTICS.nativeCall), impure, canTakeSteps]

  rule <k> prepareBuiltin(Identifier(S:String), H:HeatList) => #nativeCall(S, T, hListToList(H)) ...</k>
       <types>... Identifier(S) |-> T:Type ...</types>
     requires S in_keys(nativeDefinedBuiltins) andBool isKResult(H) [native-call]

     //memory allocated by the native heap needs to be freed by a call to native free
     rule <k> prepareBuiltin(Identifier("free"), hrItem(tv(Loc:SymLoc, T:Type)))
              => #nativeCall("free", FunType, ListItem(tv(Loc, T))) ...</k>
          <types>... Identifier("free") |-> FunType:Type ...</types>
          requires isNativeLoc(Loc)

endmodule
