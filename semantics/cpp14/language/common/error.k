module CPP-ERROR-SYNTAX
     imports ERROR-SYNTAX

     syntax KItem ::= COND(String, String, String)
                    | DV(String, String, String)

endmodule

module CPP-ERROR
     imports CPP-ERROR-SYNTAX
     imports COMPAT-SYNTAX

     rule COND(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg("CND-" +String Title, Msg, "Conditionally-supported behavior.", ListItem("C++14") ListItem(Citation)))
          requires checkOptions(Cond(), Title, true)

     rule DV(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg("DRV-" +String Title, Msg, "Diagnosable Rule violation.", ListItem("C++14") ListItem(Citation)))

     rule COND(Title:String, _, _) => HALT
          requires notBool checkOptions(Cond(), Title, true)

endmodule
