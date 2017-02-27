module CPP-STMT-TRY
     imports C-CONFIGURATION
     imports COMPAT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-DECL-DECLARATOR-SYNTAX
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

     rule (.K => elaborate(S)) ~> CatchAnyOp(S::Stmt)
     rule <k> elaborateDone(S:K) ~> CatchAnyOp(_) => .K ...</k>
          <elab>... .K => CatchAnyOp(S) </elab>

     context evalThrow(HOLE:Expr, _) [result(Val)]

     rule Throw(E::Expr) => prepareThrow(E, E)

     syntax Expr ::= prepareThrow(AExpr, K)
     context prepareThrow(_, HOLE:TypeExpr => typeof(HOLE)) [result(CPPType)]

     rule prepareThrow(_, T:CPPArrayType => type(pointerType(innerType(T))))
     rule prepareThrow(_, T:CPPFunctionType => type(pointerType(T)))
     rule prepareThrow(E::Expr, T:CPPType)
          => evalThrow(figureInit(le(temp(!I:Int, utype(T)), noTrace, utype(T)), utype(T), AutoStorage, E), E)
     rule prepareThrow(NoExpression(), NoExpression())
          => pre(ThrowOp(exceptionObject(type(no-type))), hasTrace(Throw(NoExpression())), type(void))

     syntax Expr ::= evalThrow(Expr, Expr)

     rule evalThrow(V:Val, E::Expr) => pre(ThrowOp(V), hasTrace(E), type(void))

     rule exceptionObject(T::CPPType) => le(exceptionObject(T), noTrace, T)

     context CatchStmt(NormalizedDecl(... type: HOLE:AType), _)
     context CatchStmt(DeclaratorAndSpecifiers(NormalizedDecl(... type: HOLE:AType), _), _)
     rule (.K => elaborate(BlockStmt(I, ListItem(processCatchDecl(D)) L))) ~> CatchStmt(NormalizedDecl(... type: _:CPPType) #as D::Decl, BlockStmt(I::Int, L::List))
     rule (.K => elaborate(BlockStmt(I, ListItem(processCatchDecl(D)) L))) ~> CatchStmt(DeclaratorAndSpecifiers(NormalizedDecl(... type: _:CPPType), _) #as D::Decl, BlockStmt(I::Int, L::List))

     rule <k> elaborateDone(pushBlock(I::Int) 
              ~> declareNonStaticObject(... t: T::CPPType) #as D:KItem ~> K:K) 
              ~> CatchStmt(_, _)
              => .K
          ...</k>
          <elab>... .K => CatchOp(T, {pushBlock(I) ~> D ~> K}:>Stmt) </elab>

     syntax Decl ::= processCatchDecl(Decl) [function]
     syntax Declarator ::= processCatchDecl(Declarator) [function]
     rule processCatchDecl(DeclaratorAndSpecifiers(D::Declarator, S::Set)) => DeclaratorAndSpecifiers(processCatchDecl(D), S)
     rule processCatchDecl(NormalizedDecl(... type: T::CPPType, init: NoInit() => exceptionObject(T)))
     rule processCatchDecl(NormalizedDecl(... type: T:CPPArrayType => type(pointerType(innerType(T)))))
     rule processCatchDecl(NormalizedDecl(... type: T:CPPFunctionType => type(pointerType(T))))
     rule processCatchDecl(D::Decl) => D [owise]

endmodule
