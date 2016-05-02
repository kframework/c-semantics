module C-EXPR-ALIGNOF
     imports C-ABSTRACT-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-TYPING-EXPR-SYNTAX
     imports C-ALIGNMENT-SYNTAX
     imports C-ELABORATOR-SYNTAX

     rule AlignofExpression(E:K) => alignofType(typeof(E))
     rule AlignofType(T:Type, _) => alignofType(T)
     rule AlignofType(typeof(T:Type), _) => alignofType(T)

endmodule

