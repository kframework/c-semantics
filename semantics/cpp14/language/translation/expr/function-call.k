module CPP-EXPR-FUNCTION-CALL
     imports COMPAT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-BINDING-SYNTAX
     imports CPP-CLASS-SYNTAX
     imports CPP-DECL-INITIALIZER-SYNTAX
     imports CPP-EXPR-MEMBERS-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ELABORATOR-SYNTAX
     imports CPP-OVERLOADING-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule CallExpr(Lbl:KLabel(_::K, _::K, T:CPPFunctionType) #as V::Val, list(A::List))
          => elabCall(V, A, getReturnType(T), list(bindParams(getParams(T), A)))
          requires isLKLabel(#klabel(Lbl))

     syntax KItem ::= elabCall(Val, List, CPPType, StrictList) [strict(4)]
     rule elabCall(Fun::Val, Args::List, T::CPPType, krlist(Temps::List))
          => makeCall(BuiltinCallOp(Fun, Temps), combine(trace(Fun), hasTrace(list(Args)), #klabel(`CallExpr`)), T)

     syntax TExpr ::= makeCall(Expr, Trace, CPPType) [function]
     rule makeCall(E::Expr, Tr::Trace, T::CPPType) => le(E, Tr, T)
          requires isUnnamedLValue(T)
     rule makeCall(E::Expr, Tr::Trace, T::CPPType) => xe(E, Tr, T)
          requires isUnnamedXValue(T)
     rule makeCall(E::Expr, Tr::Trace, T::CPPType) => pre(E, Tr, T) [owise]

     syntax List ::= bindParams(List, List) [function]
     rule bindParams(ListItem(T:CPPType) P::List, ListItem(Init::Init) A::List)
          => ListItem(figureInit(le(temp(!I:Int, T), noTrace, T), T, AutoStorage, Init)) bindParams(P, A)
          requires notBool (isCPPRefType(T) andBool isExpr(Init))
     // in this case we are calling bindReference instead of the regular initialization scenario, but
     // bindReference shouldn't be executed in the calling context, it needs to be executed only in the 
     // called function, otherwise we will end up with an lvalue where the parameter should be an xvalue.
     rule bindParams(ListItem(T:CPPRefType) P::List, ListItem(Init:Expr) A::List)
          => ListItem(Init) bindParams(P, A)
     // ignore implicit object parameter for static function member
     rule bindParams(ListItem(implicitObjectParameter(t(... st: no-type))) P::List,
                     ListItem(impliedObjArg(Obj::Expr)) A::List)
          => ListItem(Obj) bindParams(P, A)
     rule bindParams(ListItem(implicitObjectParameter(T::CPPType)) P::List, ListItem(impliedObjArg(Obj::Expr)) A::List)
          => ListItem(setThis(& ParenthesizedCast(T, Obj))) bindParams(P, A)
          requires T =/=K type(no-type)
     rule bindParams(.List, .List) => .List
     rule bindParams(ListItem(variadic), .List) => .List
endmodule
