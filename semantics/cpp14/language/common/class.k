module CPP-CLASS-SYNTAX
     imports CPP-SORTS
     imports CPP-DYNAMIC-SORTS
     imports INT
     syntax ClassOffset ::= classOffset(Int)
     syntax Expr ::= evalBraceOrEqualInitializer(class: Class, object: Expr, initializer: Expr) [strict(2)]
     syntax This ::= This()
     syntax Expr ::= This
endmodule

module CPP-CLASS
     imports CPP-CLASS-SYNTAX
 endmodule
