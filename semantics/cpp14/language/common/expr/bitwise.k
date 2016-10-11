module CPP-EXPR-BITWISE
     imports INT
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule prv(E1:Int, Tr1::Trace, T1::CPPType) ^ prv(E2:Int, Tr2::Trace, T2::CPPType)
          => arithInterpret(T1, E1 xorInt E2, combine(Tr1, Tr2, #klabel(`_^__CPP-SYNTAX`)))
          requires isPromoted(T1) andBool T1 ==Type T2

     rule prv(E1:Int, Tr1::Trace, T1::CPPType) & prv(E2:Int, Tr2::Trace, T2::CPPType)
          => arithInterpret(T1, E1 &Int E2, combine(Tr1, Tr2, #klabel(`_&__CPP-SYNTAX`)))
          requires isPromoted(T1) andBool T1 ==Type T2

     rule prv(E1:Int, Tr1::Trace, T1::CPPType) | prv(E2:Int, Tr2::Trace, T2::CPPType)
          => arithInterpret(T1, E1 |Int E2, combine(Tr1, Tr2, #klabel(`_|__CPP-SYNTAX`)))
          requires isPromoted(T1) andBool T1 ==Type T2


endmodule
