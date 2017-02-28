module CPP-CLASS-SYNTAX
     imports CPP-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS
     imports INT
     syntax ClassOffset ::= classOffset(Int)
     syntax Expr ::= evalBraceOrEqualInitializer(class: Class, object: Expr, initializer: Expr) [strict(2)]
     syntax This ::= This()
     syntax Expr ::= This
     syntax Bool ::= isOfDerivedClassOf(Expr, Class) [function]
     syntax Expr ::= contrivedObject(CPPType)
     syntax ValResult ::= noObject()
endmodule

module CPP-CLASS
     imports CPP-CLASS-SYNTAX
 endmodule
