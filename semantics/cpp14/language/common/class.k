module CPP-CLASS-SYNTAX
     imports CPP-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS
     imports INT
     syntax ClassOffset ::= classOffset(Int)
     syntax Expr ::= evalBraceOrEqualInitializer(class: Class, object: Expr, initializer: Expr) [strict(2)]
     syntax KItem ::= returnFromBraceOrEqualInitializer(LVal, Scope)
     syntax This ::= This()
     syntax Expr ::= This
     syntax Expr ::= contrivedObject(CPPType)
     syntax ValResult ::= noObject()
     syntax CId ::= unnamedObject(Class)
     syntax Expr ::= beginConstruction(LVal)
     syntax Expr ::= endConstruction(LVal)
endmodule

module CPP-CLASS
     imports CPP-CLASS-SYNTAX
 endmodule
