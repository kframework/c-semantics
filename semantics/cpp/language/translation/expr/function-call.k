module CPP-TRANSLATION-EXPR-FUNCTION-CALL
     imports COMPAT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-CLASS-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-TRANSLATION-DECL-INITIALIZER-SYNTAX
     imports CPP-EXPR-MEMBERS-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TRANSLATION-ELABORATOR-SYNTAX
     imports CPP-TRANSLATION-OVERLOADING-SYNTAX
     imports CPP-TRANSLATION-TEMPORARY-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule CallExpr((lv(_, Tr::Trace, t(... st: functionType(...)) #as T::CPPType) #Or le(_, Tr::Trace, t(... st: functionType(...)) #as T::CPPType)) #as V::Val, list(A::List), krlist(DArgs::List))
          => elabCall(V, isVirtualCall(Tr, T), A, getReturnType(T), list(bindParams(getParams(T), A, DArgs)))

     syntax Val ::= valWithType(CPPType)
     rule valWithType(T::CPPType) => lv(_, _, T) #Or le(_, _, T) #Or xv(_, _, T) #Or xe(_, _, T) #Or prv(_, _, T) #Or pre(_, _, T) [macro, unboundVariables(_)]

     rule CallExpr(valWithType(t(... st: pointerType(t(... st: functionType(...)) #as T::CPPType))) #as V:Val, list(A::List), krlist(DArgs::List))
          => elabCall(V, false, A, getReturnType(T), list(bindParams(getParams(T), A, DArgs)))

     syntax KItem ::= elabCall(Val, Bool, List, CPPType, StrictList) [strict(5)]

     rule elabCall(Fun::Val, IsVirtualCall::Bool, Args::List, T::CPPType, krlist(Temps::List))
          => makeCall(BuiltinCallOp(Fun, IsVirtualCall, Temps), combine(trace(Fun), hasTrace(list(Args)), CallExpr(Fun, list(Args))), T)

     syntax TExpr ::= makeCall(Expr, Trace, CPPType) [function]

     rule makeCall(E::Expr, Tr::Trace, T::CPPType) => le(E, Tr, T)
          requires isUnnamedLValue(T)

     rule makeCall(E::Expr, Tr::Trace, T::CPPType) => xe(E, Tr, T)
          requires isUnnamedXValue(T)

     rule makeCall(E::Expr, Tr::Trace, T::CPPType) => pre(E, Tr, T) [owise]

     syntax List ::= bindParams(List, List, List) [function]

     rule bindParams(ListItem(T:CPPType) P::List, ListItem(Init::Init) A::List, ListItem(_) DArgs::List)
          => ListItem(createTemporary(temp(!I:Int, T), T, figureInit(le(temp(!I:Int, T), noTrace, T), T, Init, CopyInit(), AutoStorage))) bindParams(P, A, DArgs)

     // ignore implicit object parameter for static function member
     rule bindParams(ListItem(implicitObjectParameter(t(... st: no-type))) P::List,
                     ListItem(Obj::Expr) A::List, DArgs::List)
          => ListItem(Obj) bindParams(P, A, DArgs)

     // we use getAddress instead of & because technically speaking the this argument can be any value category
     rule bindParams(ListItem(implicitObjectParameter(cppRefType #as T::CPPType)) P::List, ListItem(Obj::Expr) A::List, DArgs::List)
          => ListItem(ParenthesizedCast(type(pointerType(innerType(T))), getAddress(Obj))) bindParams(P, A, DArgs)
          requires T =/=K type(no-type)

     rule bindParams(.List, .List, .List) => .List

     rule bindParams(ListItem(variadic), L::List, .List) => bindVariadic(L)

     rule bindParams(ListItem(_) P::List, .List, ListItem(Arg:KItem) A::List)
          => ListItem(Arg) bindParams(P, .List, A)
          requires Arg =/=K NoArg()

     syntax List ::= bindVariadic(List) [function]

     rule bindVariadic(ListItem(Obj::Expr) L::List) => ListItem(defaultArgPromote(Obj)) bindVariadic(L)

     rule bindVariadic(.List) => .List

     syntax Expr ::= defaultArgPromote(Expr)

     context defaultArgPromote(HOLE:Expr => reval(HOLE)) [result(PRVal)]

     rule defaultArgPromote(V:PRVal) => convertType(argPromoteType(type(V)), V)

     syntax CPPType ::= argPromoteType(CPPType) [function, klabel(argPromoteTypeCpp)]

     rule argPromoteType(t(... st: nullptr_t)) => type(pointerType(type(void)))

     rule argPromoteType(t(... st: float)) => type(double)

     rule argPromoteType(T::CPPType) => promote(promote(T)) [owise]

endmodule
