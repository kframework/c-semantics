module CPP-TRANSLATION-STMT-TRY
     imports C-CONFIGURATION
     imports COMPAT-SYNTAX
     imports SYMLOC-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-BUILTIN-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-TRANSLATION-DECL-CLASS-DESTRUCTOR-SYNTAX
     imports CPP-TRANSLATION-DECL-DECLARATOR-SYNTAX
     imports CPP-TRANSLATION-DECL-INITIALIZER-SYNTAX
     imports CPP-TRANSLATION-ELABORATOR-SYNTAX
     imports CPP-TRANSLATION-ODR-SYNTAX
     imports CPP-TRANSLATION-TYPING-EXPR-SYNTAX

     rule (.K => elaborate(Try, listToK(Catch)))
          ~> TryStmt(Try::Stmt, Catch::List)

     rule <k> elaborateDone(Try:K, Catch:K) ~> TryStmt(_, _) => .K ...</k>
          <elab>... .K => TryStmt(Try, kSeqToList(Catch)) </elab>

     rule (.K => elaborate(S)) ~> TCatchAnyOp(S::Stmt)

     rule <k> elaborateDone(S:K) ~> TCatchAnyOp(_) => .K ...</k>
          <elab>... .K => CatchAnyOp(S) </elab>

     context Throw.eval(HOLE:Expr, _) [result(Val)]

     rule Throw(E::Expr)
       => Odr.newUse(obj(0, 0, builtinCppSymbol("::std::terminate()")))
       ~> Throw.prepare(E, E)

     syntax Expr ::= "Throw.prepare" "(" AExpr "," K ")"

     context Throw.prepare(_, HOLE:TypeExpr => typeof(HOLE)) [result(CPPType)]

     rule Throw.prepare(_, t(... st: _:CPPSimpleArrayType) #as T::CPPType => type(pointerType(innerType(T))))

     rule Throw.prepare(_, t(... st: functionType(...)) #as T::CPPType => type(pointerType(T)))

     rule Throw.prepare(E::Expr, T:CPPType)
          => Throw.potentiallyInvokeDestructor(T)
          ~> Throw.eval(figureInit(le(temp(!I:Int, utype(T)), noTrace, utype(T)), utype(T), E, CopyInit(), /* will never be used: */ AutoStorage), E)

     rule Throw.prepare(NoExpression(), NoExpression())
          => pre(ThrowOp(exceptionObject(type(no-type))), hasTrace(Throw(NoExpression())), type(void))

     syntax Expr ::= "Throw.eval" "(" Expr "," Expr ")"

     rule Throw.eval(V:Val, E::Expr) => pre(ThrowOp(V), hasTrace(E), type(void))

     // @ref n4778 13.1/5
     // <quote>
     // When the thrown object is a class object, [...].
     // The destructor is potentially invoked.
     // </quote>
     // <group>
     syntax KItem ::= "Throw.potentiallyInvokeDestructor" "(" CPPType ")"

     rule Throw.potentiallyInvokeDestructor(T::CPPType)
          => #if isCPPClassType(T) #then
                 Class.potentiallyInvokeDestructor(classFromType(T))
             #else .K #fi

     // </group>

     rule exceptionObject(T::CPPType) => le(exceptionObject(T), noTrace, T)
          requires Translation()

     rule <k> CatchStmt(DeclLoc(Loc::CabsLoc, D::Decl) => D, _) ...</k>
          <curr-tr-program-loc> _ => Loc </curr-tr-program-loc>

     context CatchStmt(NormalizedDecl(... type: HOLE:AType), _)

     context CatchStmt(DeclaratorAndSpecifiers(NormalizedDecl(... type: HOLE:AType), _), _)

     rule (.K => elaborate(BlockStmt(ListItem(processCatchDecl(D)) L))) ~> CatchStmt(NormalizedDecl(... type: _:CPPType) #as D::Decl, BlockStmt(L::List))

     rule (.K => elaborate(BlockStmt(ListItem(processCatchDecl(D)) L))) ~> CatchStmt(DeclaratorAndSpecifiers(NormalizedDecl(... type: _:CPPType), _) #as D::Decl, BlockStmt(L::List))

     rule <k> elaborateDone(pushBlock(I::Int)
              ~> declareNonStaticObjectExec(... t: T::CPPType) #as D:KItem ~> K:K)
              ~> CatchStmt(_, _)
              => .K
          ...</k>
          <elab>... .K => CatchOp(T, pushBlock(I) ~> D ~> K) </elab>

     syntax Decl ::= processCatchDecl(Decl) [function]

     syntax Declarator ::= processCatchDecl(Declarator) [function]

     rule processCatchDecl(DeclaratorAndSpecifiers(D::Declarator, S::Set)) => DeclaratorAndSpecifiers(processCatchDecl(D), S)

     rule processCatchDecl(NormalizedDecl(... type: T::CPPType, init: NoInit() => exceptionObject(T)))

     rule processCatchDecl(NormalizedDecl(... type: t(... st: _:CPPSimpleArrayType) #as T::CPPType => type(pointerType(innerType(T)))))

     rule processCatchDecl(NormalizedDecl(... type: t(... st: functionType(...)) #as T::CPPType => type(pointerType(T))))

     rule processCatchDecl(D::Declarator) => D [owise]

endmodule
