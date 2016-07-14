// information used by execution configuration and therefore
// included in all C and C++ modules
module CPP-DYNAMIC-CONFIG-SYNTAX
     syntax NormalizedNamespace ::= GlobalNamespace()
endmodule

module CPP-DYNAMIC-SYNTAX
     imports CPP-DYNAMIC-CONFIG-SYNTAX
     imports INT
     imports LIST
     imports SYMLOC-SYNTAX

     syntax CPPType // defined in CPP-TYPING-SYNTAX

     syntax CPPValue ::= SymLoc

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
 
     syntax UnnamedNamespace
     syntax Namespace ::= NormalizedNamespace | UnnamedNamespace | NoNamespace()
                        | Namespace "::" NamespaceSpecifier
     syntax NamespaceSpecifier

     syntax NamespaceScope ::= namespaceScope(Namespace)
     syntax BlockScope ::= blockScope(QualId, Int) [klabel(blockScopeCpp)]
     syntax Scope ::= NamespaceScope | BlockScope

     syntax LanguageLinkage ::= "CLinkage" | "CPPLinkage" | "DefaultLinkage" // equivalent to CPPLinkage except that objects with CPPLinkage are treated as having the extern modifier in certain respects

     syntax Linkage ::= "ExternalLinkage" | "InternalLinkage" | "NoLinkage"
     syntax Duration ::= "StaticStorage" | "ThreadStorage" | "AutoStorage" | "DynamicStorage"

     syntax QualId ::= NormalizedNamespace "::" CId

     syntax CId ::= "funLabel" "(" CId ")"

     syntax KItem ::= functionObject(CId, CPPType, List, K) [klabel(cppFunctionObject)]

     syntax KItem ::= "pushBlock" "(" Int ")"
                    | "popBlock"

     syntax KItem ::= gotoObject(Int, List, K, List, List) [klabel(gotoObjectCpp)]

     syntax KResult ::= CPPType | Val

     syntax Bool ::= isLKLabel(K) [function, klabelPredicate]

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

endmodule
