module COMMON-SYNTAX
     imports STRING
     imports INT
     imports SET
     imports BOOL

     syntax CId ::= Identifier(String)
     syntax CId ::= "#NoName"
     syntax CId ::= #NoName(Int)
     syntax CId ::= unnamed(Int, String)

     syntax CabsLoc ::= "UnknownCabsLoc"
     syntax CabsLoc ::= CabsLoc(String, Int, Int, Int, Bool)

     syntax Qualifier ::= Const()
     syntax Qualifier ::= Volatile()
     syntax Qualifier ::= Restrict()

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
     syntax QualId ::= Namespace "::" CId

     syntax Scope ::= "none"

     syntax Status ::= "initializing" | "mainCalled" | "mainExited" | "terminated"

     syntax CValue ::= NumValue
     syntax NumValue ::= Int

     syntax LanguageLinkage ::= "CLinkage" | "CPPLinkage"

     syntax KItem ::= allowInit(K)

     syntax EffectiveValue ::= Int

endmodule
