module CPP-STMT-CANONICALIZATION
      imports LIST
      imports CPP-ABSTRACT-SYNTAX
      imports CPP-SYNTAX

      rule CompoundAStmt(L::List) => BlockStmt(!N:Int, canonicalizeAStmts(L)) [anywhere]
      rule LabelAStmt(X::CId, L::List) => LabelStmt(X, canonicalizeAStmts(L))

      syntax List ::= canonicalizeAStmts(List) [function]
      rule canonicalizeAStmts(ListItem(E:Expr) L::List) => ListItem(ExpressionStmt(E)) canonicalizeAStmts(L)
      rule canonicalizeAStmts(ListItem(S::Stmt) L::List) => ListItem(S) canonicalizeAStmts(L) [owise]
      rule canonicalizeAStmts(.List) => .List

endmodule
