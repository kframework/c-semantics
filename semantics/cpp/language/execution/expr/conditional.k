module CPP-EXECUTION-EXPR-CONDITIONAL
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-SYNTAX

     context ConditionalOp((HOLE:Expr => reval(HOLE)), _, _, _, _) requires Execution() [result(PRV)]

     rule ConditionalOp(prv(0, _, _), _, E::Expr, prvalue, T::CPPType)
          => ConvertType(T, makePRVal(E))
          requires Execution()

     rule ConditionalOp(prv(1, _, _), E::Expr, _, prvalue, T::CPPType)
          => ConvertType(T, makePRVal(E))
          requires Execution()

     rule ConditionalOp(prv(0, _, _), _, E::Expr, lvalue, T::CPPType)
          => setType(T, E)
          requires Execution()

     rule ConditionalOp(prv(1, _, _), E::Expr, _, lvalue, T::CPPType)
          => setType(T, E)
          requires Execution()

endmodule
