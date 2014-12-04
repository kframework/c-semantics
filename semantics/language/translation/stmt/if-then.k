module C-STMT-IF-THEN-SYNTAX
     imports C-DYNAMIC-SYNTAX

     syntax Bool ::= isTruthValue(TypedValue) [function]
endmodule

module C-STMT-IF-THEN
     imports C-STMT-IF-THEN-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX

     rule isTruthValue(tv(V:CValue, t(_, T:SimpleType)))
          => T ==K int andBool (V ==K 0 orBool V ==K 1 orBool V ==K symVal)

     rule IfThenElse((V:TypedValue => simplifyTruth(V)), _, _)
          requires notBool isTruthValue(V)
          [structural]

     // IfThenElse might also be handling the ternary operator (?:) and so
     // needing to return a value.
     rule IfThenElse(tv(0, t(_, int)), S1:K, S2:K)
          => S1 ~> discard ~> S2
          [structural]
     rule IfThenElse(tv(1, t(_, int)), S1:K, S2:K)
          => S2 ~> discard ~> S1
          [structural]

     // Things get a bit ugly in this case. We only want to return a value if
     // both branches also return a value (and therefore this is a ternary
     // expression).
     rule IfThenElse(tv(symVal, t(_, int)), S1:K, S2:K)
          => maybeSymVal(checkResultInK(S1), checkResultInK(S2))
          [structural]

     //add checkResultInK in order to aovid putting K Sequence in strict position
     syntax KItem ::= maybeSymVal(K, K) [strict]
                    | "checkResult"
                    | checkResultInK(K)

     syntax KResult ::= "noResult"

     rule checkResultInK(K:K) => K ~> checkResult
          [structural]

     rule R:KResult ~> checkResult => R
     rule checkResult => noResult

     rule maybeSymVal(noResult, noResult) => .K
     rule maybeSymVal(tv(_, T:Type), tv(_, T:Type)) => tv(symVal, T)
     rule maybeSymVal(voidVal, voidVal) => voidVal

endmodule

