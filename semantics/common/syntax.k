module COMMON-SORTS
     imports BITS-SORTS
     imports SYMLOC-SORTS
     imports INT-SYNTAX
     imports FLOAT-SYNTAX
     syntax CValue ::= BitValue | Agg | Encodable | IntPtr
     syntax EffectiveValue ::= Int | Float | CValue
     syntax Agg
     syntax CId
     syntax CabsLoc
     syntax Qualifier
     syntax Quals
     syntax EvalContext
     syntax LanguageLinkage
     syntax AutoSpecifier
     syntax Namespace
     syntax Scope
endmodule

module COMMON-SYNTAX
     imports COMMON-SORTS
     imports SET
     imports STRING-SYNTAX

     syntax UnnamedCId ::= unnamed(Int, String)  // Unnamed struct/union/enums.
     syntax NoName ::= "#NoName" | #NoName(Int)  // Unnamed struct/union fields.
     syntax CId ::= NoName
     syntax CId ::= Identifier(String)
     syntax CId ::= UnnamedCId

     syntax CabsLoc ::= "UnknownCabsLoc"
     syntax CabsLoc ::= CabsLoc(rel: String, abs: String, line: Int, col: Int, systemHeader: Bool)

     syntax Qualifier ::= Const()
     syntax Qualifier ::= Volatile()
     syntax Qualifier ::= Restrict()
     syntax Qualifier ::= RestrictReserved(String, CabsLoc)
     syntax Qualifier ::= Atomic()

     syntax EvalContext ::= "eval" | "noEval"

     // Const, Restrict, Volatile, Atomic
     syntax Quals ::= quals(Set)

     syntax Quals ::= "noQuals" [function]
     syntax Bool ::= Qualifier "inQuals" Quals [function]
     syntax Quals ::= toQuals(Set) [function]
     syntax Quals ::= Quals "+Quals" Quals [function]
     syntax Quals ::= Quals "+Qual" Qualifier [function]
     syntax Quals ::= Quals "-Qual" Qualifier [function]
     syntax Bool ::= Quals "<=Quals" Quals [function]

     syntax Namespace ::= GlobalNamespace()

     syntax Scope ::= "none" | FileScope
     syntax FileScope ::= "fileScope"

     syntax Status ::= "initializingTu" | "mainCalled" | "mainExited" | "terminated"
     syntax KItem ::= "cleanup" | "reportSuccess"

     syntax LanguageLinkage ::= "CLinkage" | "CPPLinkage"

     syntax KItem ::= CodeLoc(K, CabsLoc)

     syntax FunctionSpecifier ::= Inline()
     syntax Init ::= NoInit()

     syntax AutoSpecifier ::= Auto()
     syntax StorageClassSpecifier ::= Static() | Extern() | Register() | ThreadLocal()

endmodule
