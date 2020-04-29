module CPP-EXECUTION-EXPR-ASSIGNMENT-SYNTAX
     imports BASIC-K
     syntax Expr ::= fillRHoles(K, K) [function, klabel(fillRHolesCpp)]

     syntax Expr ::= fillLHoles(K, K) [function, klabel(fillLHolesCpp)]
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

     syntax ResolvedExpr ::= compoundExprs(Expr, Expr)
     rule compoundExprs(L::Expr, R::Expr)
         => ((L + R)
        #Or ((L - R)
        #Or ((L * R)
        #Or ((L / R)
        #Or ((L % R)
        #Or ((L & R)
        #Or ((L ^ R)
        #Or ((L | R)
        #Or ((L << R)
        #Or ((L >> R))))))))))) [macro]

     context compoundOp(_ + HOLE:Expr) requires Execution()
     context compoundOp(_ - HOLE:Expr) requires Execution()
     context compoundOp(_ * HOLE:Expr) requires Execution()
     context compoundOp(_ / HOLE:Expr) requires Execution()
     context compoundOp(_ % HOLE:Expr) requires Execution()
     context compoundOp(_ & HOLE:Expr) requires Execution()
     context compoundOp(_ ^ HOLE:Expr) requires Execution()
     context compoundOp(_ | HOLE:Expr) requires Execution()
     context compoundOp(_ << HOLE:Expr) requires Execution()
     context compoundOp(_ >> HOLE:Expr) requires Execution()

     rule compoundOp(compoundExprs(_, R::Expr) #as E:ResolvedExpr) => E
          requires isKResult(R) andBool Execution()

     rule fillRHoles(V::Expr, pre(L::Expr := E::Expr, Tr::Trace, T::CPPType)) => pre(L := fillRHoles(V, E), Tr, T)
     rule fillRHoles(V::Expr, V':PRV) => V'
     rule fillRHoles(V::Expr, ConvertType(T::CPPType, E::Expr)) => ConvertType(T, fillRHoles(V, E))
     rule fillRHoles(V::Expr, compoundOp(E::Expr)) => compoundOp(fillRHoles(V, E))
     rule fillRHoles(V::Expr, RHOLE) => V
     rule fillRHoles(V::Expr, L::Expr + R::Expr) => fillRHoles(V, L) + R
     rule fillRHoles(V::Expr, L::Expr - R::Expr) => fillRHoles(V, L) - R
     rule fillRHoles(V::Expr, L::Expr * R::Expr) => fillRHoles(V, L) * R
     rule fillRHoles(V::Expr, L::Expr / R::Expr) => fillRHoles(V, L) / R
     rule fillRHoles(V::Expr, L::Expr % R::Expr) => fillRHoles(V, L) % R
     rule fillRHoles(V::Expr, L::Expr & R::Expr) => fillRHoles(V, L) & R
     rule fillRHoles(V::Expr, L::Expr ^ R::Expr) => fillRHoles(V, L) ^ R
     rule fillRHoles(V::Expr, L::Expr | R::Expr) => fillRHoles(V, L) | R
     rule fillRHoles(V::Expr, L::Expr << R::Expr) => fillRHoles(V, L) << R
     rule fillRHoles(V::Expr, L::Expr >> R::Expr) => fillRHoles(V, L) >> R

     rule fillLHoles(LV::Expr, pre(LHOLE := R::Expr, Tr::Trace, T::CPPType))
          => pre(LV := R, Tr, T)

endmodule
