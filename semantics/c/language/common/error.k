module C-ERROR-SYNTAX
     imports BASIC-K
     imports COMMON-SORTS
     imports STRING-SYNTAX
     imports BOOL-SYNTAX
     imports INT-SYNTAX
     imports ERROR-SYNTAX

     // Error code, desc., citation.
     syntax KItem ::= UNDEF(String, String) [function, klabel(CUndef)]
     syntax KItem ::= UNDEF(String, String, List)
     syntax KItem ::= UNSPEC(String, String)
     syntax KItem ::= CV(String, String)
     syntax KItem ::= SE(String, String)
     syntax KItem ::= IMPL(String, String)
     syntax KItem ::= IMPLUB(String, String)

     syntax KResult ::= Bool

     syntax CabsLoc ::= fixLocSystemHeader(mainLoc:CabsLoc, additionalLoc:CabsLoc) [function]

endmodule

module C-ERROR
     imports C-ERROR-SYNTAX
     imports C-CONFIGURATION
     imports COMMON-SYNTAX
     imports BOOL
     imports STRING

     rule UNDEF(Title:String, Msg:String) => UNDEF(Title, Msg, .List)

     rule UNDEF(Title:String, Msg:String, Reason:List)
          => EXIT(ErrorMsg(Undef(CLinkage), Title, Msg, Reason))
     rule UNSPEC(Title:String, Msg:String)
          => EXIT(ErrorMsg(Unspec(CLinkage), Title, Msg))
     rule CV(Title:String, Msg:String)
          => EXIT(ErrorMsg(Constraint(), Title, Msg))
     rule SE(Title:String, Msg:String)
          => EXIT(ErrorMsg(Syntax(CLinkage), Title, Msg))
     rule IMPL(Title:String, Msg:String)
          => EXIT(ErrorMsg(Impl(CLinkage), Title, Msg))
     rule IMPLUB(Title:String, Msg:String)
          => EXIT(ErrorMsg(ImplUB(CLinkage), Title, Msg))

     rule fixLocSystemHeader(CabsLoc(... systemHeader: false) #as Main:CabsLoc, _:CabsLoc)
          => Main
     rule fixLocSystemHeader(
               CabsLoc(Rel:String, Abs:String, Line:Int, Col:Int, true),
               CabsLoc(... systemHeader: false))
          => CabsLoc(Rel, Abs, Line, Col, false)
     rule fixLocSystemHeader(First:CabsLoc, _:CabsLoc) => First  [owise]

endmodule
