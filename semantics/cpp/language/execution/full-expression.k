module CPP-EXECUTION-FULL-EXPRESSION-SYNTAX
     syntax KItem ::= "fullExpression"
endmodule

module CPP-EXECUTION-FULL-EXPRESSION
     imports CPP-EXECUTION-FULL-EXPRESSION-SYNTAX
     imports C-CONFIGURATION
     imports C-SEQUENCE-POINT-SYNTAX
     imports CPP-EXECUTION-TEMPORARY-SYNTAX

     rule fullExpression => destructTemporaries(false) ~> sequencePoint

endmodule
