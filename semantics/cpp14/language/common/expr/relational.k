module CPP-EXPR-RELATIONAL
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     syntax PRVal ::= makeTruth(Bool, Trace) [function, klabel(makeTruthCpp)]
     rule makeTruth(B:Bool, Tr::Trace)
          => #if B #then prv(1, Tr, type(bool)) #else prv(0, Tr, type(bool)) #fi

     rule prv(I1:Int, Tr1::Trace, T1::CPPType) == prv(I2:Int, Tr2::Trace, T2::CPPType)
          => makeTruth(I1 ==Int I2, combine(Tr1, Tr2, #klabel(`_==__CPP-SYNTAX`)))
          requires isPromoted(T1) andBool T1 ==Type T2

     rule prv(I1:Int, Tr1::Trace, T1::CPPType) != prv(I2:Int, Tr2::Trace, T2::CPPType)
          => makeTruth(I1 =/=Int I2, combine(Tr1, Tr2, #klabel(`_!=__CPP-SYNTAX`)))
          requires isPromoted(T1) andBool T1 ==Type T2

     rule prv(I1:Int, Tr1::Trace, T1::CPPType) < prv(I2:Int, Tr2::Trace, T2::CPPType)
          => makeTruth(I1 <Int I2, combine(Tr1, Tr2, #klabel(`_<__CPP-SYNTAX`)))
          requires isPromoted(T1) andBool T1 ==Type T2
     rule prv(I1:Int, Tr1::Trace, T1::CPPType) > prv(I2:Int, Tr2::Trace, T2::CPPType)
          => makeTruth(I1 >Int I2, combine(Tr1, Tr2, #klabel(`_>__CPP-SYNTAX`)))
          requires isPromoted(T1) andBool T1 ==Type T2
     rule prv(I1:Int, Tr1::Trace, T1::CPPType) <= prv(I2:Int, Tr2::Trace, T2::CPPType)
          => makeTruth(I1 <=Int I2, combine(Tr1, Tr2, #klabel(`_<=__CPP-SYNTAX`)))
          requires isPromoted(T1) andBool T1 ==Type T2
     rule prv(I1:Int, Tr1::Trace, T1::CPPType) >= prv(I2:Int, Tr2::Trace, T2::CPPType)
          => makeTruth(I1 >=Int I2, combine(Tr1, Tr2, #klabel(`_>=__CPP-SYNTAX`)))
          requires isPromoted(T1) andBool T1 ==Type T2

endmodule
