module CPP-TRANSLATION-STMT-CANONICALIZATION
      imports K-EQUAL
      imports LIST
      imports CPP-ABSTRACT-SYNTAX
      imports CPP-SYNTAX

      rule CompoundAStmt(L::List) => BlockStmt(!N:Int, canonicalizeAStmts(L)) [anywhere]

      rule LabelAStmt(X::CId, L::List) => TLabelStmt(X, canonicalizeAStmts(L)) [anywhere]

      rule IfAStmt(E::Expr, S1:Block, S2:Block) => IfTStmt(E, canonicalizeAStmt(S1), canonicalizeAStmt(S2)) [anywhere]

      rule IfAStmt(_::Expr, _, (NoStatement() => CompoundAStmt(.List))) [anywhere]

      rule IfAStmt(_::Expr, S::Stmt => CompoundAStmt(ListItem(S)), _)
           requires notBool isBlock(S) [anywhere]

      rule IfAStmt(_::Expr, _, S::AStmt => CompoundAStmt(ListItem(S)))
           requires notBool isBlock(S) andBool S =/=K NoStatement() [anywhere]

      rule WhileAStmt(E::Expr, S:Block) => WhileTStmt(E, canonicalizeAStmt(S)) [anywhere]

      rule WhileAStmt(_::Expr, S::Stmt => CompoundAStmt(ListItem(S)))
           requires notBool isBlock(S) [anywhere]

      rule ForAStmt((NoStatement() => NullStmt()), _::AExpr, _, _) [anywhere]

      rule ForAStmt(_, (NoExpression() => BoolLiteral(true)), _, _) [anywhere]

      rule ForAStmt(_, _::AExpr, _, S::Stmt => CompoundAStmt(ListItem(S)))
           requires notBool isBlock(S) [anywhere]

      rule ForAStmt(D::Stmt, C::Expr, E:Expr, S:Block) => ForTStmt(D, C, TExpressionStmt(E), S)

      rule ForAStmt(D::Stmt, C::Expr, NoExpression(), S:Block) => ForTStmt(D, C, NullStmt(), S)

      rule TryAStmt(S:Block, L::List) => TryStmt(canonicalizeAStmt(S), canonicalizeAStmts(L)) [anywhere]

      rule CatchAStmt(D:Decl, S:Block) => CatchStmt(D, canonicalizeAStmt(S)) [anywhere]

      rule CatchAStmt(Ellipsis(), S:Block) => TCatchAnyOp(canonicalizeAStmt(S)) [anywhere]

      syntax List ::= canonicalizeAStmts(List) [function]

      rule canonicalizeAStmts(ListItem(E:Expr) L::List) => ListItem(TExpressionStmt(E)) canonicalizeAStmts(L)

      rule canonicalizeAStmts(ListItem(S::Stmt) L::List) => ListItem(S) canonicalizeAStmts(L) [owise]

      rule canonicalizeAStmts(.List) => .List

      syntax Stmt ::= canonicalizeAStmt(AStmt) [function]

      rule canonicalizeAStmt(E:Expr) => TExpressionStmt(E)

      rule canonicalizeAStmt(S::Stmt) => S [owise]

endmodule
