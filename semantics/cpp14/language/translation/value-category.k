module CPP-VALUE-CATEGORY-SORTS
     syntax CatExpr
endmodule

module CPP-VALUE-CATEGORY-SYNTAX
     imports CPP-VALUE-CATEGORY-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS

     syntax CatExpr ::= catof(CatExpr)
     syntax CatExpr ::= Expr | ValueCategory | Typed

     syntax Val ::= makeVal(ValueCategory, CPPType, CPPValue, Trace) [function]
     syntax Val ::= makeExpr(ValueCategory, CPPType, Expr, Trace) [function]

endmodule

module CPP-VALUE-CATEGORY
     imports CPP-VALUE-CATEGORY-SYNTAX
     imports BOOL-SYNTAX
     imports K-REFLECTION
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-EXPR-CONDITIONAL-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SORTS

     rule makeVal(lvalue, T::CPPType, V::SymLoc, Tr::Trace) => lv(V, Tr, T)
     rule makeVal(xvalue, T::CPPType, V::SymLoc, Tr::Trace) => xv(V, Tr, T)
     rule makeVal(prvalue, T::CPPType, V::CPPValue, Tr::Trace) => prv(V, Tr, T)
     rule makeExpr(lvalue, T::CPPType, V::Expr, Tr::Trace) => le(V, Tr, T)
     rule makeExpr(xvalue, T::CPPType, V::Expr, Tr::Trace) => xe(V, Tr, T)
     rule makeExpr(prvalue, T::CPPType, V::Expr, Tr::Trace) => pre(V, Tr, T)

     rule catof(ExprLoc(_, E::Expr) => E)

     rule catof(StringLiteral(_, _) => lvalue)
     rule catof(CharacterLiteral(_, _) => prvalue)
     rule catof(IntegerLiteral(_, _) => prvalue)
     rule catof(BoolLiteral(_) => prvalue)
     rule catof(NullPointerLiteral() => prvalue)

     context catof(HOLE:CatExpr)
             requires getKLabel(HOLE) ==K #klabel(`Name`)
                  orBool getKLabel(HOLE) ==K #klabel(`CallExpr`) [result(Val)]
     rule catof(L:LVal => lvalue)
     rule catof(X:XVal => xvalue)
     rule catof(PR:PRVal => prvalue)

     rule catof(ConditionalOperator(_, E2::Expr, E3::Expr))
          => catofConditional(E2, E3)

     syntax CatExpr ::= catofConditional(Expr, Expr)
     rule (.K => typeAndCatOfConditional(E2, E2, E2, E3, E3, E3)) ~> catofConditional(E2::Expr, E3::Expr)
     rule typeAndCat(_, V:ValueCategory) ~> catofConditional(_, _) => catof(V)

endmodule
