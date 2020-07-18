module C-EXPR-CONDITIONAL
     imports BASIC-K
     imports BOOL
     imports INT
     imports K-EQUAL
     imports BITS-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-EXPR-LOGICAL-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-TYPING-EXPR-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.5.15}{4}}}{
     The first operand is evaluated; there is a sequence point between its
     evaluation and the evaluation of the second or third operand (whichever is
     evaluated). The second operand is evaluated only if the first compares
     unequal to 0; the third operand is evaluated only if the first compares
     equal to 0; the result is the value of the second or third operand
     (whichever is evaluated), converted to the type described below.
     }*/

     rule E:K ? E1:K : E2:K
          => evalConditional(simplifyTruth(E), E1, E2)

     syntax Bool ::= isShortCircuit(RValue)  [function, functional]
     rule isShortCircuit(tv(1, ut(_, int))) => true
     rule isShortCircuit(tv(0, ut(_, int))) => true
     rule isShortCircuit(_) => false  [owise]

     syntax KItem ::= evalConditional(K, K, K)
     context evalConditional(HOLE:KItem => reval(HOLE), _, _) [result(RValue)]
     context evalConditional(tv(1, ut(_, int)), HOLE:KItem => reval(HOLE), _) [result(RValue)]
     context evalConditional(tv(0, ut(_, int)), _, HOLE:KItem => reval(HOLE)) [result(RValue)]
     context evalConditional(C:RValue, HOLE:KItem => reval(HOLE), _)
         requires notBool isShortCircuit(C)
         [result(RValue)]
     context evalConditional(C:RValue, _, HOLE:KItem => reval(HOLE))
         requires notBool isShortCircuit(C)
         [result(RValue)]

     rule (.K => typeof(C ? E1 : E2)) ~> evalConditional(tv(1, ut(_, int)) #as C, E1:RValue, E2)
     rule (.K => typeof(C ? E1 : E2)) ~> evalConditional(tv(0, ut(_, int)) #as C, E1, E2:RValue)
     rule (.K => typeof(C ? E1 : E2)) ~> evalConditional(C::RValue, E1:RValue, E2:RValue) [owise]

     rule typeof(T:Type) ~> evalConditional(E:K, E1:K, E2:K)
          => evalConditional(E, Cast(T, E1), Cast(T, E2), utype(T))
          requires notBool isVariablyModifiedType(T)
     rule typeof(T:Type) ~> evalConditional(E:K, E1:K, E2:K)
          => evalConditional(E, E1, E2, utype(T))
          requires isVariablyModifiedType(T)

     syntax KItem ::= evalConditional(K, K, K, UType) [klabel(evalConditional4)]
     context evalConditional(HOLE:KItem => reval(HOLE), _, _, _) [result(RValue)]
     context evalConditional(tv(1, ut(_, int)), HOLE:KItem => reval(HOLE), _, _) [result(RValue)]
     context evalConditional(tv(0, ut(_, int)), _, HOLE:KItem => reval(HOLE), _) [result(RValue)]
     context evalConditional(C:RValue, HOLE:KItem => reval(HOLE), _, _)
          requires notBool isShortCircuit(C)
          [result(RValue)]
     context evalConditional(C:RValue, _, HOLE:KItem => reval(HOLE), _)
          requires notBool isShortCircuit(C)
          [result(RValue)]

     rule evalConditional(C:RValue, E1:RValue, E2:RValue, T::UType)
          => te(stripHold(C) ? te(stripHold(E1), utype(E1)) : te(stripHold(E2), utype(E2)), stripConstants(T))
          requires isHold(C) orBool isVariablyModifiedType(type(T))
     rule evalConditional(tv(1, ut(_, int)), E1:RValue, _, T::UType) => E1
          requires notBool isVariablyModifiedType(type(T))
     rule evalConditional(tv(0, ut(_, int)), _, E2:RValue, T::UType) => E2
          requires notBool isVariablyModifiedType(type(T))
     rule evalConditional(tv((unknown(I:Int) => #if I ==Int 0 #then 0 #else 1 #fi), ut(_, int)), _, _, T::UType)
          requires notBool isVariablyModifiedType(type(T))

endmodule
