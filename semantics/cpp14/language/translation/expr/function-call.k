module CPP-EXPR-FUNCTION-CALL
     imports COMPAT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-BINDING-SYNTAX
     imports CPP-DECL-INITIALIZER-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ELABORATOR-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule CallExpr(Lbl:KLabel(V:K, Tr::Trace, t(Q::Quals, S::Set, functionType(T::CPPType, P::CPPTypes, L::LanguageLinkage))), list(A::List))
          => elabCall(Lbl(V, Tr, t(Q, S, functionType(T, P, L))), A, T, list(bindParams(toList(P), A)))
          requires isLKLabel(#klabel(Lbl))

     syntax KItem ::= elabCall(Val, List, CPPType, StrictList) [strict(4)]

     rule elabCall(Fun::Val, Args::List, T::CPPType, krlist(Temps::List))
          => makeCall(BuiltinCallOp(Fun, Temps), combine(trace(Fun), hasTrace(list(Args)), #klabel(`CallExpr`)), T)

     syntax TExpr ::= makeCall(Expr, Trace, CPPType) [function]
     rule makeCall(E::Expr, Tr::Trace, T::CPPType) => le(E, Tr, T)
          requires isCPPLVRefType(T) orBool (isCPPRVRefType(T) andBool notBool isCPPFunctionType(innerType(T)))
     rule makeCall(E::Expr, Tr::Trace, T::CPPType) => xe(E, Tr, T)
          requires isCPPRVRefType(T) andBool isObjectType(innerType(T))
     rule makeCall(E::Expr, Tr::Trace, T::CPPType) => pre(E, Tr, T) [owise]

     syntax List ::= bindParams(List, List) [function]
     rule bindParams(ListItem(T::CPPType) P::List, ListItem(Init::Init) A::List)
          => ListItem(figureInit(le(temp(!I:Int, T), noTrace, T), T, AutoStorage, Init, Init)) bindParams(P, A)
     rule bindParams(.List, .List) => .List
     rule bindParams(ListItem(variadic), .List) => .List
endmodule
