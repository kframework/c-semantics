module C-COMMON-EXPR-ALIGNOF
     imports C-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-ALIGNMENT-SYNTAX

     rule AlignofExpression(E:K)
          => alignofType(typeof(E))
          [structural]
     rule AlignofType(T:Type, _) => alignofType(T)
          [structural]

endmodule

