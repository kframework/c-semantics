module C-EXPR-FUNCTION-CALL
     imports C-ABSTRACT-SYNTAX
     imports C-BINDING-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ELABORATOR-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     imports COMPAT-SYNTAX

     syntax KResult ::= rvlist(List)

     syntax KItem ::= revalParams(K)
                    | #revalParams(HeatList) [strict]
     //TODO(liyi): overcome the context associative matching
     //context revalParams(list(_ ListItem((HOLE:KItem => reval(HOLE))) _))

     rule revalParams(list(L:List)) => #revalParams(toHeatList(L))

     //the original rule to write to revalParams(rvlist...) might be wrong
     rule #revalParams(HL:HeatList) => revalParams(rvlist(hListToList(HL)))
          requires isAllKResultInHeatList(HL)
          [structural]
     /*TODO(liyi): might not need this later
     rule revalParams(list(L:List)) => revalParams(rvlist(L))
          requires all(L, isKResult)
          [structural]
     */

     syntax KItem ::= maybeBind(List, List)
     syntax KItem ::= elabCall(RValue, List, Type, List)

     context Call(_, (HOLE:KItem => revalParams(HOLE)))
     rule Call(Lbl:KLabel(V:K, t(S:Set, pointerType(t(S':Set, functionType(T:Type, P:List))))), rvlist(L:List))
          => maybeBind(P, L)
          ~> elabCall(Lbl(V, t(S, pointerType(t(S', functionType(T, P))))), L, T, .List)
          requires (#klabel(Lbl) ==K #klabel(`tv`) orBool #klabel(Lbl) ==K #klabel(`te`))
               andBool (isCompleteType(T) orBool isVoidType(T))
               andBool notBool isArrayType(T) // Don't think this is possible.
     rule (.K => CV("EFC1", "function call with incomplete or invalid return type.",
               "6.5.2.2:2"))
          ~> Call(Lbl:KLabel(_, t(_, pointerType(t(_, functionType(T:Type, _))))), rvlist(_))
          requires (#klabel(Lbl) ==K #klabel(`tv`) orBool #klabel(Lbl) ==K #klabel(`te`))
               andBool (notBool (isCompleteType(T) orBool isVoidType(T))
                    orBool isArrayType(T))

     // Only attempt to bind if we have a prototype.
     rule maybeBind(.List, _) => .K
     rule maybeBind(P:List, L:List) => elaborate(bind(.List, P, L))
          requires P =/=K .List

     rule elabCall(te(K:K, _), L:List, T:Type, .List)
          => te(Call(K, list(L)), T)
     rule elabCall(tv(V:CValue, T:Type), L:List, T':Type, .List)
          => te(Call(tv(V, T), list(L)), T')
     rule elabCall(te(K:K, _), _, T:Type, L:List)
          => te(Call(K, list(L)), T)
          requires L =/=K .List
     rule elabCall(tv(V:CValue, T:Type), _, T':Type, L:List)
          => te(Call(tv(V, T), list(L)), T')
          requires L =/=K .List

     syntax KResult ::= "fauxParam"
     rule elaborateDone((Computation(te((fauxParam := V:K), _)) => .K) ~> _)
          ~> elabCall(_, _, _, _:List (.List => ListItem(V)))
     rule (elaborateDone(.K) => .K)
          ~> elabCall(_, _, _, _)

     rule bindParam(_, T:Type, V:RValue)
          => runInit(Computation(ncle(fauxParam, T) := V))
     rule bindParam(_) => .K

endmodule
