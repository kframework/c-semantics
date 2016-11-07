module C-ERROR-SYNTAX
     imports BASIC-K
     imports STRING-SYNTAX
     imports BOOL-SYNTAX
     imports INT-SYNTAX
     imports ERROR-SYNTAX

     // Error code, desc., C11 citation.
     syntax KItem ::= UNDEF(String, String) [function, klabel(CUndef)]
     syntax KItem ::= UNDEF(String, String, String)
     syntax KItem ::= UNSPEC(String, String)
     syntax KItem ::= CV(String, String)
     syntax KItem ::= SE(String, String)
     syntax KItem ::= IMPL(String, String)

     syntax KResult ::= Bool

endmodule

module C-ERROR
     imports C-ERROR-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports STRING

     rule UNDEF(Title:String, Msg:String) => UNDEF(Title, Msg, "")

     rule UNDEF(Title:String, Msg:String, Reason:String)
      => EXIT(ErrorMsg("UB-" +String Title, Msg, "Undefined behavior", Reason))
          requires checkOptions(Undef(), Title, true)
     rule UNSPEC(Title:String, Msg:String)
          => EXIT(ErrorMsg("USP-" +String Title, Msg, "Unspecified value or behavior"))
          requires checkOptions(Unspec(), Title, true)
     rule CV(Title:String, Msg:String)
          => EXIT(ErrorMsg("CV-" +String Title, Msg, "Constraint violation"))
     rule SE(Title:String, Msg:String)
          => EXIT(ErrorMsg("SE-" +String Title, Msg, "Syntax error"))
     rule IMPL(Title:String, Msg:String)
          => EXIT(ErrorMsg("IMPL-" +String Title, Msg, "Implementation defined behavior"))
          requires checkOptions(Impl(), Title, true)

     rule UNDEF(Title:String, _, _) => HALT
          requires notBool checkOptions(Undef(), Title, true)
     rule UNSPEC(Title:String, _) => HALT
          requires notBool checkOptions(Unspec(), Title, true)
     rule IMPL(Title:String, _) => HALT
          requires notBool checkOptions(Impl(), Title, true)

endmodule
