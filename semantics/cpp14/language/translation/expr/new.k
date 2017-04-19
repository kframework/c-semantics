module CPP-EXPR-NEW-SYNTAX
     imports BOOL-SYNTAX
     imports INT-SYNTAX
     imports MAP
     imports COMMON-SORTS
     imports CPP-TYPING-SORTS
     syntax KItem ::= lookupAllocationFunction(CId, CPPType, Bool)
     syntax List ::= getSecondDeleteArg(Map, Int) [function]
endmodule

module CPP-EXPR-NEW
     imports CPP-EXPR-NEW-SYNTAX
     imports COMPAT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-BUILTIN-SYNTAX
     imports CPP-DECL-INITIALIZER-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-OVERLOADING-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TRANSLATION-NAME-SYNTAX
     imports CPP-TYPING-SYNTAX

     context NewExpr(_, _, (HOLE:Expr => reval(HOLE)), _, _) [result(PRVal)]

     rule (.K => lookupAllocationFunction(operatornew, T, IsGlobal)) ~> NewExpr(IsGlobal::Bool, T:CPPType, NoExpression(), _, _)
          requires notBool isCPPArrayType(T)
     rule (.K => lookupAllocationFunction(operatornew[], getMostDerivedArrayElement(T), IsGlobal)) ~> NewExpr(IsGlobal::Bool, T:CPPType, _:PRVal, _, _)
     rule (.K => lookupAllocationFunction(operatornew[], getMostDerivedArrayElement(T), IsGlobal)) ~> NewExpr(IsGlobal::Bool, T:CPPArrayType, _, _, _)

     rule lookupAllocationFunction(X::CId, T::CPPType, IsGlobal:Bool) => qualifiedNameLookup(X, GlobalNamespace(), defaultMask)
          requires IsGlobal orBool notBool isCPPClassType(T)
     rule lookupAllocationFunction(X::CId, t(... st: classType(C::Class)), false) => qualifiedNameLookup(X, C, defaultMask)
     // this operator is implicitly declared in every TU, so we should never
     // actually hit the infinite recursion case here
     rule (notFound(X::CId) => qualifiedNameLookup(X, GlobalNamespace(), defaultMask)) ~> NewExpr(...)

     rule (cSet(... id: Q::QualId) #as C:CandidateSet => resolveOverload(C, list(ListItem(pre(newSize(!I), noTrace, type(size_t)) * prv(byteSizeofType(T), noTrace, type(size_t))) P), 
                                             Name(NoNNS(), operatornew[]))
          ~> !I:Int)
          ~> NewExpr(_, T::CPPType, _, _, P::List)
          requires getId(Q) ==K operatornew[]

     rule (cSet(... id: Q::QualId) #as C:CandidateSet => resolveOverload(C, list(ListItem(prv(byteSizeofType(T), noTrace, type(size_t))) P), 
                                                                          Name(NoNNS(), operatornew)))
          ~> NewExpr(_, T:CPPType, _, _, P::List)
          requires getId(Q) ==K operatornew

     rule R:PRExpr ~> I:Int ~> NewExpr(_, T:CPPType, Size:PRExpr, Init::Init, _) #as E:Expr
          => computeNewInit(R, T, Size, E, I, figureInit(le(Name(NoNNS(), #NoName(I)), noTrace, t(noQuals, .Set, dynamicArrayType(T, newSize(I)))), t(noQuals, .Set, dynamicArrayType(T, newSize(I))), Init, DirectInit()))
     rule R:PRExpr ~> I:Int ~> NewExpr(_, T:CPPType, prv(Size:Int, Tr::Trace, SizeT::CPPType), Init::Init, _) #as E:Expr
          => computeNewInit(R, T, prv(Size, Tr, SizeT), E, I, figureInit(le(Name(NoNNS(), #NoName(I)), noTrace, t(noQuals, .Set, arrayType(T, Size))), t(noQuals, .Set, arrayType(T, Size)), Init, DirectInit()))
     rule R:PRExpr ~> NewExpr(_, T:CPPType, NoExpression(), Init::Init, _) #as E:Expr
          => computeNewInit(R, T, NoExpression(), E, !I, figureInit(le(Name(NoNNS(), #NoName(!I:Int)), noTrace, T), T, Init, DirectInit()))

     syntax Expr ::= computeNewInit(Expr, CPPType, AExpr, Expr, Int, K) [strict(6)]

     rule computeNewInit(R::Expr, T::CPPType, Size:Expr, E::Expr, I::Int, Init:KResult)
          => pre(NewOp(T, R, Init, Size, I), hasTrace(E), type(pointerType(T)))
     rule computeNewInit(R::Expr, T::CPPType, NoExpression(), E::Expr, I::Int, Init:KResult)
          => pre(NewOp(T, R, Init, .K, I), hasTrace(E), type(pointerType(T)))

     rule getSecondDeleteArg(M::Map, I::Int) => #getSecondDeleteArg(M, func(type(void), ptr(type(void))), func(type(void), ptr(type(void)), type(size_t)), I)
     syntax List ::= #getSecondDeleteArg(Map, CPPType, CPPType, Int) [function]
     rule #getSecondDeleteArg((T1 |-> _) (T2 |-> _) M::Map, T1::CPPType, T2::CPPType, I::Int) => ListItem(prv(I, noTrace, type(size_t)))
     rule #getSecondDeleteArg(...) => .List [owise]

     context DeleteExpr(_, _, (HOLE:Expr => reval(HOLE))) [result(PRVal)]
     rule (.K => CallExpr(Name(GlobalNamespace(), operatordelete), list(ListItem(le(Name(NoNNS(), #NoName(!I:Int)), noTrace, type(V))) ListItem(pre(newSize(!I), noTrace, type(size_t)))), krlist(.List)) ~> !I) ~> DeleteExpr(false, false, V:PRVal)
          requires isCPPPointerType(type(V)) andBool notBool isCPPClassType(innerType(type(V)))
     rule R:PRExpr ~> I:Int ~> DeleteExpr(false, false, V:PRVal) => pre(DeleteOp(V, R, .K, I), hasTrace(DeleteExpr(false, false, V)), type(void))

endmodule
