module CPP-TRANSLATION-EXPR-ALIGNOF
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-ALIGNMENT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TRANSLATION-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule (.K => typeof(E)) ~> AlignofExpr(E::Expr)

     rule typeof(T:CPPType) ~> AlignofExpr(E::Expr) => prv(byteAlignofType(T), hasTrace(AlignofExpr(E)), type(size_t))

     rule AlignofType(T:CPPType) => prv(byteAlignofType(T), hasTrace(AlignofType(T)), type(size_t))

endmodule
