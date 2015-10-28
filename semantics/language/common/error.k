module C-ERROR-SYNTAX
     imports BASIC-K
     imports STRING-SYNTAX
     imports BOOL-SYNTAX

     // Error code, desc., C11 citation.
     syntax KItem ::= UNDEF(String, String, String)
     syntax KItem ::= UNSPEC(String, String, String)
     syntax KItem ::= CV(String, String, String)
     syntax KItem ::= IMPL(String, String, String)
     syntax KItem ::= "EXT-CV" "(" String "," String "," String "," String ")"

     syntax KResult ::= Bool
     syntax Error
     syntax K ::= assert(Bool, Error)

     syntax KItem ::= EXIT(String)
     syntax ErrorExit

     syntax KItem ::= openWriteThenClose(String, String)
     syntax Bool ::= "isCSV" [function]
 
endmodule

module C-ERROR
     imports C-ERROR-SYNTAX

     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports K-REFLECTION
     imports C-CONFIGURATION

     rule assert(B::Bool, E::Error) => #if B #then .K #else E #fi [macro]

     rule _:ErrorExit ~> _:Error => .K
          requires isErrorRecovery

     syntax String ::= ErrorMsg(String, String, String, String, String) [function]
     rule ErrorMsg(Title:String, Msg:String, ErrType:String, Document:String, Citation:String)
          => "Error: "
          +String Title
          +String "\n"
          +String "Description: "
          +String Msg
          +String "\n"
          +String "Type: "
          +String ErrType
          +String "\n"
          +String "See also: "
          +String Document
          +String " sec. "
          +String Citation
          requires Citation =/=String "" andBool notBool isCSV

     rule ErrorMsg(Title:String, Msg:String, ErrType:String, Document:String, Citation:String)
          => Title
          +String ",\""
          +String Msg
          +String "\","
          +String ErrType
          +String ",\""
          +String Document
          +String " sec. "
          +String Citation
          +String "\""
          requires Citation =/=String "" andBool isCSV

     rule UNDEF(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg("UB-" +String Title, Msg, "Undefined behavior.", "C11", Citation))
     rule UNSPEC(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg("USP-" +String Title, Msg, "Unspecified value or behavior.", "C11", Citation))
     rule CV(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg("CV-" +String Title, Msg, "Constraint violation.", "C11", Citation))
     rule IMPL(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg("IMPL-" +String Title, Msg, "Implementiation defined behavior.", "C11", Citation))
     rule EXT-CV(Title:String, Msg:String, Document:String, Citation:String)
          => EXIT(ErrorMsg(Title, Msg, "Constraint violation.", Document, Citation))

     syntax KItem ::= writeThenClose(Int, String)
     syntax KItem ::= close(Int)
     rule openWriteThenClose(File:String, Line:String) => writeThenClose(#open(File, "wac"), Line)
     rule writeThenClose(Fd:Int, Line:String) => #write(Fd, Line) ~> close(Fd)
     rule close(Fd:Int) => #close(Fd)

     syntax Bool ::= isCSV(K) [function, klabel(isCSV1)]

     rule isCSV => isCSV(#configuration)
     rule isCSV(<generatedTop>... <options>... SetItem(CSV(_)) ...</options> ...</generatedTop>) => true
     rule isCSV(_) => false [owise]

endmodule
