module CPP-TRANSLATION-EXPR-NEW-SYNTAX
     imports BOOL-SYNTAX
     imports INT-SYNTAX
     imports MAP
     imports COMMON-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPE-MAP-SORTS
     imports CPP-TYPING-SORTS
     syntax KItem ::= lookupAllocationFunction(CId, CPPType, Bool)
     syntax List ::= getSecondDeleteArg(TypeMap, PRVal) [function]
endmodule

module CPP-TRANSLATION-EXPR-NEW
     imports CPP-TRANSLATION-EXPR-NEW-SYNTAX
     imports COMPAT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-BUILTIN-SYNTAX
     imports CPP-TRANSLATION-DECL-CLASS-SYNTAX
     imports CPP-TRANSLATION-DECL-INITIALIZER-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TRANSLATION-OVERLOADING-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TRANSLATION-NAME-SYNTAX
     imports CPP-TYPE-MAP-SYNTAX
     imports CPP-TYPING-SYNTAX

     context NewExpr(_, _, (HOLE:Expr => reval(HOLE)), _, _) [result(PRVal)]

     rule (.K => lookupAllocationFunction(operatornew, T, IsGlobal))
          ~> NewExpr(IsGlobal::Bool, T:CPPType, NoExpression(), _, _)
          requires notBool isCPPArrayType(T)

     rule (.K => lookupAllocationFunction(operatornew[], getMostDerivedArrayElement(T), IsGlobal))
          ~> NewExpr(IsGlobal::Bool, T:CPPType, _:PRVal, _, _)

     rule (.K => lookupAllocationFunction(operatornew[], getMostDerivedArrayElement(T), IsGlobal))
          ~> NewExpr(IsGlobal::Bool, T:CPPArrayType, _, _, _)

     rule lookupAllocationFunction(X::CId, T::CPPType, IsGlobal:Bool)
          => qualifiedNameLookup(X, GlobalNamespace(), defaultMask)
          requires IsGlobal orBool notBool isCPPClassType(T)

     rule lookupAllocationFunction(X::CId, t(... st: classType(C::Class)), false)
          => qualifiedNameLookup(X, C, defaultMask)
               orIfNotFound
             qualifiedNameLookup(X, GlobalNamespace(), defaultMask)

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
          => computeNewInit(
               R, T, Size, E, I,
               figureInit(
                 le(ExecName(NoNNS(), #NoName(I)), noTrace, t(noQuals, .Set, dynamicArrayType(T, newSize(I)))),
                 t(noQuals, .Set, dynamicArrayType(T, newSize(I))),
                 Init,
                 DirectInit()
               )
             )

     rule R:PRExpr ~> I:Int ~> NewExpr(_, T:CPPType, prv(Size:Int, Tr::Trace, SizeT::CPPType), Init::Init, _) #as E:Expr
          => computeNewInit(
               R, T, prv(Size, Tr, SizeT), E, I,
               figureInit(
                 le(ExecName(NoNNS(), #NoName(I)), noTrace, t(noQuals, .Set, arrayType(T, Size))),
                 t(noQuals, .Set, arrayType(T, Size)),
                 Init,
                 DirectInit()
               )
             )

     rule R:PRExpr ~> NewExpr(_, T:CPPType, NoExpression(), Init::Init, _) #as E:Expr
          => computeNewInit(
               R, T, NoExpression(), E, !I,
               figureInit(
                 le(ExecName(NoNNS(), #NoName(!I:Int)), noTrace, T),
                 T,
                 Init,
                 DirectInit()
               )
            )

     syntax Expr ::= computeNewInit(Expr, CPPType, AExpr, Expr, Int, K) [strict(6)]

     syntax K ::= ExprOrNothing(K) [function]
     rule ExprOrNothing(E:Expr) => E
     rule ExprOrNothing(_) => .K [owise]

     rule computeNewInit(R::Expr, T::CPPType, Size::K, E::Expr, I::Int, Init:KResult)
          => pre(NewOp(T, R, Init, ExprOrNothing(Size), I), hasTrace(E), type(pointerType(T)))

     rule getSecondDeleteArg(M::TypeMap, V::PRVal)
          => #getSecondDeleteArg(M, func(type(void), ptr(type(void))), func(type(void), ptr(type(void)), type(size_t)), V)

     syntax List ::= #getSecondDeleteArg(TypeMap, CPPType, CPPType, PRVal) [function]
     rule #getSecondDeleteArg((T1 |-> _) (T2 |-> _) M::TypeMap, T1::CPPType, T2::CPPType, V::PRVal) => ListItem(V)
     rule #getSecondDeleteArg(...) => .List [owise]

     context DeleteExpr(_, _, (HOLE:Expr => reval(HOLE))) [result(PRVal)]

     rule (.K => lookupAllocationFunction(operatordelete, innerType(type(V)), IsGlobal))
          ~> DeleteExpr(IsGlobal::Bool, false, V:PRVal)
          requires isCPPPointerType(type(V)) andBool #fun(InnerT::CPPType => notBool isCPPClassType(InnerT) orBool notBool hasDestructorThat({InnerT}:>CPPClassType, #klabel(`isVirtualDestructor`)))(innerType(type(V)))

     rule (
            cSet(Cands::TypeMap, Q::QualId) #as C:CandidateSet
            => resolveOverload(
                 C,
                 list(
                   ListItem(le(ExecName(NoNNS(), #NoName(!I:Int)), noTrace, type(V)))
                   getSecondDeleteArg(Cands, pre(newSize(!I), noTrace, type(size_t)))
                 ),
                 Name(NoNNS(), operatordelete)
               )
            ~> !I:Int
          )
          ~> DeleteExpr(_, false, V::PRVal)

     rule R:PRExpr ~> I:Int ~> DeleteExpr(IsGlobal::Bool, false, V:PRVal)
          => pre(DeleteOp(V, R, .K, I), hasTrace(DeleteExpr(IsGlobal, false, V)), type(void))

endmodule
