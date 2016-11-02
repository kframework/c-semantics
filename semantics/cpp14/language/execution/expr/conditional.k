module CPP-EXPR-CONDITIONAL
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX

     context ConditionalOp((HOLE:Expr => reval(HOLE)), _, _, _, _) [result(PRVal)]
     rule ConditionalOp(prv(0, _, _), _, E::Expr, prvalue, T::CPPType)
          => ConvertType(T, makePRVal(E))
     rule ConditionalOp(prv(1, _, _), E::Expr, _, prvalue, T::CPPType)
          => ConvertType(T, makePRVal(E))
     rule ConditionalOp(prv(0, _, _), _, E::Expr, lvalue, T::CPPType)
          => setType(T, E)
     rule ConditionalOp(prv(1, _, _), E::Expr, _, lvalue, T::CPPType)
          => setType(T, E)

     syntax Expr ::= setType(CPPType, Expr) [strict]
     rule setType(T::CPPType, lv(Loc::SymLoc, Tr::Trace, _)) => lv(Loc, Tr, T)

endmodule
