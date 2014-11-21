module C-ABSTRACT-SYNTAX
     imports C-SYNTAX
     syntax KItem ::= "AnonymousName" // new, argument is type
     rule AnonymousName => #NoName [macro, structural]

     syntax C ::= Definition
     syntax Definition ::= DefinitionLoc(K, K)
     syntax Definition ::= DefinitionLocRange(K, K, K)
     // this wraps all statements with their location in the original file
     syntax Statement ::= StatementLoc(K, K) // new

     rule DefinitionLoc(K:K, L:K) => CodeLoc(K:K, L:K) [macro, structural]
     rule StatementLoc(K:K, L:K) => CodeLoc(K:K, L:K) [macro, structural]
     rule DefinitionLocRange(K:K, _, L:K) => CodeLoc(K:K, L:K) [macro, structural]

     syntax Expression ::= Conditional(K, K, K)
     rule Conditional(K1:K, K2:K, K3:K) => K1:K ? K2:K : K3:K [macro, structural]

     syntax Expression ::= ArrayIndex(K, K)
     rule ArrayIndex(K1:K, K2:K) => K1:K[K2:K] [macro, structural]

     syntax Expression ::= Negative(K)
     rule Negative(K:K) => - K:K [macro, structural]
     syntax Expression ::= Positive(K)
     rule Positive(K:K) => + K:K [macro, structural]
     syntax Expression ::= LogicalNot(K)
     rule LogicalNot(K:K) => ! K:K [macro, structural]
     syntax Expression ::= BitwiseNot(K)
     rule BitwiseNot(K:K) => ~ K:K [macro, structural]
     syntax Expression ::= Dereference(K)
     rule Dereference(K:K) => * K:K [macro, structural]
     syntax Expression ::= Reference(K)
     rule Reference(K:K) => & K:K [macro, structural]
     syntax Expression ::= PreIncrement(K)
     rule PreIncrement(K:K) => ++ K:K [macro, structural]
     syntax Expression ::= PreDecrement(K)
     rule PreDecrement(K:K) => -- K:K [macro, structural]
     syntax Expression ::= PostIncrement(K)
     rule PostIncrement(K:K) => K:K ++ [macro, structural]
     syntax Expression ::= PostDecrement(K)
     rule PostDecrement(K:K) => K:K -- [macro, structural]

     syntax Expression ::= Multiply(K, K)
     rule Multiply(K1:K, K2:K) => K1:K * K2:K [macro, structural]
     syntax Expression ::= Divide(K, K)
     rule Divide(K1:K, K2:K) => K1:K / K2:K [macro, structural]
     syntax Expression ::= Modulo(K, K)
     rule Modulo(K1:K, K2:K) => K1:K % K2:K [macro, structural]
     syntax Expression ::= Plus(K, K)
     rule Plus(K1:K, K2:K) => K1:K + K2:K [macro, structural]
     syntax Expression ::= Minus(K, K)
     rule Minus(K1:K, K2:K) => K1:K - K2:K [macro, structural]
     syntax Expression ::= LeftShift(K, K)
     rule LeftShift(K1:K, K2:K) => K1:K << K2:K [macro, structural]
     syntax Expression ::= RightShift(K, K)
     rule RightShift(K1:K, K2:K) => K1:K >> K2:K [macro, structural]
     syntax Expression ::= LessThan(K, K)
     rule LessThan(K1:K, K2:K) => K1:K < K2:K [macro, structural]
     syntax Expression ::= LessThanOrEqual(K, K)
     rule LessThanOrEqual(K1:K, K2:K) => K1:K <= K2:K [macro, structural]
     syntax Expression ::= GreaterThan(K, K)
     rule GreaterThan(K1:K, K2:K) => K1:K > K2:K [macro, structural]
     syntax Expression ::= GreaterThanOrEqual(K, K)
     rule GreaterThanOrEqual(K1:K, K2:K) => K1:K >= K2:K [macro, structural]
     syntax Expression ::= Equality(K, K)
     rule Equality(K1:K, K2:K) => K1:K == K2:K [macro, structural]
     syntax Expression ::= NotEquality(K, K)
     rule NotEquality(K1:K, K2:K) => K1:K != K2:K [macro, structural]
     syntax Expression ::= BitwiseAnd(K, K)
     rule BitwiseAnd(K1:K, K2:K) => K1:K & K2:K [macro, structural]
     syntax Expression ::= BitwiseXor(K, K)
     rule BitwiseXor(K1:K, K2:K) => K1:K ^ K2:K [macro, structural]
     syntax Expression ::= BitwiseOr(K, K)
     rule BitwiseOr(K1:K, K2:K) => K1:K | K2:K [macro, structural]
     syntax Expression ::= LogicalAnd(K, K)
     rule LogicalAnd(K1:K, K2:K) => K1:K && K2:K [macro, structural]
     syntax Expression ::= LogicalOr(K, K)
     rule LogicalOr(K1:K, K2:K) => K1:K || K2:K [macro, structural]

     syntax Expression ::= Assign(K, K)
     rule Assign(K1:K, K2:K) => K1:K := K2:K [macro, structural]
     syntax Expression ::= AssignMultiply(K, K)
     rule AssignMultiply(K1:K, K2:K) => K1:K *= K2:K [macro, structural]
     syntax Expression ::= AssignDivide(K, K)
     rule AssignDivide(K1:K, K2:K) => K1:K /= K2:K [macro, structural]
     syntax Expression ::= AssignModulo(K, K)
     rule AssignModulo(K1:K, K2:K) => K1:K %= K2:K [macro, structural]
     syntax Expression ::= AssignPlus(K, K)
     rule AssignPlus(K1:K, K2:K) => K1:K += K2:K [macro, structural]
     syntax Expression ::= AssignMinus(K, K)
     rule AssignMinus(K1:K, K2:K) => K1:K -= K2:K [macro, structural]
     syntax Expression ::= AssignBitwiseAnd(K, K)
     rule AssignBitwiseAnd(K1:K, K2:K) => K1:K &= K2:K [macro, structural]
     syntax Expression ::= AssignBitwiseXor(K, K)
     rule AssignBitwiseXor(K1:K, K2:K) => K1:K ^= K2:K [macro, structural]
     syntax Expression ::= AssignBitwiseOr(K, K)
     rule AssignBitwiseOr(K1:K, K2:K) => K1:K |= K2:K [macro, structural]
     syntax Expression ::= AssignLeftShift(K, K)
     rule AssignLeftShift(K1:K, K2:K) => K1:K <<= K2:K [macro, structural]
     syntax Expression ::= AssignRightShift(K, K)
     rule AssignRightShift(K1:K, K2:K) => K1:K >>= K2:K [macro, structural]

     syntax Expression ::= Dot(K, CId)
     rule Dot(K:K, X:CId) => K:K . X:CId [macro, structural]
     syntax Expression ::= Arrow(K, CId)
     rule Arrow(K:K, X:CId) => K:K -> X:CId [macro, structural]

     /*@ This macro defines an important identity from
     \source[n1570]{\para{6.5.3.2}{3}}. As a syntactic macro, it should run
     on programs before they even start to reduce. */
     rule &(*(K:K)) => K:K [macro, structural]

endmodule

