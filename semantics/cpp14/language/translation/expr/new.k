module CPP-EXPR-NEW
     imports COMPAT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-DECL-INITIALIZER-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule (.K => CallExpr(Name(GlobalNamespace(), operatornew[]), list(ListItem(BinaryOperator(operator*, pre(newSize(!I), noTrace, type(size_t)), prv(byteSizeofType(T), noTrace, type(size_t)))) P)) ~> !I:Int) ~> NewExpr(T:CPPType, _:PRVal, _, P::List)
          requires notBool isCPPClassType(T) andBool notBool isCPPArrayType(T)

     context NewExpr(_, (HOLE:Expr => reval(HOLE)), _, _) [result(PRVal)]

     rule (.K => CallExpr(Name(GlobalNamespace(), operatornew), list(ListItem(prv(byteSizeofType(T), noTrace, type(size_t))) P))) ~> NewExpr(T:CPPType, NoExpression(), _, P::List)

     rule R:PRExpr ~> I:Int ~> NewExpr(T:CPPType, Size:PRExpr, Init::Init, P::List)
          => computeNewInit(R, T, Size, P, I, figureInit(le(Name(NoNNS(), #NoName(I)), noTrace, t(noQuals, .Set, dynamicArrayType(T, newSize(I)))), t(noQuals, .Set, dynamicArrayType(T, newSize(I))), DynamicStorage, Init))
     rule R:PRExpr ~> I:Int ~> NewExpr(T:CPPType, prv(Size:Int, Tr::Trace, SizeT::CPPType), Init::Init, P::List)
          => computeNewInit(R, T, prv(Size, Tr, SizeT), P, I, figureInit(le(Name(NoNNS(), #NoName(I)), noTrace, t(noQuals, .Set, arrayType(T, Size))), t(noQuals, .Set, arrayType(T, Size)), DynamicStorage, Init))
     rule R:PRExpr ~> NewExpr(T:CPPType, NoExpression(), Init::Init, P::List)
          => computeNewInit(R, T, NoExpression(), P, !I, figureInit(le(Name(NoNNS(), #NoName(!I:Int)), noTrace, T), T, DynamicStorage, Init))

     syntax Expr ::= computeNewInit(Expr, CPPType, AExpr, List, Int, K) [strict(6)]

     rule computeNewInit(R::Expr, T::CPPType, Size:Expr, P::List, I::Int, Init:KResult)
          => pre(NewOp(T, R, Init, Size, I), hasTrace(NewExpr(T, Size, NoInit(), P)), type(pointerType(T)))
          requires notBool isCPPClassType(T) andBool notBool isCPPArrayType(T)
     rule computeNewInit(R::Expr, T::CPPType, NoExpression(), P::List, I::Int, Init:KResult)
          => pre(NewOp(T, R, Init, .K, I), hasTrace(NewExpr(T, NoExpression(), NoInit(), P)), type(pointerType(T)))
          requires notBool isCPPClassType(T) andBool notBool isCPPArrayType(T)

     context DeleteExpr(_, _, (HOLE:Expr => reval(HOLE))) [result(PRVal)]
     rule (.K => CallExpr(Name(GlobalNamespace(), operatordelete), list(ListItem(le(Name(NoNNS(), #NoName(!I:Int)), noTrace, type(V))) ListItem(pre(newSize(!I), noTrace, type(size_t))))) ~> !I) ~> DeleteExpr(false, false, V:PRVal)
          requires isCPPPointerType(type(V)) andBool notBool isCPPClassType(innerType(type(V)))
     rule R:PRExpr ~> I:Int ~> DeleteExpr(false, false, V:PRVal) => pre(DeleteOp(V, R, .K, I), hasTrace(DeleteExpr(false, false, V)), type(void))

endmodule
