module C-PROMOTION
     imports C-COMMON-PROMOTION-SYNTAX
     imports BOOL
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYNTAX

     rule - (V:RValue => cast(promote(utype(V)), V))
          requires isIntegerType(type(V))
               andBool notBool isPromoted(utype(V))
     rule + (V:RValue => cast(promote(utype(V)), V))
          requires isIntegerType(type(V))
               andBool notBool isPromoted(utype(V))
     rule ~ (V:RValue => cast(promote(utype(V)), V))
          requires isIntegerType(type(V))
               andBool notBool isPromoted(utype(V))

     syntax KItem ::= arithBinOp(K, K)
     rule arithBinOp(L:K, R:K)
         => arithBinConversionOp(L, R)
        #Or (L << R)
        #Or (L >> R) [macro]

     rule arithBinOp(L:RValue, R:RValue) #as O:KItem
          => fillExpr(O, cast(promote(utype(L)), L), R)
          requires isIntegerType(type(L))
               andBool notBool isPromoted(utype(L))

     rule arithBinOp(L:RValue, R:RValue) #as O:KItem
          => fillExpr(O, L, cast(promote(utype(R)), R))
          requires isIntegerType(type(R))
               andBool notBool isPromoted(utype(R))
               andBool (notBool isIntegerType(type(L)) orBool isPromoted(utype(L)))

     syntax KItem ::= arithBinNonEqualityOp(K, K)
     rule arithBinNonEqualityOp(L:K, R:K)
         => ((L * R)
        #Or ((L / R)
        #Or ((L % R)
        #Or ((L + R)
        #Or ((L - R)
        #Or ((L < R)
        #Or ((L > R)
        #Or ((L <= R)
        #Or ((L >= R)
        #Or ((L & R)
        #Or ((L | R)
        #Or ((L ^ R)
        #Or ((L << R)
        #Or ((L >> R))))))))))))))) [macro]

     rule arithBinNonEqualityOp(tv(V::CValue, T::UType), R:RValue) #as O:KItem
          => fillExpr(O, tv(V, stripConstants(T)), R)
          requires fromConstantExpr(T) andBool notBool fromConstantExpr(R)
               andBool (notBool isIntegerUType(T) orBool isPromoted(T))
               andBool (notBool isIntegerUType(utype(R)) orBool isPromoted(utype(R)))
     rule arithBinNonEqualityOp(L:RValue, tv(V::CValue, T::UType)) #as O:KItem
          => fillExpr(O, L, tv(V, stripConstants(T)))
          requires fromConstantExpr(T) andBool notBool fromConstantExpr(L)
               andBool (notBool isIntegerUType(T) orBool isPromoted(T))
               andBool (notBool isIntegerUType(utype(L)) orBool isPromoted(utype(L)))

     rule arithBinNonEqualityOp(te(V:KItem, T::UType), R:RValue) #as O:KItem
          => fillExpr(O, te(V, stripConstants(T)), R)
          requires fromConstantExpr(T) andBool notBool fromConstantExpr(R)
               andBool (notBool isIntegerUType(T) orBool isPromoted(T))
               andBool (notBool isIntegerUType(utype(R)) orBool isPromoted(utype(R)))
     rule arithBinNonEqualityOp(L:RValue, te(V:KItem, T::UType)) #as O:KItem
          => fillExpr(O, L, te(V, stripConstants(T)))
          requires fromConstantExpr(T) andBool notBool fromConstantExpr(L)
               andBool (notBool isIntegerUType(T) orBool isPromoted(T))
               andBool (notBool isIntegerUType(utype(L)) orBool isPromoted(utype(L)))

     /*@ \fromStandard{\source[n1570]{\para{6.3.1.8}{1}}}{
     Many operators that expect operands of arithmetic type cause conversions
     and yield result types in a similar way. The purpose is to determine a
     common real type for the operands and result. For the specified operands,
     each operand is converted, without change of type domain, to a type whose
     corresponding real type is the common real type. Unless explicitly stated
     otherwise, the common real type is also the corresponding real type of the
     result, whose type domain is the type domain of the operands if they are
     the same, and complex otherwise. This pattern is called the usual
     arithmetic conversions:
     }*/

     syntax KItem ::= fillExpr(KItem, K, K) [function]
     rule fillExpr(_ * _, L:K, R:K) => L * R
     rule fillExpr(_ / _, L:K, R:K) => L / R
     rule fillExpr(_ % _, L:K, R:K) => L % R
     rule fillExpr(_ + _, L:K, R:K) => L + R
     rule fillExpr(_ - _, L:K, R:K) => L - R
     rule fillExpr(_ < _, L:K, R:K) => L < R
     rule fillExpr(_ > _, L:K, R:K) => L > R
     rule fillExpr(_ <= _, L:K, R:K) => L <= R
     rule fillExpr(_ >= _, L:K, R:K) => L >= R
     rule fillExpr(_ == _, L:K, R:K) => L == R
     rule fillExpr(_ != _, L:K, R:K) => L != R
     rule fillExpr(_ & _, L:K, R:K) => L & R
     rule fillExpr(_ | _, L:K, R:K) => L | R
     rule fillExpr(_ ^ _, L:K, R:K) => L ^ R
     rule fillExpr(_ >> _, L:K, R:K) => L >> R
     rule fillExpr(_ << _, L:K, R:K) => L << R

     syntax KItem ::= arithBinConversionOp(K, K)
     rule arithBinConversionOp(L:K, R:K) 
         => ((L * R)
        #Or ((L / R)
        #Or ((L % R)
        #Or ((L + R)
        #Or ((L - R)
        #Or ((L < R)
        #Or ((L > R)
        #Or ((L <= R)
        #Or ((L >= R)
        #Or ((L == R)
        #Or ((L != R)
        #Or ((L & R)
        #Or ((L | R)
        #Or ((L ^ R))))))))))))))) [macro]

     rule arithBinConversionOp(L:RValue, R:RValue) #as O:KItem
         => fillExpr(O, cast(usualArithmeticConversion(utype(L), utype(R)), L),
                        cast(usualArithmeticConversion(utype(L), utype(R)), R))
         requires isArithmeticType(type(L))
               andBool isArithmeticType(type(R))
               andBool (notBool isIntegerUType(utype(L)) orBool isPromoted(utype(L)))
               andBool (notBool isIntegerUType(utype(R)) orBool isPromoted(utype(R)))
               andBool notBool (arithBinNonEqualityOp(_, _) :=K O andBool (fromConstantExpr(L) xorBool fromConstantExpr(R)))
               andBool (utype(L) =/=Type utype(R))

endmodule
