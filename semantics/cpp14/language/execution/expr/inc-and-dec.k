module CPP-EXPR-INC-AND-DEC
     imports CPP-DYNAMIC-SYNTAX

     rule postOp(LV:LVal, Op::Expr, _) => #postOp(LV, fillLHoles(LV, Op))

     syntax KItem ::= #postOp(K, K) [klabel(#postOpCpp)]
     context #postOp((HOLE:Expr => reval(HOLE)), _) [result(PRVal)]
     rule #postOp(V:PRVal, Op:K) => fillRHoles(V, Op) ~> discard ~> V

endmodule
