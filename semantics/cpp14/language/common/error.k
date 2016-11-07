module CPP-ERROR-SYNTAX
     imports ERROR-SYNTAX

     syntax KItem ::= COND(String, String)
                    | IMPL(String, String) [klabel(IMPLCpp)]
                    | UNDEF(String, String) [klabel(UNDEFCpp)]
                    | DRAFTING(String, String) [klabel(DRAFTINGCpp)]

endmodule

module CPP-ERROR
     imports CPP-ERROR-SYNTAX
     imports BOOL
     imports STRING

     rule COND(Title:String, Msg:String)
          => EXIT(ErrorMsg("CND-" +String Title, Msg, "Conditionally-supported behavior"))
          requires checkOptions(Cond(), Title, true)

     rule IMPL(Title:String, Msg:String)
          => EXIT(ErrorMsg("IMPL++-" +String Title, Msg, "Implementation-defined behavior."))
          requires checkOptions(Cond(), Title, true)

     rule UNDEF(Title:String, Msg:String)
          => EXIT(ErrorMsg("UB++-" +String Title, Msg, "Undefined behavior."))
          requires checkOptions(Undef(), Title, true)

     rule DRAFTING(Title:String, Msg:String)
          => EXIT(ErrorMsg("DR++-" +String Title, Msg, "Behavior underspecified by C++ standard."))
          requires checkOptions(Drafting(), Title, true)

     rule COND(Title:String, _) => HALT
          requires notBool checkOptions(Cond(), Title, true)
     rule IMPL(Title:String, _) => HALT
          requires notBool checkOptions(Impl(), Title, true)
     rule UNDEF(Title:String, _) => HALT
          requires notBool checkOptions(Undef(), Title, true)
     rule DRAFTING(Title:String, _) => HALT
          requires notBool checkOptions(Drafting(), Title, true)

endmodule
