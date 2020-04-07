module CPP-TRANSLATION-INIT
     imports K-REFLECTION
     imports COMMON-INIT-SYNTAX
     imports COMMON-TRANSLATION-UNIT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TRANSLATION-IMPLICIT-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-TRANSLATION-ODR-SYNTAX

     imports C-CONFIGURATION

     rule [[ nameOfCurrentTranslationUnit() => TU ]]
          <curr-tr-tu>TU::String</curr-tr-tu>


     rule [[ Execution() => B ]]
          <compile-time-evaluation> B::Bool </compile-time-evaluation>

     rule isKResult(le(_, _, T::CPPType) #Or xe(_, _, T::CPPType) #Or pre(_, _, T::CPPType)) => notBool isCPPRefType(T)

     context alias [c]: <k> HERE:K ...</k> <compile-time-evaluation> false </compile-time-evaluation>
     context alias [c]: <k> HERE:K ...</k> <compile-time-evaluation> true </compile-time-evaluation> [result(ExecResult)]

     rule <k> TranslationUnit(Tu::String, Decls::List)
               => makeTu(Tu +String Uuid)
               ~> makeNs(GlobalNamespace())
               ~> implicitDecls
               ~> listToK(Decls)
               ~> generateOdrUsedFunctions()
               ~> removeUnusedIdentifiers(Tu +String Uuid)
          ...</k>
          <uuid> Uuid::String </uuid>

          // don't delete this... we want to make sure the fresh counter starts
          // at 1 for each TU because unlike C, C++ doesn't give us unique block
          // numbers directly from the parser, so we are using the fresh counter to
          // assign block numbers. But the fresh counter starts at 0 and block 0
          // is the privileged "haven't entered the outer block of the function yet"
          // block.
          requires !Fresh:Int >=Int 0

     syntax KItem ::= makeNs(Namespace)

     rule <k> makeNs(N::Namespace) => .K ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <namespaces>...
               (.Bag => <ns>...
                             <ns-id> N </ns-id>
                        ...</ns>)
          ...</namespaces>

     rule combine(hasTrace(E::Expr), O::Expr) => hasTrace(fillExpr(O, E))

     rule combine(hasTrace(E::Expr), hasTrace(E2::Expr), O::Expr) => hasTrace(fillExpr(O, E, E2))

     rule combine(hasTrace(E::Expr), hasTrace(E2::Expr), hasTrace(E3::Expr), V::ValueCategory, T::CPPType) => hasTrace(ConditionalOp(E, E2, E3, V, T))

     rule combine(_, _) => noTrace [owise]

     rule combine(_, _::Trace, _) => noTrace [owise]

     rule combine(_, _, _::Trace, _, _) => noTrace [owise]

     rule DeclLoc(L::CabsLoc, D::Decl) => L ~> D

     rule StmtLoc(L::CabsLoc, S::Stmt) => L ~> S

     rule <k> L:CabsLoc => .K ...</k>
          <elab>... .K => L </elab>
          <curr-tr-program-loc> _ => L </curr-tr-program-loc>
          requires Translation()

     rule <k> L:CabsLoc => .K ...</k>
          <curr-program-loc> _ => L </curr-program-loc>
          requires Execution()

     rule <k> ExprLoc(L::CabsLoc, E:Expr) => #ExprLoc(L, E) ...</k>
          <curr-tr-program-loc> _ => L </curr-tr-program-loc>
          requires Translation()

     syntax Expr ::= #ExprLoc(CabsLoc, Expr) [strict(c; 2)]

     rule <k> #ExprLoc(L::CabsLoc, V:Val) => V ...</k>
          <curr-tr-program-loc> _ => L </curr-tr-program-loc>
          requires isEvalVal(V)

     rule <k> #ExprLoc(L::CabsLoc, V:PRExpr) => pre(ExprLoc(L, stripHold(V)), trace(V), type(V)) ...</k>
          <curr-tr-program-loc> _ => L </curr-tr-program-loc>

     rule <k> #ExprLoc(L::CabsLoc, V:XExpr) => xe(ExprLoc(L, stripHold(V)), trace(V), type(V)) ...</k>
          <curr-tr-program-loc> _ => L </curr-tr-program-loc>

     rule <k> #ExprLoc(L::CabsLoc, V:LExpr) => le(ExprLoc(L, stripHold(V)), trace(V), type(V)) ...</k>
          <curr-tr-program-loc> _ => L </curr-tr-program-loc>

     rule (<T>...
               <k> cleanup </k>
               <options> Opts:Set </options>
          ...</T> => .Bag)
          requires notBool (Debug() in Opts)
          [structural]

endmodule
