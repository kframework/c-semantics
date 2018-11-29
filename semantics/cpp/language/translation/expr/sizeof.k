module CPP-TRANSLATION-EXPR-SIZEOF
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TRANSLATION-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule (.K => typeof(E)) ~> SizeofExpr(E::Expr)

     rule typeof(T:CPPType) ~> SizeofExpr(E::Expr) => prv(byteSizeofType(T), hasTrace(SizeofExpr(E)), type(size_t))

     rule SizeofType(T:CPPType) => prv(byteSizeofType(T), hasTrace(SizeofType(T)), type(size_t))


endmodule
