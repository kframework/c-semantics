module COMMON-SORTS
     imports BITS-SORTS
     imports SYMLOC-SORTS
     imports INT-SYNTAX
     imports FLOAT-SYNTAX
     syntax CValue ::= BitValueOrEncodable | Agg | IntPtr
     syntax BitValueOrEncodable ::= BitValue | Encodable
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

     syntax UnnamedCId ::= unnamed(Int, String) [symbol]  // Unnamed struct/union/enums.
     syntax NoName ::= "#NoName" [symbol] | #NoName(Int) [symbol]  // Unnamed struct/union fields.
     syntax CId ::= NoName
     syntax CId ::= Identifier(String) [symbol]
     syntax CId ::= UnnamedCId

     syntax CabsLoc ::= "UnknownCabsLoc"
     syntax CabsLoc ::= CabsLoc(rel: String, abs: String, line: Int, col: Int, systemHeader: Bool) [symbol]

     syntax Qualifier ::= Const() [symbol]
     syntax Qualifier ::= Volatile() [symbol]
     syntax Qualifier ::= Restrict() [symbol]
     syntax Qualifier ::= RestrictReserved(String, CabsLoc) [symbol]
     syntax Qualifier ::= Atomic() [symbol]

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
     syntax Bool ::= Quals ">Quals" Quals [function]

     syntax Namespace ::= GlobalNamespace()

     syntax Scope ::= "none" | FileScope
     syntax FileScope ::= "fileScope"

     syntax Status ::= "initializingTu" | "mainCalled" | "mainExited" | "terminated"
     syntax KItem ::= "cleanup" | "reportSuccess"

     syntax LanguageLinkage ::= "CLinkage" | "CPPLinkage"

     syntax Location ::= CodeLoc(K, CabsLoc)
     syntax Location ::= ExpLoc(K, CabsLoc)

     syntax FunctionSpecifier ::= Inline() [symbol]
     syntax NoInit ::= NoInit() [symbol]
     syntax Init ::= NoInit

     syntax AutoSpecifier ::= Auto() [symbol]
     syntax StorageClassSpecifier ::= Static() [symbol] | Extern() [symbol] | Register() [symbol] | ThreadLocal() [symbol]

endmodule
