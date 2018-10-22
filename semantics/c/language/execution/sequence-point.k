module C-SEQUENCE-POINT-SYNTAX
     syntax KItem ::= "sequencePoint"
     syntax KItem ::= "fullExpression"
endmodule

module C-SEQUENCE-POINT
     imports C-CONFIGURATION
     imports C-SEQUENCE-POINT-SYNTAX

     rule [sequencePoint]:
          <k> sequencePoint => .K ...</k>
          <locs-written> _ => .Set </locs-written>
          [structural]

     // TODO(dwightguth): destroy temporaries in C++
     rule fullExpression => sequencePoint

endmodule
