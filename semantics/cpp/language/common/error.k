module CPP-ERROR-SYNTAX
     imports ERROR-SYNTAX

     syntax KItem ::= COND(String, String)
                    | IMPL(String, String) [klabel(IMPLCpp)]
                    | UNDEF(String, String) [klabel(UNDEFCpp)]
                    | DRAFTING(String, String) [klabel(DRAFTINGCpp)]
                    | UNSPEC(String, String) [klabel(UNSPECCpp)]

endmodule

module CPP-ERROR
     imports CPP-ERROR-SYNTAX
     imports BOOL
     imports STRING
     imports COMMON-SYNTAX

     rule COND(Title:String, Msg:String)
          => EXIT(ErrorMsg(Cond(), Title, Msg))

     rule IMPL(Title:String, Msg:String)
          => EXIT(ErrorMsg(Impl(CPPLinkage), Title, Msg))

     rule UNDEF(Title:String, Msg:String)
          => EXIT(ErrorMsg(Undef(CPPLinkage), Title, Msg))

     rule UNSPEC(Title:String, Msg:String)
          => EXIT(ErrorMsg(Unspec(CPPLinkage), Title, Msg))

     rule DRAFTING(Title:String, Msg:String)
          => EXIT(ErrorMsg(Drafting(CPPLinkage), Title, Msg))

endmodule
