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
      rule ForAStmt((NoStatement() => NullStmt()), _::AExpr, _, _) [anywhere]
      rule ForAStmt(_, (NoExpression() => BoolLiteral(true)), _, _) [anywhere]
      rule ForAStmt(_, _::AExpr, _, S::Stmt => CompoundAStmt(ListItem(S)))
           requires notBool isBlock(S) [anywhere]
      rule ForAStmt(D::Stmt, C::Expr, E:Expr, S:Block) => ForStmt(D, C, ExpressionStmt(E), S)
      rule ForAStmt(D::Stmt, C::Expr, NoExpression(), S:Block) => ForStmt(D, C, NullStmt(), S)

      syntax List ::= canonicalizeAStmts(List) [function]
      rule canonicalizeAStmts(ListItem(E:Expr) L::List) => ListItem(ExpressionStmt(E)) canonicalizeAStmts(L)
      rule canonicalizeAStmts(ListItem(S::Stmt) L::List) => ListItem(S) canonicalizeAStmts(L) [owise]
      rule canonicalizeAStmts(.List) => .List

      syntax Stmt ::= canonicalizeAStmt(AStmt) [function]
      rule canonicalizeAStmt(E:Expr) => ExpressionStmt(E)
      rule canonicalizeAStmt(S::Stmt) => S [owise]

endmodule
