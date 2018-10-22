module CPP-EXECUTION-EXPR-ASSIGNMENT
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

endmodule
