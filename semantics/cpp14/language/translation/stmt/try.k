module CPP-STMT-TRY
     imports C-CONFIGURATION
     imports COMPAT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-DECL-INITIALIZER-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ELABORATOR-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule (.K => elaborate(Try, listToK(Catch)))
          ~> TryStmt(Try::Stmt, Catch::List)
     rule <k> elaborateDone(Try:K, Catch:K) ~> TryStmt(_, _) => .K ...</k>
          <elab>... .K => TryStmt(Try, kSeqToList(Catch)) </elab>

     rule (.K => elaborate(S)) ~> CatchAnyStmt(S::Stmt)
     rule <k> elaborateDone(S:K) ~> CatchAnyStmt(_) => .K ...</k>
          <elab>... .K => CatchAnyStmt(S) </elab>

     context evalThrow(HOLE:Expr, _) [result(Val)]

     rule Throw(E::Expr) => prepareThrow(E, E)

     syntax Expr ::= prepareThrow(Expr, TypeExpr)
     context prepareThrow(_, HOLE:TypeExpr => typeof(HOLE)) [result(CPPType)]

     rule prepareThrow(_, T:CPPArrayType => type(pointerType(innerType(T))))
     rule prepareThrow(_, T:CPPFunctionType => type(pointerType(T)))
     rule prepareThrow(E::Expr, T:CPPType)
          => evalThrow(figureInit(le(temp(!I:Int, utype(T)), noTrace, utype(T)), utype(T), AutoStorage, E), E)

     syntax Expr ::= evalThrow(Expr, Expr)

     rule evalThrow(V:Val, E::Expr) => pre(ThrowOp(V), hasTrace(E), type(void))


endmodule
