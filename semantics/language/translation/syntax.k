module C-ABSTRACT-SYNTAX
     imports C-SYNTAX
     syntax K ::= "AnonymousName" // new, argument is type
     rule AnonymousName => #NoName [macro, structural]
     
     syntax C ::= Definition
     syntax Definition ::= "DefinitionLoc" "(" K "," K ")"
          [klabel('DefinitionLoc)]
     syntax Definition ::= "DefinitionLocRange" "(" K "," K "," K ")"
          [klabel('DefinitionLocRange)]
     // this wraps all statements with their location in the original file
     syntax Statement ::= "StatementLoc" "(" K "," K ")"
          [klabel('StatementLoc)] // new

     rule DefinitionLoc(K:K, L:K) => CodeLoc(K:K, L:K) [macro, structural]
     rule StatementLoc(K:K, L:K) => CodeLoc(K:K, L:K) [macro, structural]
     rule DefinitionLocRange(K:K, _, L:K) => CodeLoc(K:K, L:K) [macro, structural]

     syntax Expression ::= Conditional(K, K, K)
          [klabel('Conditional)]
     rule Conditional(K1:K, K2:K, K3:K) => K1:K ? K2:K : K3:K [macro, structural]
     
     syntax Expression ::= ArrayIndex(K, K) [klabel('ArrayIndex)]
     rule ArrayIndex(K1:K, K2:K) => K1:K[K2:K] [macro, structural]
     
     syntax Expression ::= Negative(K) [klabel('Negative)]
     rule Negative(K:K) => - K:K [macro, structural]
     syntax Expression ::= Positive(K) [klabel('Positive)]
     rule Positive(K:K) => + K:K [macro, structural]
     syntax Expression ::= LogicalNot(K) [klabel('LogicalNot)]
     rule LogicalNot(K:K) => ! K:K [macro, structural]
     syntax Expression ::= BitwiseNot(K) [klabel('BitwiseNot)]
     rule BitwiseNot(K:K) => ~ K:K [macro, structural]
     syntax Expression ::= Dereference(K) [klabel('Dereference)]
     rule Dereference(K:K) => * K:K [macro, structural]
     syntax Expression ::= Reference(K) [klabel('Reference)]
     rule Reference(K:K) => & K:K [macro, structural]
     syntax Expression ::= PreIncrement(K) [klabel('PreIncrement)]
     rule PreIncrement(K:K) => ++ K:K [macro, structural]
     syntax Expression ::= PreDecrement(K) [klabel('PreDecrement)]
     rule PreDecrement(K:K) => -- K:K [macro, structural]
     syntax Expression ::= PostIncrement(K) [klabel('PostIncrement)]
     rule PostIncrement(K:K) => K:K ++ [macro, structural]
     syntax Expression ::= PostDecrement(K) [klabel('PostDecrement)]
     rule PostDecrement(K:K) => K:K -- [macro, structural]

     syntax Expression ::= Multiply(K, K) [klabel('Multiply)]
     rule Multiply(K1:K, K2:K) => K1:K * K2:K [macro, structural]
     syntax Expression ::= Divide(K, K) [klabel('Divide)]
     rule Divide(K1:K, K2:K) => K1:K / K2:K [macro, structural]
     syntax Expression ::= Modulo(K, K) [klabel('Modulo)]
     rule Modulo(K1:K, K2:K) => K1:K % K2:K [macro, structural]
     syntax Expression ::= Plus(K, K) [klabel('Plus)]
     rule Plus(K1:K, K2:K) => K1:K + K2:K [macro, structural]
     syntax Expression ::= Minus(K, K) [klabel('Minus)]
     rule Minus(K1:K, K2:K) => K1:K - K2:K [macro, structural]
     syntax Expression ::= LeftShift(K, K) [klabel('LeftShift)]
     rule LeftShift(K1:K, K2:K) => K1:K << K2:K [macro, structural]
     syntax Expression ::= RightShift(K, K) [klabel('RightShift)]
     rule RightShift(K1:K, K2:K) => K1:K >> K2:K [macro, structural]
     syntax Expression ::= LessThan(K, K) [klabel('LessThan)]
     rule LessThan(K1:K, K2:K) => K1:K < K2:K [macro, structural]
     syntax Expression ::= LessThanOrEqual(K, K) [klabel('LessThanOrEqual)]
     rule LessThanOrEqual(K1:K, K2:K) => K1:K <= K2:K [macro, structural]
     syntax Expression ::= GreaterThan(K, K) [klabel('GreaterThan)]
     rule GreaterThan(K1:K, K2:K) => K1:K > K2:K [macro, structural]
     syntax Expression ::= GreaterThanOrEqual(K, K) [klabel('GreaterThanOrEqual)]
     rule GreaterThanOrEqual(K1:K, K2:K) => K1:K >= K2:K [macro, structural]
     syntax Expression ::= Equality(K, K) [klabel('Equality)]
     rule Equality(K1:K, K2:K) => K1:K == K2:K [macro, structural]
     syntax Expression ::= NotEquality(K, K) [klabel('NotEquality)]
     rule NotEquality(K1:K, K2:K) => K1:K != K2:K [macro, structural]
     syntax Expression ::= BitwiseAnd(K, K) [klabel('BitwiseAnd)]
     rule BitwiseAnd(K1:K, K2:K) => K1:K & K2:K [macro, structural]
     syntax Expression ::= BitwiseXor(K, K) [klabel('BitwiseXor)]
     rule BitwiseXor(K1:K, K2:K) => K1:K ^ K2:K [macro, structural]
     syntax Expression ::= BitwiseOr(K, K) [klabel('BitwiseOr)]
     rule BitwiseOr(K1:K, K2:K) => K1:K | K2:K [macro, structural]
     syntax Expression ::= LogicalAnd(K, K) [klabel('LogicalAnd)]
     rule LogicalAnd(K1:K, K2:K) => K1:K && K2:K [macro, structural]
     syntax Expression ::= LogicalOr(K, K) [klabel('LogicalOr)]
     rule LogicalOr(K1:K, K2:K) => K1:K || K2:K [macro, structural]
     
     syntax Expression ::= "Assign" "(" K "," K ")" [klabel('Assign)]
     rule Assign(K1:K, K2:K) => K1:K := K2:K [macro, structural]
     syntax Expression ::= "AssignMultiply" "(" K "," K ")"
          [klabel('AssignMultiply)]
     rule AssignMultiply(K1:K, K2:K) => K1:K *= K2:K [macro, structural]
     syntax Expression ::= "AssignDivide" "(" K "," K ")"
          [klabel('AssignDivide)]
     rule AssignDivide(K1:K, K2:K) => K1:K /= K2:K [macro, structural]
     syntax Expression ::= "AssignModulo" "(" K "," K ")"
          [klabel('AssignModulo)]
     rule AssignModulo(K1:K, K2:K) => K1:K %= K2:K [macro, structural]
     syntax Expression ::= "AssignPlus" "(" K "," K ")"
          [klabel('AssignPlus)]
     rule AssignPlus(K1:K, K2:K) => K1:K += K2:K [macro, structural]
     syntax Expression ::= "AssignMinus" "(" K "," K ")"
          [klabel('AssignMinus)]
     rule AssignMinus(K1:K, K2:K) => K1:K -= K2:K [macro, structural]
     syntax Expression ::= "AssignBitwiseAnd" "(" K "," K ")"
          [klabel('AssignBitwiseAnd)]
     rule AssignBitwiseAnd(K1:K, K2:K) => K1:K &= K2:K [macro, structural]
     syntax Expression ::= "AssignBitwiseXor" "(" K "," K ")"
          [klabel('AssignBitwiseXor)]
     rule AssignBitwiseXor(K1:K, K2:K) => K1:K ^= K2:K [macro, structural]
     syntax Expression ::= "AssignBitwiseOr" "(" K "," K ")"
          [klabel('AssignBitwiseOr)]
     rule AssignBitwiseOr(K1:K, K2:K) => K1:K |= K2:K [macro, structural]
     syntax Expression ::= "AssignLeftShift" "(" K "," K ")"
          [klabel('AssignLeftShift)]
     rule AssignLeftShift(K1:K, K2:K) => K1:K <<= K2:K [macro, structural]
     syntax Expression ::= "AssignRightShift" "(" K "," K ")"
          [klabel('AssignRightShift)]
     rule AssignRightShift(K1:K, K2:K) => K1:K >>= K2:K [macro, structural]
     
     syntax Expression ::= Dot(K, Id) [klabel('Dot)]
     rule Dot(K:K, X:Id) => K:K . X:Id [macro, structural]
     syntax Expression ::= Arrow(K, Id) [klabel('Arrow)]
     rule Arrow(K:K, X:Id) => K:K -> X:Id [macro, structural]
     

     /*@ This macro defines an important identity from
     \source[n1570]{\para{6.5.3.2}{3}}. As a syntactic macro, it should run
     on programs before they even start to reduce. */
     rule &(*(K:K)) => K:K [macro, structural]

endmodule

