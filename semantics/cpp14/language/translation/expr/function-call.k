module CPP-EXPR-FUNCTION-CALL
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-BINDING-SYNTAX
     imports CPP-DECL-INITIALIZER-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ELABORATOR-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule CallExpr(Lbl:KLabel(V:K, t(Q::Quals, S::Set, functionType(T::CPPType, P::List, L::LanguageLinkage))), list(A::List))
          => elaborate(bind(P, P, A, 0))
          ~> elabCall(Lbl(V, t(Q, S, functionType(T, P, L))), A, T, .K)
          requires isLKLabel(#klabel(Lbl))

     syntax KItem ::= elabCall(Val, List, CPPType, K)

     rule (elaborateDone(K:K) => .K)
          ~> elabCall(_, _, _, _ => K)

     rule elabCall(Fun::Val, Args::List, T::CPPType, K:K)
          => makeCall(BuiltinCallOp(Fun, size(Args), K), T)

     syntax TExpr ::= makeCall(Expr, CPPType) [function]
     rule makeCall(E::Expr, T::CPPType) => le(E, T)
          requires isCPPLVRefType(T) orBool (isCPPRVRefType(T) andBool isCPPFunctionType(innerType(T)))
     rule makeCall(E::Expr, T::CPPType) => xe(E, T)
          requires isCPPRVRefType(T) andBool isCPPObjectType(innerType(T))
     rule makeCall(E::Expr, T::CPPType) => pre(E, T) [owise]

     rule bindParam(I::Int, T::CPPType, Init::Init)
          => bindParamHelper(figureInit(le(Name(NoNNS(), arg(I)), T), T, Init, Init))
     syntax KItem ::= bindParamHelper(K) [strict]
     rule bindParamHelper(initValue(_, _, S::Stmt)) => S

endmodule
