module CPP-EXECUTION-DECL-INITIALIZER
     imports CPP-DYNAMIC-SYNTAX

     rule compoundInit(V:Val, E::Expr) => E
          requires Execution()

endmodule
