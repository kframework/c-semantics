module CPP-EXECUTION-FULL-EXPRESSION-SYNTAX
     syntax KItem ::= "fullExpression"
endmodule

module CPP-EXECUTION-FULL-EXPRESSION
     imports CPP-EXECUTION-FULL-EXPRESSION-SYNTAX
     imports C-CONFIGURATION
     imports C-SEQUENCE-POINT-SYNTAX

     // TODO(dwightguth): destroy temporaries in C++
     rule fullExpression => sequencePoint



endmodule
