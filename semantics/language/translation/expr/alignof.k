module C-EXPR-ALIGNOF
     imports C-ABSTRACT-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-ALIGNMENT-SYNTAX

     rule AlignofExpression(E:K) => alignofType(typeof(E))
     rule AlignofType(T:Type, _) => alignofType(T)

endmodule

