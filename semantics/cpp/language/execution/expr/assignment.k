module CPP-EXECUTION-EXPR-ASSIGNMENT-SYNTAX
     imports BASIC-K
     syntax KItem ::= fillRHoles(K, K) [function, klabel(fillRHolesCpp)]

     syntax KItem ::= fillLHoles(K, K) [function, klabel(fillLHolesCpp)]
endmodule

module CPP-EXECUTION-EXPR-ASSIGNMENT
     imports CPP-EXECUTION-EXPR-ASSIGNMENT-SYNTAX
     imports BOOL
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-MEMORY-WRITING-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule lv(Loc:SymLoc, Tr::Trace, T::CPPType) := prv(V::CPPValue, Tr'::Trace, T'::CPPType)
          => write(Loc, convertType(utype(T), prv(V, Tr', T')), T)
          ~> lv(Loc, Tr, T)
          requires Execution() andBool notBool isCPPClassType(T)

     rule lv(Loc:SymLoc, Tr::Trace, T::CPPType) :=init prv(V::CPPValue, Tr'::Trace, T'::CPPType)
          => init(Loc, convertType(utype(T), prv(V, Tr', T')), T)
          ~> lv(Loc, Tr, T)
          requires Execution() andBool notBool isCPPClassType(T)

     rule compoundAssign(L:LVal, R::Expr, _)
          => fillLHoles(L, fillRHoles(L, R))
          requires Execution()

     context compoundOp(Lbl:KLabel(_, HOLE:KItem))
          requires Execution()

     rule compoundOp(Lbl:KLabel(L:K, R:KResult)) => Lbl(L, R)
          requires Execution()

     rule fillRHoles(V::PRVal, RHOLE) => V

     rule fillRHoles(V::PRVal, Lbl:KLabel(L:K))
          => Lbl(fillRHoles(V, L))
          requires #klabel(Lbl) =/=K #klabel(`compoundAssignCpp`) andBool #klabel(Lbl) =/=K #klabel(`postOpCpp`)

     rule fillRHoles(V::PRVal, Lbl:KLabel(L:K, R:K))
          => Lbl(fillRHoles(V, L), fillRHoles(V, R))
          requires #klabel(Lbl) =/=K #klabel(`compoundAssignCpp`) andBool #klabel(Lbl) =/=K #klabel(`postOpCpp`)

     rule fillRHoles(V::PRVal, Lbl:KLabel(L:K, M:K, R:K))
          => Lbl(fillRHoles(V, L), fillRHoles(V, M), fillRHoles(V, R))
          requires #klabel(Lbl) =/=K #klabel(`compoundAssignCpp`) andBool #klabel(Lbl) =/=K #klabel(`postOpCpp`)

     rule fillRHoles(_, K:K) => K [owise]

     rule fillLHoles(V::LVal, LHOLE) => V

     rule fillLHoles(V::LVal, Lbl:KLabel(L:K))
          => Lbl(fillLHoles(V, L))
          requires #klabel(Lbl) =/=K #klabel(`compoundAssignCpp`) andBool #klabel(Lbl) =/=K #klabel(`postOpCpp`)

     rule fillLHoles(V::LVal, Lbl:KLabel(L:K, R:K))
          => Lbl(fillLHoles(V, L), fillLHoles(V, R))
          requires #klabel(Lbl) =/=K #klabel(`compoundAssignCpp`) andBool #klabel(Lbl) =/=K #klabel(`postOpCpp`)

     rule fillLHoles(V::PRVal, Lbl:KLabel(L:K, M:K, R:K))
          => Lbl(fillLHoles(V, L), fillLHoles(V, M), fillLHoles(V, R))
          requires #klabel(Lbl) =/=K #klabel(`compoundAssignCpp`) andBool #klabel(Lbl) =/=K #klabel(`postOpCpp`)

     rule fillLHoles(_, K:K) => K [owise]

endmodule
