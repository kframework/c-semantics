module CPP-TRANSLATION-TEMPLATE-DEDUCTION-SYNTAX
     imports LIST
     imports CPP-TRANSLATION-DECL-TEMPLATE-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-SORTS
     imports CPP-TYPING-SORTS

     syntax KItem ::= deduceTemplateFromCall(CPPTypeExpr, List, List, QualId)
                    | deduceTemplateFromDecl(Expr, AType) [strict]
                    | deduceAuto(CPPTypeExpr, Init)
                    | "finishAutoDeduction"
endmodule

module CPP-TRANSLATION-TEMPLATE-DEDUCTION
     imports CPP-TRANSLATION-TEMPLATE-DEDUCTION-SYNTAX
     imports C-CONFIGURATION
     imports K-REFLECTION
     imports COMMON-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-TRANSLATION-DECL-DECLARATOR-SYNTAX
     imports CPP-TRANSLATION-DECL-TEMPLATE-SYNTAX
     imports CPP-TRANSLATION-OVERLOADING-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPE-MAP-SYNTAX
     imports CPP-TRANSLATION-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-TRANSLATION-VALUE-CATEGORY-SYNTAX

     syntax DeductionContext ::= "FunctionCall" | "FunctionDecl"

     syntax KItem ::= getTypesForDeduction(CPPTypeExpr, K, K)
                    | #getTypesForDeduction(CPPTypeExpr, CPPType, CPPTypeExpr, ValueCategory) [function]
                    | deducePair(CPPTypeExpr, CPPType, Bool, DeductionContext) //P, A, P is reference type in function call context, context
                    | deducePairs(TemplateParams, TemplateArgs, Bool, DeductionContext)
                    | finishDeduction(TemplateInfo)

     rule (.K => getTypesForDeduction(Param, I, I)) ~> deduceTemplateFromCall(t(_, _, functionType(... paramTypes: (Param::CPPTypeExpr, Ps::CPPTypeExprs => Ps))), (ListItem(I::Init) => .List) _, _::List (.List => ListItem(Param)), _)

     context getTypesForDeduction(_, HOLE:TypeExpr => typeof(HOLE), _) [result(CPPType)]

     context getTypesForDeduction(_, _, HOLE:CatExpr => catof(HOLE)) [result(ValueCategory)]

     rule getTypesForDeduction(P::CPPType, A:CPPType, Cat:ValueCategory) => #getTypesForDeduction(P, A, P, Cat)

     rule #getTypesForDeduction(_, (t(Q::Quals, Mods::Set, T:CPPSimpleArrayType) => t(noQuals, Mods, pointerType(innerType(t(Q, Mods, T))))), P::CPPType, _)
          requires notBool isCPPRefType(P)

     rule #getTypesForDeduction(_, (T:CPPFunctionType => t(noQuals, .Set, pointerType(T))), P::CPPType, _)
          requires notBool isCPPRefType(P)

     rule #getTypesForDeduction(_, (t(Q::Quals, Mods::Set, T::CPPSimpleType) => t(noQuals, Mods, T)), P::CPPType, _)
          requires notBool isCPPRefType(P) andBool notBool isCPPSimpleArrayType(T) andBool notBool isCPPSimpleFunctionType(T) andBool Q =/=K noQuals

     rule #getTypesForDeduction(t((Q::Quals => noQuals), Mods::Set, T::CPPSimpleType), _, _, _)
          requires Q =/=K noQuals

     rule #getTypesForDeduction(P:CPPRefTypeExpr => innerType(P), _, _, _)

     rule #getTypesForDeduction(_, (A::CPPType => t(noQuals, .Set, lvRefType(A))), P::CPPType, lvalue)
          requires isForwardingReference(P)

     rule #getTypesForDeduction(P::CPPType, A::CPPType, OriginalP::CPPType, _) => #if isCPPRefType(OriginalP) #then deducePair(P, A, true, FunctionCall) #else deducePair(P, A, false, FunctionCall) #fi [owise]

     syntax Bool ::= isForwardingReference(CPPTypeExpr) [function]

     rule isForwardingReference(t(_, _, rvRefType(t(quals(.Set), _, dependentType(...))))) => true

     rule isForwardingReference(_) => false [owise]

     rule deducePair((t(Q::Quals, _, pointerType(P::CPPTypeExpr)) => P), (t(Q::Quals, _, pointerType(A::CPPType)) => A), _, _)

     rule deducePair(t(Q::Quals, _, classType(N::Namespace :: Class(T::Tag, X::CId, P::TemplateParams))), t(Q::Quals, _, classType(N :: Class(T, X, A::TemplateArgs))), B::Bool, C::DeductionContext) => deducePairs(P, A, B, C)

     rule deducePair(t(Q::Quals, _, functionType(... returnType: P::CPPTypeExpr, paramTypes: Ps::CPPTypeExprs)), t(Q::Quals, _, functionType(... returnType: A::CPPType, paramTypes: As::CPPTypes)), B::Bool, C::DeductionContext) => deducePairs(toTemplateParams(toList(P, Ps)), toTemplateArgs(toList(A, As)), B, C)

     rule deducePair(P:CPPType, A::CPPType, _, _) => .K

     rule <k> deducePair(t(Q::Quals, _, dependentType(P::String, I::Int)), t(Q::Quals, Mods::Set, A::CPPSimpleType), _, _) => .K ...</k>
          <template-deduction>... .Map => dependentType(P, I) |-> t(Q, Mods, A) ...</template-deduction>

     rule <k> deducePair(t(Q::Quals, _, auto), t(Q::Quals, Mods::Set, A::CPPSimpleType), _, _) => .K ...</k>
          <template-deduction>... .Map => auto |-> t(Q, Mods, A) ...</template-deduction>

     rule (.K => deducePair(P, A, B, C)) ~> deducePairs((P:CPPTypeExpr, Ps::TemplateParams => Ps), (A:CPPType, As::TemplateArgs => As), B::Bool, C::DeductionContext)

     rule deducePairs(.TemplateParams, .TemplateArgs, _, _) => .K

     // TODO(traiansf): default Args for template functions
     rule <k> deduceTemplateFromCall(t(Q::Quals, Mods::Set, functionType(Ret::CPPType, .CPPTypes, MI::MethodInfo, L::LanguageLinkage, E::ExceptionSet)), _, Params::List, X::QualId) => finishDeduction(T) ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <templates>... X |-> (_::TypeMap t(Q, Mods, functionType(Ret, toCPPTypes(Params), MI, L, E)) |-> T:TemplateInfo) ...</templates>

     rule <k> finishDeduction(T::TemplateInfo) => instantiateTemplateType(T, Args) ...</k>
          <template-deduction> Args::Map </template-deduction>

     context deduceTemplateFromDecl(_, HOLE:CPPTypeExpr)
             requires notBool isDependentInScope(HOLE) [result(CPPType)]

     // no partial ordering required
     rule deduceTemplateFromDecl(cSet(... candidates: P::CPPTypeExpr |-> T::TemplateInfo), A:CPPType) => deducePair(P, A, false, FunctionDecl) ~> finishDeduction(T)

     rule deduceAuto(P::CPPTypeExpr, I::Init) => getTypesForDeduction(P, I, I) ~> finishAutoDeduction
          requires notBool isStmt(I) andBool isBraceInit(I)

     rule deduceAuto(t(_, _, functionType(... returnType: P::CPPTypeExpr)), S:Stmt) => locateReturns(P, ListItem(S)) ~> finishAutoDeduction

     syntax KItem ::= locateReturns(CPPTypeExpr, List)

     // TODO(dwightguth): replace this with a generic visitor of syntax
     rule locateReturns(_, (ListItem(BlockStmt(_, L::List)) => L) _)

     rule locateReturns(_, (ListItem(TLabelStmt(_, L::List)) => L) _)

     rule locateReturns(_, (ListItem(TGotoStmt(_)) => .List) _)

     rule locateReturns(_, (ListItem(TExpressionStmt(_)) => .List) _)

     rule locateReturns(_, (ListItem(IfTStmt(_::Expr, S1::Stmt, S2::Stmt)) => ListItem(S1) ListItem(S2)) _)

     rule locateReturns(_, (ListItem(DeclStmt(_)) => .List) _)

     rule locateReturns(_, (ListItem(TBreakStmt()) => .List) _)

     rule locateReturns(_, (ListItem(NullStmt()) => .List) _)

     rule (.K => getTypesForDeduction(P, I, I))
          ~> locateReturns(P::CPPTypeExpr, (ListItem(ReturnStmt(I::Init)) => .List) _)

     rule locateReturns(_, .List) => .K
endmodule
