module CPP-EXPR-FUNCTION-CALL
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-BINDING-SYNTAX
     imports CPP-DECL-INITIALIZER-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ELABORATOR-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule CallExpr(Lbl:KLabel(V:K, Tr::Trace, t(Q::Quals, S::Set, functionType(T::CPPType, P::CPPTypes, L::LanguageLinkage))), list(A::List))
          => elaborate(bind(argRange(size(A)), toList(P), A))
          ~> elabCall(Lbl(V, Tr, t(Q, S, functionType(T, P, L))), A, T, .K)
          requires isLKLabel(#klabel(Lbl))

     syntax List ::= argRange(Int) [function]
     rule argRange(0) => .List
     rule argRange(I::Int) => argRange(I -Int 1) ListItem(arg(I -Int 1)) [owise]

     syntax KItem ::= elabCall(Val, List, CPPType, K)

     rule (elaborateDone(K:K) => .K)
          ~> elabCall(_, _, _, _ => K)

     rule elabCall(Fun::Val, Args::List, T::CPPType, K:K)
          => makeCall(BuiltinCallOp(Fun, size(Args), K), combine(trace(Fun), hasTrace(list(Args)), #klabel(`CallExpr`)), T)

     syntax TExpr ::= makeCall(Expr, Trace, CPPType) [function]
     rule makeCall(E::Expr, Tr::Trace, T::CPPType) => le(E, Tr, T)
          requires isCPPLVRefType(T) orBool (isCPPRVRefType(T) andBool isCPPFunctionType(innerType(T)))
     rule makeCall(E::Expr, Tr::Trace, T::CPPType) => xe(E, Tr, T)
          requires isCPPRVRefType(T) andBool isObjectType(innerType(T))
     rule makeCall(E::Expr, Tr::Trace, T::CPPType) => pre(E, Tr, T) [owise]

     rule bindParam(X::CId, T::CPPType, Init::Init)
          => bindParamHelper(figureInit(le(Name(NoNNS(), X), noTrace, T), T, Init, Init))
     syntax KItem ::= bindParamHelper(K) [strict]
     rule bindParamHelper(initValue(_, _, S::Stmt)) => S

endmodule
