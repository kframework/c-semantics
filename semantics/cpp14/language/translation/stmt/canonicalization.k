module CPP-STMT-CANONICALIZATION
      imports K-EQUAL
      imports LIST
      imports CPP-ABSTRACT-SYNTAX
      imports CPP-SYNTAX

      rule CompoundAStmt(L::List) => BlockStmt(!N:Int, canonicalizeAStmts(L)) [anywhere]
      rule LabelAStmt(X::CId, L::List) => LabelStmt(X, canonicalizeAStmts(L)) [anywhere]
      rule IfAStmt(E::Expr, S1:Block, S2:Block) => IfStmt(E, canonicalizeAStmt(S1), canonicalizeAStmt(S2)) [anywhere]
      rule IfAStmt(_::Expr, _, (NoStatement() => CompoundAStmt(.List))) [anywhere]
      rule IfAStmt(_::Expr, S::Stmt => CompoundAStmt(ListItem(S)), _)
           requires notBool isBlock(S) [anywhere]
      rule IfAStmt(_::Expr, _, S::AStmt => CompoundAStmt(ListItem(S)))
           requires notBool isBlock(S) andBool S =/=K NoStatement() [anywhere]

      syntax List ::= canonicalizeAStmts(List) [function]
      rule canonicalizeAStmts(ListItem(E:Expr) L::List) => ListItem(ExpressionStmt(E)) canonicalizeAStmts(L)
      rule canonicalizeAStmts(ListItem(S::Stmt) L::List) => ListItem(S) canonicalizeAStmts(L) [owise]
      rule canonicalizeAStmts(.List) => .List

      syntax Stmt ::= canonicalizeAStmt(AStmt) [function]
      rule canonicalizeAStmt(E:Expr) => ExpressionStmt(E)
      rule canonicalizeAStmt(S::Stmt) => S [owise]

endmodule
