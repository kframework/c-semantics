module CPP-ERROR-SYNTAX
     imports ERROR-SYNTAX

     syntax KItem ::= COND(String, String, String)
                    | IMPL(String, String, String) [klabel(IMPLCpp)]
                    | UNDEF(String, String, String) [klabel(UNDEFCpp)]
                    | DRAFTING(String, String, Int) [klabel(DRAFTINGCpp)]

endmodule

module CPP-ERROR
     imports CPP-ERROR-SYNTAX
     imports BOOL
     imports STRING

     rule COND(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg("CND-" +String Title, Msg, "Conditionally-supported behavior", ListItem("C++14") ListItem(Citation)))
          requires checkOptions(Cond(), Title, true)

     rule IMPL(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg("IMPL++-" +String Title, Msg, "Implementation-defined behavior.", ListItem("C++14") ListItem(Citation)))
          requires checkOptions(Cond(), Title, true)

     rule UNDEF(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg("UB++-" +String Title, Msg, "Undefined behavior.", ListItem("C++14") ListItem(Citation)))
          requires checkOptions(Undef(), Title, true)

     rule DRAFTING(Title:String, Msg:String, Citation:Int)
          => EXIT(ErrorMsg("DR++-" +String Title, Msg, "Behavior underspecified by C++ standard.", ListItem("C++ Defect Reports") ListItem(Int2String(Citation))))
          requires checkOptions(Drafting(), Title, true)

     rule COND(Title:String, _, _) => HALT
          requires notBool checkOptions(Cond(), Title, true)
     rule IMPL(Title:String, _, _) => HALT
          requires notBool checkOptions(Impl(), Title, true)
     rule UNDEF(Title:String, _, _) => HALT
          requires notBool checkOptions(Undef(), Title, true)
     rule DRAFTING(Title:String, _, _) => HALT
          requires notBool checkOptions(Drafting(), Title, true)

endmodule
