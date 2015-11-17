module C-EXPR-CONDITIONAL
     imports C-EXPR-LOGICAL-SYNTAX

     imports C-COMMON-PROMOTION-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX
     imports COMPAT-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.5.15}{4}}}{
     The first operand is evaluated; there is a sequence point between its
     evaluation and the evaluation of the second or third operand (whichever is
     evaluated). The second operand is evaluated only if the first compares
     unequal to 0; the third operand is evaluated only if the first compares
     equal to 0; the result is the value of the second or third operand
     (whichever is evaluated), converted to the type described below.
     }*/
     rule (.K => typeof(E1 ? E2 : E3)) ~> E1:K ? E2:K : E3:K

     rule typeof(T:Type) ~> E:K ? E1:K : E2:K
          => evalConditional(simplifyTruth(E), Cast(T, E1), Cast(T, E2), T)
          requires notBool isVariablyModifiedType(T)
     rule typeof(T:Type) ~> E:K ? E1:K : E2:K
          => evalConditional(simplifyTruth(E), E1, E2, T)
          requires isVariablyModifiedType(T)

     syntax KItem ::= evalConditional(K, K, K, Type)
     context evalConditional(HOLE:KItem => reval(HOLE), _, _, _) [result(RValue)]
     context evalConditional(_, HOLE:KItem => reval(HOLE), _, _) [result(RValue)]
     context evalConditional(_, _, HOLE:KItem => reval(HOLE), _) [result(RValue)]

     rule evalConditional(C:RValue, E1:RValue, E2:RValue, T:Type)
          => te(stripHold(C) ? E1 : E2, stripConstants(T))
          requires isHold(C) orBool isVariablyModifiedType(T)
     rule evalConditional(tv(1, t(_, int)), E1:RValue, _, T:Type) => E1
          requires notBool isVariablyModifiedType(T)
     rule evalConditional(tv(0, t(_, int)), _, E2:RValue, T:Type) => E2
          requires notBool isVariablyModifiedType(T)

endmodule

