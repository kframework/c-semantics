module C-SEQUENCE-POINT-SYNTAX
     syntax K ::= "sequencePoint"
endmodule

module C-SEQUENCE-POINT
     imports C-SEQUENCE-POINT-SYNTAX
     rule [sequencePoint]:
          <k> sequencePoint => . ...</k>
          <locsWrittenTo> _ => .Bag </locsWrittenTo>
          [structural]
endmodule
