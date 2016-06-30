module COMMON-SYNTAX
     imports STRING
     imports INT
     imports C-TYPING-SYNTAX

     syntax CId ::= Identifier(String)
     syntax CId ::= "#NoName"
     syntax CId ::= #NoName(Int)

     syntax CabsLoc ::= "UnknownCabsLoc"
     syntax CabsLoc ::= CabsLoc(String, Int, Int, Int, Bool)

     syntax Qualifier ::= Const()
     syntax Qualifier ::= Volatile()
     syntax Qualifier ::= Restrict()

     syntax EvalContext ::= "eval" | "noEval"


     // Function id, def return type, def params, local declarations, body.
     syntax RValue ::= functionObject(CId, Type, List, K)
endmodule
