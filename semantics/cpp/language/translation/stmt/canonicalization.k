module CPP-TRANSLATION-STMT-CANONICALIZATION
      imports K-EQUAL
      imports LIST
      imports CPP-ABSTRACT-SYNTAX
      imports CPP-SYNTAX

      rule CompoundAStmt(L::List) => BlockStmt(canonicalizeAStmts(L)) [anywhere]

      rule LabelAStmt(X::CId, L::List) => TLabelStmt(X, canonicalizeAStmts(L)) [anywhere]

      rule IfAStmt(E::Expr, S1:Block, S2:Block) => IfTStmt(E, canonicalizeAStmt(S1), canonicalizeAStmt(S2)) [anywhere]

      rule IfAStmt(E::Expr, S1::AStmt, NoStatement()) => IfAStmt(E, S1, CompoundAStmt(.List)) [anywhere]

      rule IfAStmt(E::Expr, S1::AStmt, S2::AStmt) => IfAStmt(E, CompoundAStmt(ListItem(S1)), S2)
           requires notBool isBlock(S1) [anywhere]

      rule IfAStmt(E::Expr, S1::AStmt, S2::AStmt) => IfAStmt(E::Expr, S1::AStmt, CompoundAStmt(ListItem(S2)))
           requires notBool isBlock(S2) andBool S2 =/=K NoStatement() [anywhere]

      rule WhileAStmt(E::Expr, S:Block) => WhileTStmt(E, canonicalizeAStmt(S)) [anywhere]

      rule WhileAStmt(E::Expr, S::AStmt) => WhileAStmt(E, CompoundAStmt(ListItem(S)))
           requires notBool isBlock(S) [anywhere]

      rule ForAStmt(NoStatement(), C::AExpr, E::AExpr, S::AStmt) => ForAStmt(NullStmt(), C::AExpr, E, S) [anywhere]

      rule ForAStmt(D::AStmt, NoExpression(), E::AExpr, S::AStmt) => ForAStmt(D, BoolLiteral(true), E, S) [anywhere]

      rule ForAStmt(D::AStmt, C::AExpr, E::AExpr, S::Stmt) => ForAStmt(D, C, E, CompoundAStmt(ListItem(S)))
           requires notBool isBlock(S) [anywhere]

      rule ForAStmt(D::Stmt, C::Expr, E:Expr, S:Block) => ForTStmt(D, C, TExpressionStmt(E), S)

      rule ForAStmt(D::Stmt, C::Expr, NoExpression(), S:Block) => ForTStmt(D, C, NullStmt(), S)

      rule TryAStmt(S:Block, L::List) => TryStmt(canonicalizeAStmt(S), canonicalizeAStmts(L)) [anywhere]

      rule CatchAStmt(D:Decl, S:Block) => CatchStmt(D, canonicalizeAStmt(S)) [anywhere]

      rule CatchAStmt(Ellipsis(), S:Block) => TCatchAnyOp(canonicalizeAStmt(S)) [anywhere]

      syntax List ::= canonicalizeAStmts(List) [function]

      rule canonicalizeAStmts(ListItem(E:Expr) L::List) => ListItem(TExpressionStmt(E)) canonicalizeAStmts(L)

      rule canonicalizeAStmts(ListItem(S:AStmt) L::List) => ListItem(S) canonicalizeAStmts(L) [owise]

      rule canonicalizeAStmts(.List) => .List

      syntax Stmt ::= canonicalizeAStmt(AStmt) [function]

      rule canonicalizeAStmt(E:Expr) => TExpressionStmt(E)

      rule canonicalizeAStmt(S::Stmt) => S [owise]

endmodule
