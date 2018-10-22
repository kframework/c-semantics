module C-EXPR-FUNCTION-CALL
     imports BASIC-K
     imports BOOL
     imports K-EQUAL
     imports COMPAT-SYNTAX
     imports C-ABSTRACT-SORTS
     imports C-BINDING-SYNTAX
     imports C-CHECK-USE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ELABORATOR-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     syntax KResult ::= rvlist(List)

     syntax KItem ::= revalParams(K)
                    | #revalParams(HeatList) [strict]
     //TODO(liyi): overcome the context associative matching
     //context revalParams(list(_ ListItem((HOLE:KItem => reval(HOLE))) _))

     rule revalParams(list(L:List)) => #revalParams(toHeatList(L))

     //the original rule to write to revalParams(rvlist...) might be wrong
     rule #revalParams(HL:HeatList) => revalParams(rvlist(hListToList(HL)))
          requires allRValueInHeatList(HL)
          [structural]
     /*TODO(liyi): might not need this later
     rule revalParams(list(L:List)) => revalParams(rvlist(L))
          requires all(L, isKResult)
          [structural]
     */

     syntax KItem ::= maybeBind(List, List)

     context Call(_, (HOLE:KItem => revalParams(HOLE)))
     rule Call(Lbl:KLabel(V:K, ut(S::Set, pointerType(t(Qs'::Quals, S'::Set, functionType(T::UType, P:List))))), rvlist(L:List))
          => maybeBind(P, L)
          ~> elabCall(Lbl(V, ut(S, pointerType(t(Qs', S', functionType(T, P))))), L, T, .List)
          requires isRKLabel(#klabel(Lbl))
               andBool (isCompleteType(type(T)) orBool isVoidType(type(T)))
               andBool notBool isArrayType(type(T)) // Don't think this is possible.
     rule (.K => CV("EFC1", "Function call with incomplete or invalid return type."))
          ~> Call(Lbl:KLabel(_, ut(_, pointerType(t(_, _, functionType(T::UType, _))))), rvlist(_))
          requires isRKLabel(#klabel(Lbl))
               andBool (notBool (isCompleteType(type(T)) orBool isVoidType(type(T)))
                    orBool isArrayType(type(T)))

     // Only attempt to bind if we have a prototype.
     rule maybeBind(.List, _) => .K
     rule maybeBind(P:List, L:List) => elaborate(bind(P, P, L))
          requires P =/=K .List

     syntax KItem ::= elabCall(RValue, List, UType, List)
     rule elabCall(te(K:K, _), L::List, T::UType, .List)
          => te(Call(K, list(L)), T)
     rule elabCall(tv(V::CValue, T::UType), L::List, T'::UType, .List)
          => te(Call(checkUse(tv(V, T)), list(L)), T')
     rule elabCall(te(K:K, _), _, T::UType, L::List)
          => te(Call(K, list(L)), T)
          requires L =/=K .List
     rule elabCall(tv(V::CValue, T::UType), _, T'::UType, L::List)
          => te(Call(checkUse(tv(V, T)), list(L)), T')
          requires L =/=K .List

     syntax Nclv ::= "fauxParam"
     rule elaborateDone((Initializer(fauxParam := V:K) => .K) ~> _)
          ~> elabCall(_, _, _, _:List (.List => ListItem(V)))
     rule (elaborateDone(.K) => .K) ~> elabCall(_, _, _, _)

     rule bindParam(_, T:Type, V:RValue)
          => Initializer(ncle(fauxParam, T) := V)

endmodule
