module CPP-DYNAMIC-SYNTAX
     imports INT
     imports LIST
     imports BITS-SYNTAX
     imports SYMLOC-SYNTAX

     syntax CPPType // defined in CPP-TYPING-SYNTAX

     syntax CPPValue ::= SymLoc
                       | Bits
                       | NullPtrVal // value of type std::nullptr_t
     syntax EffectiveValue ::= CPPValue
     syntax NullPtrVal ::= "nullptrVal"

     syntax Val ::= "voidVal"

     syntax LVal ::= lv(SymLoc, CPPType) [klabel(lvcpp)]
     syntax XVal ::= xv(SymLoc, CPPType)
     syntax PRVal ::= prv(CPPValue, CPPType)
     syntax GLVal ::= LVal | XVal
     syntax RVal ::= XVal | PRVal
     syntax Val ::= GLVal | RVal
     syntax Expr ::= Val

     syntax Expr ::= reval(Expr) [strict, klabel(revalCpp)]

     syntax LExpr ::= le(Expr, CPPType) [klabel(lecpp)]
     syntax XExpr ::= xe(Expr, CPPType)
     syntax PRExpr ::= pre(Expr, CPPType)
     syntax GLExpr ::= LExpr | XExpr
     syntax RExpr ::= XExpr | PRExpr
     syntax TExpr ::= GLExpr | RExpr
     syntax Expr ::= TExpr

     syntax Expr ::= stripHold(Expr) [function, klabel(stripHoldCpp)]
 
     syntax DeclarationType ::= "Function" | "Var"
     syntax Decl ::= declareNonStaticObject(CId, CPPType, K, DeclarationType, Duration, Set) [strict(3)]
     syntax KItem ::= frozenDeclaration(Int, Int, Decl) [klabel(frozenDeclarationCpp)]
     syntax KResult ::= initValue(Expr, CPPType, K) [klabel(initValueCpp)]
 
     syntax UnnamedNamespace
     syntax NNS ::= Namespace | NoNNS() | NNSSpecifier
                  | NNS "::" NNSSpecifier [klabel(NestedName)]
     syntax Namespace ::= Namespace "::" NamespaceSpecifier
                        | NoNamespace() // signifies a declaration at block scope
                        | UnnamedNamespace
     syntax NamespaceSpecifier ::= Namespace(CId)
     syntax NNSSpecifier ::= NNS(CId)
                           | TemplateNNS(CId)

     syntax NamespaceScope ::= namespaceScope(Namespace)
     syntax BlockScope ::= blockScope(QualId, SymBase, Int) [klabel(blockScopeCpp)]
     syntax Scope ::= NamespaceScope | BlockScope

     syntax Linkage ::= "ExternalLinkage" | "InternalLinkage" | "NoLinkage"
     syntax Duration ::= "StaticStorage" | "ThreadStorage" | "AutoStorage" | "DynamicStorage"

     syntax CId ::= "funLabel" "(" CId ")"

     syntax KItem ::= functionObject(QualId, CPPType, List, K) [klabel(cppFunctionObject)]

     syntax KItem ::= "pushBlock" "(" Int ")"
                    | "popBlock"

     syntax KItem ::= gotoObject(Int, List, K, List, List) [klabel(gotoObjectCpp)]

     syntax NSRef ::= nsRef(Namespace) | notFound(CId)
     syntax Val ::= NSRef
     syntax KResult ::= CPPType | Val

     syntax Bool ::= isLKLabel(K) [function, klabelPredicate]

     syntax StrictList ::= prval(StrictList)

endmodule

module CPP-DYNAMIC
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX

     rule isLKLabel(#klabel(`lvcpp`)) => true
     rule isLKLabel(#klabel(`lecpp`)) => true
     rule isLKLabel(_) => false [owise]

     rule stripHold(le(E::Expr, _)) => E
     rule stripHold(xe(E::Expr, _)) => E
     rule stripHold(pre(E::Expr, _)) => E
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

endmodule
