module CPP-TRANSLATION-EXPR-NEW-SYNTAX
     imports BOOL-SYNTAX
     imports INT-SYNTAX
     imports MAP
     imports COMMON-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS
     syntax KItem ::= lookupAllocationFunction(CId, CPPType, Bool)

     syntax List ::= getSecondDeleteArg(Map, PRVal) [function]
endmodule

module CPP-TRANSLATION-EXPR-NEW
     imports CPP-TRANSLATION-EXPR-NEW-SYNTAX
     imports COMPAT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-BUILTIN-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TRANSLATION-DECL-CLASS-SYNTAX
     imports CPP-TRANSLATION-DECL-CLASS-DESTRUCTOR-SYNTAX
     imports CPP-TRANSLATION-DECL-INITIALIZER-SYNTAX
     imports CPP-TRANSLATION-OVERLOADING-SYNTAX
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
          ~> NewExpr(IsGlobal::Bool, t(... st: _:CPPSimpleArrayType) #as T::CPPType, _, _, _)

     rule lookupAllocationFunction(X::CId, T::CPPType, IsGlobal:Bool)
          => qualifiedNameLookup(X, GlobalNamespace(), defaultMask)
          requires IsGlobal orBool notBool isCPPClassType(T)

     rule lookupAllocationFunction(X::CId, t(... st: classType(C::Class)), false)
          => qualifiedNameLookup(X, C, defaultMask)
               orIfNotFound
             qualifiedNameLookup(X, GlobalNamespace(), defaultMask)

     rule (cSet(... id: Q::QualId) #as C:CandidateSet => resolveOverload(C, list(ListItem(pre(newSize(!I), noTrace, type(size_t)) * prv(byteSizeofType(T), noTrace, type(size_t))) P),
                                             Name(NoNNS(), operatornew[]))
          ~> stripResolveOverloadResult()
          ~> !I:Int)
          ~> NewExpr(_, T::CPPType, _, _, P::List)
          requires getId(Q) ==K operatornew[]

     rule (cSet(... id: Q::QualId) #as C:CandidateSet => resolveOverload(C, list(ListItem(prv(byteSizeofType(T), noTrace, type(size_t))) P),
                                                                          Name(NoNNS(), operatornew))
          ~> stripResolveOverloadResult())
          ~> NewExpr(_, T:CPPType, _, _, P::List)
          requires getId(Q) ==K operatornew

     rule R:PRExpr ~> I:Int ~> NewExpr(_, T:CPPType, Size:PRExpr, Init::Init, _) #as E:Expr
          => computeNewInit(
               R, T, Size, E, I,
               figureInit(
                 le(ExecName(NoNNS(), #NoName(I)), noTrace, t(noQuals, .Set, dynamicArrayType(T, newSize(I)))),
                 t(noQuals, .Set, dynamicArrayType(T, newSize(I))),
                 Init,
                 DirectInit(),
                 DynamicStorage
               )
             )

     rule R:PRExpr ~> I:Int ~> NewExpr(_, T:CPPType, prv(Size:Int, Tr::Trace, SizeT::CPPType), Init::Init, _) #as E:Expr
          => computeNewInit(
               R, T, prv(Size, Tr, SizeT), E, I,
               figureInit(
                 le(ExecName(NoNNS(), #NoName(I)), noTrace, t(noQuals, .Set, arrayType(T, Size))),
                 t(noQuals, .Set, arrayType(T, Size)),
                 Init,
                 DirectInit(),
                 DynamicStorage
               )
             )

     rule R:PRExpr ~> NewExpr(_, T:CPPType, NoExpression(), Init::Init, _) #as E:Expr
          => computeNewInit(
               R, T, NoExpression(), E, !I,
               figureInit(
                 le(ExecName(NoNNS(), #NoName(!I:Int)), noTrace, T),
                 T,
                 Init,
                 DirectInit(),
                 DynamicStorage
               )
            )

     syntax Expr ::= computeNewInit(Expr, CPPType, AExpr, Expr, Int, KItem) [strict(c; 6)]

     syntax K ::= ExprOrNothing(K) [function]

     rule ExprOrNothing(E:Expr) => E

     rule ExprOrNothing(_) => .K [owise]

     rule computeNewInit(R::Expr, T::CPPType, Size::AExpr, E::Expr, I::Int, Init:KResult)
          => New.potentiallyInvokeDestructor(T)
          ~> pre(NewOp(T, R, Init, ExprOrNothing(Size), I), hasTrace(E), type(pointerType(T)))


     // TODO(jan.tusil) test this with multidimensional arrays
     //
     // @ref n4296 5.3.4/19
     // @ref n4778 7.6.2.4/21
     // <quote>
     // If the new-expression creates an array of objects of class type,
     // the destructor is potentially invoked.
     // </quote>
     // <group>

     syntax KItem ::= "New.potentiallyInvokeDestructor" "(" CPPType ")"

     rule New.potentiallyInvokeDestructor(t(... st: _:CPPSimpleArrayType) #as T::CPPType)
          => #if isCPPClassType(innerType(T)) #then
               Class.potentiallyInvokeDestructor(classFromType(innerType(T)))
             #else
               .K
             #fi

     rule New.potentiallyInvokeDestructor(T::CPPType) => .K
          requires notBool isCPPArrayType(T)

     // </group>

     rule getSecondDeleteArg(M::Map, V::PRVal)
          => #getSecondDeleteArg(M, func(type(void), ptr(type(void))), func(type(void), ptr(type(void)), type(size_t)), V)

     syntax List ::= #getSecondDeleteArg(Map, CPPType, CPPType, PRVal) [function]

     rule #getSecondDeleteArg((stripType(T1) |-> _) (stripType(T2) |-> _) M::Map, T1::CPPType, T2::CPPType, V::PRVal) => ListItem(V)

     rule #getSecondDeleteArg(...) => .List [owise]

     context DeleteExpr(_, _, (HOLE:Expr => reval(HOLE))) [result(PRVal)]

     rule (.K => lookupAllocationFunction(operatordelete, innerType(type(V)), IsGlobal))
          ~> DeleteExpr(IsGlobal::Bool, false, V:PRVal)
          requires isCPPPointerType(type(V)) andBool #fun(InnerT::CPPType => notBool isCPPClassType(InnerT) orBool notBool hasDestructorThat(InnerT, isVirtualDestructor))(innerType(type(V)))

     rule (
            cSet(Cands::Map, Q::QualId) #as C:CandidateSet
            => resolveOverload(
                 C,
                 list(
                   ListItem(le(ExecName(NoNNS(), #NoName(!I:Int)), noTrace, type(V)))
                   getSecondDeleteArg(Cands, pre(newSize(!I), noTrace, type(size_t)))
                 ),
                 Name(NoNNS(), operatordelete)
               )
            ~> stripResolveOverloadResult()
            ~> !I:Int
          )
          ~> DeleteExpr(_, false, V::PRVal)

     rule R:PRExpr ~> I:Int ~> DeleteExpr(IsGlobal::Bool, false, V:PRVal)
          => pre(DeleteOp(V, R, .K, I), hasTrace(DeleteExpr(IsGlobal, false, V)), type(void))

endmodule
