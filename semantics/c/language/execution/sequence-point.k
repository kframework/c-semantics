module C-SEQUENCE-POINT-SYNTAX
     syntax KItem ::= "sequencePoint"
endmodule

module C-SEQUENCE-POINT
     imports C-CONFIGURATION
     imports C-SEQUENCE-POINT-SYNTAX

     rule [sequencePoint]:
          <k> sequencePoint => .K ...</k>
          <locs-written> _ => .Set </locs-written>
          [structural]

endmodule
