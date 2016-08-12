module CPP-DYNAMIC-SORTS
     syntax LVal
     syntax XVal
     syntax PRVal
     syntax GLVal ::= LVal | XVal
     syntax RVal ::= XVal | PRVal
     syntax Val ::= GLVal | RVal
     syntax Expr ::= Val
     syntax LExpr
     syntax XExpr
     syntax PRExpr
     syntax GLExpr ::= LExpr | XExpr
     syntax RExpr ::= XExpr | PRExpr
     syntax TExpr ::= GLExpr | RExpr
     syntax Expr ::= TExpr
     syntax NNS ::= Namespace | Class | ClassTemplate | NNSSpecifier
     syntax Namespace
     syntax Class
     syntax ClassTemplate
     syntax NNSSpecifier
     syntax DeclarationType
     syntax Linkage
     syntax Duration
     syntax QualId
     syntax Scope
     syntax Trace
     syntax Typed ::= Val | TExpr
     syntax TemplateArgs ::= List{TemplateArg, ","}
     syntax TemplateParams ::= List{TemplateParam, ","}
     syntax TemplateParams ::= TemplateArgs
     syntax TemplateParam ::= TemplateArg
     syntax TemplateArg
endmodule

module CPP-REVAL-SYNTAX
     imports CPP-SORTS
     syntax Expr ::= reval(Expr) [strict, klabel(revalCpp)]
endmodule

module CPP-DYNAMIC-SYNTAX
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS
     imports CPP-REVAL-SYNTAX
     imports INT
     imports LIST
     imports BITS-SYNTAX
     imports SYMLOC-SYNTAX
     imports CPP-DEPENDENT-SYNTAX

     syntax CPPValue ::= SymLoc
                       | Bits
                       | NullPtrVal // value of type std::nullptr_t
     syntax EffectiveValue ::= CPPValue
     syntax NullPtrVal ::= "nullptrVal"

     syntax CPPValue ::= "voidVal" // not technically a value, but it can be the result of an expression

     syntax LVal ::= lv(SymLoc, Trace, CPPTypeExpr) [klabel(lvcpp)]
     syntax XVal ::= xv(SymLoc, Trace, CPPTypeExpr)
     syntax PRVal ::= prv(CPPValue, Trace, CPPTypeExpr)

     syntax LExpr ::= le(Expr, Trace, CPPTypeExpr) [klabel(lecpp)]
     syntax XExpr ::= xe(Expr, Trace, CPPTypeExpr)
     syntax PRExpr ::= pre(Expr, Trace, CPPTypeExpr)

     syntax Expr ::= stripHold(Expr) [function, klabel(stripHoldCpp)]

     syntax Trace ::= hasTrace(K) | trace(Typed) [function] | "noTrace"
     syntax Trace ::= combine(Trace, K) [function]
     syntax Trace ::= combine(Trace, Trace, K) [function, klabel(combine2)]
 
     syntax FunctionDeclarationType ::= "Function" "(" List ")" 
     syntax VarDeclarationType ::= "Var"
     syntax DeclarationType ::= FunctionDeclarationType | VarDeclarationType
     syntax Decl ::= declareNonStaticObject(CId, CPPType, K, DeclarationType, Duration, Set) [strict(3)]
     syntax KItem ::= frozenDeclaration(Int, Int, Decl) [klabel(frozenDeclarationCpp)]
     syntax KResult ::= initValue(Expr, CPPType, K) [klabel(initValueCpp)]
 
     syntax UnnamedNamespace
     syntax NNS ::= NoNNS()
                  | NNS "::" NNSSpecifier [klabel(NestedName)]
     syntax NNSSpecifier ::= NNS(CId)
                           | TemplateNNS(CId)

     syntax Namespace ::= Namespace "::" NamespaceSpecifier
                        | NoNamespace() // signifies a declaration at block scope
                        | UnnamedNamespace
     syntax NamespaceSpecifier ::= Namespace(CId)

     syntax Class ::= Namespace "::" ClassSpecifier
     syntax ClassSpecifier ::= Class(Tag, CId, TemplateArgs) [klabel(classSpecifier)]
     syntax ClassTemplate ::= Namespace "::" ClassTemplateSpecifier
     syntax ClassTemplateSpecifier ::= Class(Tag, CId, TemplateParams) [klabel(classSpecifier)]
                                     | ClassSpecifier //not technically a class template, but this type exists primarily to support CPPClassTypeExpr, so it's needed

     syntax QualId ::= Class "::" CId

     syntax NamespaceScope ::= namespaceScope(Namespace)
     syntax ClassScope ::= classScope(Class)
     syntax BlockScope ::= blockScope(QualId, SymBase, Int) [klabel(blockScopeCpp)]
     syntax TemplateParameterScope ::= "templateParameterScope"
     syntax Scope ::= NamespaceScope | ClassScope | BlockScope | TemplateParameterScope

     syntax Linkage ::= "ExternalLinkage" | "InternalLinkage" | "NoLinkage"
     syntax Duration ::= "StaticStorage" | "ThreadStorage" | "AutoStorage" | "DynamicStorage"

     syntax CId ::= "funLabel" "(" CId ")"

     syntax KItem ::= functionObject(QualId, CPPType, List, K) [klabel(cppFunctionObject)]


     syntax TemplateInfo ::= "noTemplate"

     syntax KItem ::= "pushBlock" "(" Int ")"
                    | "popBlock"

     syntax KItem ::= gotoObject(Int, List, K, List, List) [klabel(gotoObjectCpp)]

     syntax NameRef ::= nsRef(Namespace) | notFound(CId)
                      | templateRef(QualId, CPPTypeExpr)
     syntax Val ::= NameRef
     syntax KResult ::= CPPTypeExpr | Val

     syntax Bool ::= isLKLabel(K) [function, klabelPredicate]

     syntax StrictList ::= prval(StrictList)

     syntax TemplateArgs ::= toTemplateArgs(List) [function]
     syntax TemplateParams ::= toTemplateParams(List) [function]
     syntax List ::= toList(CPPTypes) [function]
                   | toList(CPPTypeExprs) [function]
     syntax CPPTypes ::= toCPPTypes(List) [function]

     syntax TemplateParam ::= CPPTypeExpr
     syntax TemplateArg ::= CPPType

endmodule

module CPP-DYNAMIC
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SORTS

     rule isLKLabel(#klabel(`lvcpp`)) => true
     rule isLKLabel(#klabel(`lecpp`)) => true
     rule isLKLabel(_) => false [owise]

     rule stripHold(le(E::Expr, _, _)) => E
     rule stripHold(xe(E::Expr, _, _)) => E
     rule stripHold(pre(E::Expr, _, _)) => E
     rule stripHold(E::Expr) => E [owise]

     syntax SPRValList ::= toSPRValList(List) [function]
     syntax List ::= ofSPRValList(SPRValList) [function]
     syntax KItem ::= "prval()"
     rule prval(list(HOLE:List)) => toSPRValList(HOLE) ~> prval() [heat]
     rule HOLE:SPRValList ~> prval() => prval(krlist(ofSPRValList(HOLE))) [cool]

     syntax SPRValList ::= K "prval::" SPRValList
                     | ".SPRValList"
     rule isKResult(.SPRValList) => true
     rule isKResult(S1::SPRValList prval:: S2::SPRValList) => isKResult(S1) andBool isKResult(S2)
     rule toSPRValList(ListItem(K:K) L::List) => K prval:: toSPRValList(L)
     rule toSPRValList(.List) => .SPRValList
     rule ofSPRValList(krlist(L1::List) prval:: L2::SPRValList) => L1 ofSPRValList(L2)
     rule ofSPRValList(.SPRValList) => .List
     rule ofSPRValList(K:K prval:: L::SPRValList) => ListItem(K) ofSPRValList(L) [owise]

     context (HOLE:Expr => reval(HOLE)) prval:: _ [result(PRVal)]
     context K:KResult prval:: HOLE:SPRValList

     syntax STypeStrictList ::= toSTypeStrictList(List) [function]
     syntax List ::= ofSTypeStrictList(STypeStrictList) [function]
     syntax KItem ::= "typeStrict()"
     rule typeStrict(list(HOLE:List)) => toSTypeStrictList(HOLE) ~> typeStrict() [heat]
     rule HOLE:STypeStrictList ~> typeStrict() => typeStrict(krlist(ofSTypeStrictList(HOLE))) [cool]

     syntax STypeStrictList ::= K "typeStrict::" STypeStrictList
                     | ".STypeStrictList"
     rule isKResult(.STypeStrictList) => true
     rule isKResult(S1::STypeStrictList typeStrict:: S2::STypeStrictList) => isKResult(S1) andBool isKResult(S2)
     rule toSTypeStrictList(ListItem(K:K) L::List) => K typeStrict:: toSTypeStrictList(L)
     rule toSTypeStrictList(.List) => .STypeStrictList
     rule ofSTypeStrictList(krlist(L1::List) typeStrict:: L2::STypeStrictList) => L1 ofSTypeStrictList(L2)
     rule ofSTypeStrictList(.STypeStrictList) => .List
     rule ofSTypeStrictList(K:K typeStrict:: L::STypeStrictList) => ListItem(K) ofSTypeStrictList(L) [owise]

     context HOLE:AType typeStrict:: _ [result(CPPTypeExpr)]
     context HOLE:CPPTypeExpr typeStrict:: _
             requires notBool isDependentInScope(HOLE) [result(CPPType)]
     context K:KResult typeStrict:: HOLE:STypeStrictList


     rule trace(lv(_, Tr::Trace, _)) => Tr
     rule trace(xv(_, Tr::Trace, _)) => Tr
     rule trace(prv(_, Tr::Trace, _)) => Tr
     rule trace(le(_, Tr::Trace, _)) => Tr
     rule trace(xe(_, Tr::Trace, _)) => Tr
     rule trace(pre(_, Tr::Trace, _)) => Tr

     rule toTemplateArgs(ListItem(A::TemplateArg) L::List) => A, toTemplateArgs(L)
     rule toTemplateArgs(.List) => .TemplateArgs
     rule toCPPTypes(ListItem(A::CPPType) L::List) => A, toCPPTypes(L)
     rule toCPPTypes(.List) => .CPPTypes
     rule toTemplateParams(ListItem(P::TemplateParam) L::List) => P, toTemplateParams(L)
     rule toTemplateParams(.List) => .TemplateParams
     rule toList(T::CPPType, Ts::CPPTypes) => ListItem(T) toList(Ts)
     rule toList(.CPPTypes) => .List

endmodule
