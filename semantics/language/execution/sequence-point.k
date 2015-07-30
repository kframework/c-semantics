module C-SEQUENCE-POINT-SYNTAX
     syntax KItem ::= "sequencePoint"
endmodule

module C-SEQUENCE-POINT
     imports C-SEQUENCE-POINT-SYNTAX
     imports C-CONFIGURATION
     imports C-DYNAMIC-SYNTAX

     rule [sequencePoint]:
          <k> sequencePoint => .K ...</k>
          <locs-written> _ => .List </locs-written>
          <locs-read> _ => .List </locs-read>
          [structural]

endmodule
