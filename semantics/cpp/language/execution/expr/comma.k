module CPP-EXECUTION-EXPR-COMMA
     imports C-SEQUENCE-POINT-SYNTAX
     imports CPP-SYNTAX
     imports CPP-DYNAMIC-SYNTAX

     rule Comma(V:Val, E::Expr) => sequencePoint ~> E
          requires Execution()

endmodule
