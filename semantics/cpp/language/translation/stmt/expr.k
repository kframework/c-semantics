module CPP-TRANSLATION-STMT-EXPR
     imports C-CONFIGURATION
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-SYNTAX
     imports CPP-COMMON-STMT-EXPR-SYNTAX

     rule <k> TExpressionStmt(V:Val)  => .K ...</k>
          <elab>... .K => ExpressionStmt(V) </elab>
          requires (isTExpr(V) orBool isDep(V)) andBool notBool isConvertableDiscardedExpr(V)

     rule TExpressionStmt(V::GLVal => prDiscardedExpr(V))
          requires isConvertableDiscardedExpr(V)

     // we add the first clause of this side condition in order to ensure
     // translation gets stuck if the expression evaluates to something that
     // makes the program ill-formed, like "cannot-convert" or "notFound"
     rule TExpressionStmt(V::Val) => .K
          requires isEvalVal(V) andBool notBool isConvertableDiscardedExpr(V)

     rule prDiscardedExpr(pre(E::Expr, Tr::Trace, T::CPPType)) => pre(prDiscardedExpr(E), Tr, T)

     rule glDiscardedExpr(le(E::Expr, Tr::Trace, T::CPPType)) => pre(glDiscardedExpr(E), Tr, T)

     rule glDiscardedExpr(xe(E::Expr, Tr::Trace, T::CPPType)) => pre(glDiscardedExpr(E), Tr, T)

     rule glDiscardedExpr(pre(E::Expr, Tr::Trace, T::CPPType)) => pre(glDiscardedExpr(E), Tr, T)

     rule NullStmt() => .K

endmodule
