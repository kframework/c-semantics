module CPP-EXPR-MULTIPLICATIVE
     imports BOOL
     imports FLOAT
     imports INT
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ERROR-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule prv(I1:Int, Tr1::Trace, T1::CPPType) * prv(I2:Int, Tr2::Trace, T2::CPPType)
          => arithInterpret(T1, I1 *Int I2, combine(Tr1, Tr2, #klabel(`_*__CPP-SYNTAX`)))
          requires isPromoted(T1)
               andBool T1 ==Type T2

     rule prv(F1:Float, Tr1::Trace, T1::CPPType) * prv(F2:Float, Tr2::Trace, T2::CPPType)
          => arithInterpret(T1, F1 *Float F2, combine(Tr1, Tr2, #klabel(`_*__CPP-SYNTAX`)))
          requires isPromoted(T1)
               andBool T1 ==Type T2

     rule prv(I1:Int, Tr1::Trace, T1::CPPType) / prv(I2:Int, Tr2::Trace, T2::CPPType)
          => arithInterpret(T1, I1 /Int I2, combine(Tr1, Tr2, #klabel(`_/__CPP-SYNTAX`)))
          requires isPromoted(T1) andBool I2 =/=Int 0
               andBool T1 ==Type T2

     rule prv(F1:Float, Tr1::Trace, T1::CPPType) / prv(F2:Float, Tr2::Trace, T2::CPPType)
          => arithInterpret(T1, F1 /Float F2, combine(Tr1, Tr2, #klabel(`_/__CPP-SYNTAX`)))
          requires isPromoted(T1) andBool F2 =/=Float 0.0
               andBool T1 ==Type T2

     rule (.K => UNDEF("CEMX1", "Division by 0."))
          ~> L:PRVal / prv(0, _, T2::CPPType)
          requires isCPPIntegerType(type(L)) andBool isPromoted(type(L))
               andBool type(L) ==Type T2

     rule (.K => UNDEF("CEMX1", "Division by 0."))
          ~> L:PRVal / prv(Z:Float, _, T2::CPPType)
          requires isCPPFloatingType(type(L)) andBool Z ==Float 0.0
               andBool type(L) ==Type T2

     rule prv(I1:Int, Tr1::Trace, T1::CPPIntegerType) % prv(I2:Int, Tr2::Trace, T2::CPPType)
          => arithInterpret(T1, I1 %Int I2, combine(Tr1, Tr2, #klabel(`_%__CPP-SYNTAX`)))
          requires isPromoted(T1) andBool I2 =/=Int 0
               andBool min(T1) <=Int I1 /Int I2
               andBool max(T1) >=Int I1 /Int I2
               andBool T1 ==Type T2

     rule (.K => UNDEF("CEMX2", "Modulus by 0."))
          ~> L:PRVal % prv(0, _, T2::CPPType)
          requires isCPPIntegerType(type(L)) andBool isPromoted(type(L))
               andBool type(L) ==Type T2

     rule (.K => UNDEF("CEMX3", "Signed integer overflow."))
          ~> prv(I1:Int, _, T1::CPPIntegerType) % prv(I2:Int, _, T2::CPPType)
          requires I2 =/=Int 0
               andBool notBool (min(T1) <=Int I1 /Int I2
                    andBool max(T1) >=Int I1 /Int I2)
               andBool isPromoted(T1)
               andBool I2 =/=Int 0
               andBool T1 ==Type T2

endmodule
