module CPP-EXECUTION-EXPR-INC-AND-DEC
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-EXECUTION-EXPR-ASSIGNMENT-SYNTAX

     rule postOp(LV:LVal, Op::Expr, _) => #postOp(LV, fillLHoles(LV, Op))
          requires Execution()

     syntax KItem ::= #postOp(K, K) [klabel(#postOpCpp)]

     context #postOp((HOLE:Expr => reval(HOLE)), _) [result(PRV)]

     rule #postOp(V:PRVal, Op:K) => fillRHoles(V, Op) ~> discard ~> V

endmodule
