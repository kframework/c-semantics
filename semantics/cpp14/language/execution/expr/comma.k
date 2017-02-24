module CPP-EXPR-COMMA
     imports C-SEQUENCE-POINT-SYNTAX
     imports CPP-SYNTAX

     rule Comma(V:Val, E::Expr) => sequencePoint ~> E

endmodule
