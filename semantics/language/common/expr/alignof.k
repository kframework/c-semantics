module C-COMMON-EXPR-ALIGNOF-SYNTAX
     // Match the sizeof pattern, but it's pretty contrived.
     syntax Int ::= byteAlignofType(Type) [function]

     syntax K ::= alignofType(K) [strict]
endmodule

module C-COMMON-EXPR-ALIGNOF
     imports C-COMMON-EXPR-ALIGNOF-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-TYPING-SYNTAX

     rule AlignofExpression(E:K)
          => alignofType(typeof(E))
          [structural]
     rule AlignofType(_:Type, _) => tv(1, cfg:sizeut)
          [structural]

     rule alignofType(T:Type) => tv(byteAlignofType(T), cfg:sizeut)
          [structural]

     // TODO(chathhorn): make configurable.
     rule byteAlignofType(_:Type) => 1

endmodule

