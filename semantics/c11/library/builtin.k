module LIBC-BUILTIN-SYNTAX
     imports C-DYNAMIC-SORTS
     imports SYMLOC-SORTS
     imports INT-SYNTAX
     imports LIST
     imports STRING-SYNTAX

     syntax KItem ::= builtin(String) [klabel(builtin0)]
                    | builtin(String, RValue) [klabel(builtin1)]
                    | builtin(String, RValue, RValue) [klabel(builtin2)]
                    | builtin(String, RValue, RValue, RValue) [klabel(builtin3)]
                    | builtin(String, RValue, RValue, RValue, RValue) [klabel(builtin4)]
                    | builtin(String, RValue, RValue, RValue, RValue, RValue) [klabel(builtin5)]
                    | builtin(String, RValue, RValue, RValue, RValue, RValue, RValue) [klabel(builtin6)]
                    | "builtin*" "(" String "," RValue "," List ")" [klabel(builtin1+)]
                    | "builtin*" "(" String "," RValue "," RValue "," List ")" [klabel(builtin2+)]
                    | "builtin*" "(" String "," RValue "," RValue "," RValue "," List ")" [klabel(builtin3+)]
                    | "builtin*" "(" String "," List "," List ")"
                    | "builtin*" "(" Int "," List "," List ")"

     syntax RValue ::= "success" [function]

     syntax KItem ::= "initBuiltins"

     // Using "fixed" to mean objects returned by library functions that
     // cause UB if the user tries to modify them.
     syntax Bool ::= isLibcFixedDuration(SymBase) [function]

endmodule

module LIB-BUILTIN-SYNTAX
     imports BASIC-K
     syntax Bool ::= isVarArg(K) [function]
     syntax Bool ::= notVarArg(K) [function]
endmodule

module LIBC-BUILTIN
     imports LIBC-BUILTIN-SYNTAX
     imports LIB-BUILTIN-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports INT
     imports MAP
     imports COMMON-BUILTIN-SYNTAX
     imports COMPAT-SYNTAX
     imports C-ALIGNMENT-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports LIBC-SYNTAX

     syntax KItem ::= prepareBuiltin(CId, Bool, HeatList, HeatList) [strict(3, 4)]
     rule <k> callBuiltin
               => Return(prepareBuiltin(F, variadic in getParams(T),
                    toHeatList(filterList(P, #klabel(`notVarArg`))),
                    toHeatList(filterList(P, #klabel(`isVarArg`)))))
          ...</k>
          <curr-scope> blockScope(F:CId, _) </curr-scope>
          <curr-function-params> P:List </curr-function-params>
          <types>... F |-> T:Type ...</types>
          [structural]

     rule isVarArg(vararg(_)) => true
     rule isVarArg(_) => false [owise]

     rule notVarArg(K:K) => notBool isVarArg(K)

     rule prepareBuiltin(Identifier(F:String), false, .HeatList, _)
          => builtin(F)
          [structural]
     rule prepareBuiltin(Identifier(F:String), false, hrItem(A1:RValue), _)
          => builtin(F, A1)
          [structural]
     rule prepareBuiltin(Identifier(F:String), false, hrItem(A1:RValue)
               hs:: hrItem(A2:RValue), _)
          => builtin(F, A1, A2)
          [structural]
     rule prepareBuiltin(Identifier(F:String), false, hrItem(A1:RValue)
               hs:: hrItem(A2:RValue) hs:: hrItem(A3:RValue), _)
          => builtin(F, A1, A2, A3)
          [structural]
     rule prepareBuiltin(Identifier(F:String), false, hrItem(A1:RValue)
               hs:: hrItem(A2:RValue) hs:: hrItem(A3:RValue)
               hs:: hrItem(A4:RValue), _)
          => builtin(F, A1, A2, A3, A4)
          [structural]
     rule prepareBuiltin(Identifier(F:String), false, hrItem(A1:RValue)
               hs:: hrItem(A2:RValue) hs:: hrItem(A3:RValue)
               hs:: hrItem(A4:RValue) hs:: hrItem(A5:RValue), _)
          => builtin(F, A1, A2, A3, A4, A5)
          [structural]
     rule prepareBuiltin(Identifier(F:String), false, hrItem(A1:RValue)
               hs:: hrItem(A2:RValue) hs:: hrItem(A3:RValue)
               hs:: hrItem(A4:RValue) hs:: hrItem(A5:RValue)
               hs:: hrItem(A6:RValue), _)
          => builtin(F, A1, A2, A3, A4, A5, A6)
          [structural]

     rule prepareBuiltin(Identifier(F:String), true, hrItem(A1:RValue), VarArgs:HeatList)
          => builtin*(F, A1, hListToList(VarArgs))
          requires allRValueInHeatList(VarArgs)
          [structural]
     rule prepareBuiltin(Identifier(F:String), true, hrItem(A1:RValue)
               hs:: hrItem(A2:RValue), VarArgs:HeatList)
          => builtin*(F, A1, A2, hListToList(VarArgs))
          requires allRValueInHeatList(VarArgs)
          [structural]
     rule prepareBuiltin(Identifier(F:String), true, hrItem(A1:RValue)
               hs:: hrItem(A2:RValue) hs:: hrItem(A3:RValue), VarArgs:HeatList)
          => builtin*(F, A1, A2, A3, hListToList(VarArgs))
          requires allRValueInHeatList(VarArgs)
          [structural]

     rule prepareBuiltin(Identifier(F:String), false, Args:HeatList, .HeatList)
          => builtin*(F, hListToList(Args), .List)
          requires allRValueInHeatList(Args)
               andBool size(hListToList(Args)) >Int 6
          [structural]
     rule prepareBuiltin(Identifier(F:String), true, Args:HeatList, VarArgs:HeatList)
          => builtin*(F, hListToList(Args), hListToList(VarArgs))
          requires allRValueInHeatList(Args)
               andBool allRValueInHeatList(VarArgs)
               andBool size(hListToList(Args)) >Int 3
          [structural]

     rule prepareBuiltin(nativeFunction(Address:Int), _, Args:HeatList, VarArgs:HeatList)
          => builtin*(Address, hListToList(Args), hListToList(VarArgs))
          requires allRValueInHeatList(Args)
               andBool allRValueInHeatList(VarArgs)

     rule success => tv(0, utype(int))

     rule isAllocatedDuration(obj(... d: libc)) => true
     rule isAllocatedDuration(obj(... d: libcFixed)) => true

     rule isLibcFixedDuration(obj(... d: libcFixed)) => true
     rule isLibcFixedDuration(_) => false [owise]

     rule initBuiltins => initStdio ~> initErrno

     syntax K ::= "initStdio" [function]
     rule initStdio
          => alloc(bnew(!Stdin:Int, file, libc), file, byteSizeofType(file))
          ~> allowInit(Computation(fileLVal(bnew(!Stdin, file, libc)) := stdin))
          ~> alloc(bnew(0, type(pointerType(file)), builtinSymbol("stdin")), type(pointerType(file)), byteSizeofType(type(pointerType(file))))
          ~> allowInit(Computation(filePtr(bnew(0, type(pointerType(file)), builtinSymbol("stdin"))) := & fileLVal(bnew(!Stdin, file, libc))))

          ~> alloc(bnew(!Stdout:Int, file, libc), file, byteSizeofType(file))
          ~> allowInit(Computation(fileLVal(bnew(!Stdout, file, libc)) := stdout))
          ~> alloc(bnew(0, type(pointerType(file)), builtinSymbol("stdout")), type(pointerType(file)), byteSizeofType(type(pointerType(file))))
          ~> allowInit(Computation(filePtr(bnew(0, type(pointerType(file)), builtinSymbol("stdout"))) := & fileLVal(bnew(!Stdout, file, libc))))

          ~> alloc(bnew(!Stderr:Int, file, libc), file, byteSizeofType(file))
          ~> allowInit(Computation(fileLVal(bnew(!Stderr, file, libc)) := stderr))
          ~> alloc(bnew(0, type(pointerType(file)), builtinSymbol("stderr")), type(pointerType(file)), byteSizeofType(type(pointerType(file))))
          ~> allowInit(Computation(filePtr(bnew(0, type(pointerType(file)), builtinSymbol("stderr"))) := & fileLVal(bnew(!Stderr, file, libc))))

     // TODO(_Thread_local errno)
     syntax K ::= "initErrno" [function]
     rule initErrno
          => alloc(obj(0, byteAlignofType(type(int)), builtinSymbol("errno")), type(int), byteSizeofType(type(int)))
          ~> allowInit(Computation(lv(lnew(obj(0, byteAlignofType(type(int)), builtinSymbol("errno"))), type(int)) := tv(0, utype(int))))

endmodule
