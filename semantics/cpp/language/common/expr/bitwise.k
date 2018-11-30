module CPP-EXPR-BITWISE
     imports INT
     imports ALIGNMENT-SYNTAX
     imports SYMLOC-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ERROR-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule prv(E1:Int, Tr1::Trace, T1::CPPType) ^ prv(E2:Int, Tr2::Trace, T2::CPPType)
          => arithInterpret(T1, E1 xorInt E2, combine(Tr1, Tr2, #klabel(`_^__CPP-SYNTAX`)))
          requires isPromoted(T1) andBool T1 ==Type T2


     rule prv(E1:Int, Tr1::Trace, T1::CPPType) & prv(E2:Int, Tr2::Trace, T2::CPPType)
          => arithInterpret(T1, E1 &Int E2, combine(Tr1, Tr2, #klabel(`_&__CPP-SYNTAX`)))
          requires isPromoted(T1) andBool T1 ==Type T2

     rule prv(L:SymLoc, Tr1::Trace, T1::CPPType) & prv(E2:Int, Tr2::Trace, T2::CPPType)
          => prv(L, Tr1, T1) + prv((offset(L) &Int E2) -Int offset(L), Tr2, T2)
          requires (~Int (getAlign(L) -Int 1) &Int ~Int E2) &Int max(correspondingUnsignedType(T1)) ==Int 0
               andBool isPromoted(T1) andBool T1 ==Type T2

     rule prv(E2:Int, Tr1::Trace, T1::CPPType) & prv(L:SymLoc, Tr2::Trace, T2::CPPType)
          => prv((offset(L) &Int E2) -Int offset(L), Tr1, T1) + prv(L, Tr2, T2)
          requires (~Int (getAlign(L) -Int 1) &Int ~Int E2) &Int max(correspondingUnsignedType(T1)) ==Int 0
               andBool isPromoted(T1) andBool T1 ==Type T2

     rule prv(L:SymLoc, Tr1::Trace, T1::CPPType) & prv(E2:Int, Tr2::Trace, T2::CPPType)
          => prv(0, combine(Tr1, Tr2, #klabel(`_&__CPP-SYNTAX`)), T1)
          requires getAlign(L) >Int E2 andBool E2 >=Int 0
               andBool isPromoted(T1) andBool T1 ==Type T2

     rule prv(E2:Int, Tr1::Trace, T1::CPPType) & prv(L:SymLoc, Tr2::Trace, T2::CPPType)
          => prv(0, combine(Tr1, Tr2, #klabel(`_&__CPP-SYNTAX`)), T1)
          requires getAlign(L) >Int E2 andBool E2 >=Int 0
               andBool isPromoted(T1) andBool T1 ==Type T2


     rule prv(E1:Int, Tr1::Trace, T1::CPPType) | prv(E2:Int, Tr2::Trace, T2::CPPType)
          => arithInterpret(T1, E1 |Int E2, combine(Tr1, Tr2, #klabel(`_|__CPP-SYNTAX`)))
          requires isPromoted(T1) andBool T1 ==Type T2


     rule prv(E1:Int, Tr1::Trace, T1::CPPType) << prv(E2:Int, Tr2::Trace, T2::CPPType)
          => arithInterpret(T1, E1 <<Int E2, combine(Tr1, Tr2, #klabel(`_<<__CPP-SYNTAX`)))
          requires isPromoted(T1) andBool isPromoted(T2) andBool isCPPUnsignedType(underlyingType(T1))

     rule prv(E1:Int, Tr1::Trace, T1::CPPType) << prv(E2:Int, Tr2::Trace, T2::CPPType)
          => ConvertType(T1, arithInterpret(correspondingUnsignedType(underlyingType(T1)), E1 <<Int E2, combine(Tr1, Tr2, #klabel(`_<<__CPP-SYNTAX`))))
          requires isPromoted(T1) andBool isPromoted(T2)
               andBool isCPPSignedType(underlyingType(T1))
               andBool E1 >=Int 0

     rule (.K => UNDEF("CEB1", "Left operand of left shift has signed type and negative value."))
          ~> prv(E1:Int, Tr1::Trace, T1::CPPType) << prv(E2:Int, Tr2::Trace, T2::CPPType)
          requires isPromoted(T1) andBool isPromoted(T2)
               andBool isCPPSignedType(underlyingType(T1))
               andBool E1 <Int 0

     rule prv(E1:Int, Tr1::Trace, T1::CPPType) >> prv(E2:Int, Tr2::Trace, T2::CPPType)
          => arithInterpret(T1, E1 >>Int E2, combine(Tr1, Tr2, #klabel(`_<<__CPP-SYNTAX`)))
          requires isPromoted(T1) andBool isPromoted(T2) andBool (isCPPUnsignedType(underlyingType(T1)) orBool E1 >=Int 0)

     rule (.K => IMPL("CEB2", "Left operand of right shift has signed type and negative value."))
          ~> prv(E1:Int, Tr1::Trace, T1::CPPType) >> prv(E2:Int, Tr2::Trace, T2::CPPType)
          requires isPromoted(T1) andBool isPromoted(T2)
               andBool isCPPSignedType(underlyingType(T1))
               andBool E1 <Int 0

endmodule
