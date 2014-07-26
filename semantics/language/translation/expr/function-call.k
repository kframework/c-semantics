module C-EXPR-FUNCTION-CALL
     imports C-BINDING-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     imports COMPAT-SYNTAX

     syntax KResult ::= rvlist(List)

     syntax KItem ::= revalParams(K)
		    | #revalParams(HeatList) [strict]
     //TODO: overcome the context associative matching
     //context revalParams(list(_ ListItem((HOLE => reval(HOLE))) _))

     rule revalParams(list(L:List)) => #revalParams(toHeatList(L))
     
     //the original rule to write to revalParams(rvlist...) might be wrong
     rule #revalParams(HL:HeatList) => revalParams(rvlist(hListToList(HL)))
          requires isAllKResultInHeatList(HL)
          [structural]     
     /*TODO: might not need this later
     rule revalParams(list(L:List)) => revalParams(rvlist(L))
          requires all(L, isKResult)
          [structural]
     */
     
     context Call(_, (HOLE => revalParams(HOLE)))

     rule Call(tv(_, t(_, pointerType(t(_, functionType(T:Type, P:List))))), rvlist(L:List))
          // Only attempt to bind if we have a prototype.
          => #if (P =/=K .List) #then bind(.List, P, L) #else .K #fi
          ~> tv(symVal, T)
          requires (isCompleteType(T) orBool isVoidType(T))
               andBool notBool isArrayType(T) // Don't think this is possible.
          [structural]
     rule (. => ERROR("EFC1", "function call with incomplete or invalid return type.",
               "6.5.2.2p2"))
          ~> Call(tv(_, t(_, pointerType(t(_, functionType(T:Type, _))))), rvlist(_))
          requires notBool (isCompleteType(T) orBool isVoidType(T))
               orBool isArrayType(T) // Don't think this is possible.
          [structural]

     rule bindParam(_, T:Type, V:TypedValue)
          => allowInit(Computation(lv(symVal, T) := V))
     rule bindParam(_) => .

endmodule

