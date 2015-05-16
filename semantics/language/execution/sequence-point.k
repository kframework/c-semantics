module C-SEQUENCE-POINT
     imports C-DYNAMIC-SYNTAX
     rule [sequencePoint]:
          <k> sequencePoint => .K ...</k>
          <locs-written> _ => .List </locs-written>
          [structural]
endmodule
