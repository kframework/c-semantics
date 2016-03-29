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
     syntax KItem ::= "EXT-UNDEF" "(" String "," String "," String "," String ")"

     syntax KResult ::= Bool
     syntax Error
     syntax K ::= assert(Bool, Error)

     syntax KItem ::= EXIT(String)
     syntax ErrorExit ::= "HALT"

     syntax String ::= ErrorMsg(String, String, String, String, String) [function]
     syntax KItem ::= openWriteThenClose(String, String)
     syntax Bool ::= "isCSV" [function]
                   | "isUndef" [function]
                   | "isUnspec" [function]
                   | "isImpl" [function]

     syntax Opts ::= "NO-UNDEF" | "NO-UNSPEC" | "NO-IMPL"

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
          requires isUndef
     rule UNSPEC(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg("USP-" +String Title, Msg, "Unspecified value or behavior.", "C11", Citation))
          requires isUnspec
     rule CV(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg("CV-" +String Title, Msg, "Constraint violation.", "C11", Citation))
     rule IMPL(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg("IMPL-" +String Title, Msg, "Implementation defined behavior.", "C11", Citation))
          requires isImpl
     rule EXT-CV(Title:String, Msg:String, Document:String, Citation:String)
          => EXIT(ErrorMsg("CV-" +String Title, Msg, "Constraint violation.", Document, Citation))
     rule EXT-UNDEF(Title:String, Msg:String, Document:String, Citation:String)
          => EXIT(ErrorMsg("UB-" +String Title, Msg, "Undefined behavior.", Document, Citation))
          requires isUndef

     rule UNDEF(_, _, _) => HALT
          requires notBool isUndef
     rule UNSPEC(_, _, _) => HALT
          requires notBool isUnspec
     rule IMPL(_, _, _) => HALT
          requires notBool isImpl
     rule EXT-UNDEF(_, _, _) => HALT
          requires notBool isUndef

     syntax KItem ::= writeThenClose(Int, String)
     syntax KItem ::= close(Int)
     rule openWriteThenClose(File:String, Line:String) => writeThenClose(#open(File, "wac"), Line)
     rule writeThenClose(Fd:Int, Line:String) => #write(Fd, Line) ~> close(Fd)
     rule close(Fd:Int) => #close(Fd)

     syntax Bool ::= isCSV(K) [function, klabel(isCSV1)]
     rule isCSV => isCSV(#configuration)
     rule isCSV(<generatedTop>... <options>... SetItem(CSV(_)) ...</options> ...</generatedTop>) => true
     rule isCSV(_) => false [owise]

     syntax Bool ::= isUndef(K) [function, klabel(isUndef1)]
     rule isUndef => isUndef(#configuration)
     rule isUndef(<generatedTop>... <options>... SetItem(NO-UNDEF) ...</options> ...</generatedTop>) => false
     rule isUndef(_) => true [owise]
     syntax Bool ::= isUnspec(K) [function, klabel(isUnspec1)]
     rule isUnspec => isUnspec(#configuration)
     rule isUnspec(<generatedTop>... <options>... SetItem(NO-UNSPEC) ...</options> ...</generatedTop>) => false
     rule isUnspec(_) => true [owise]
     syntax Bool ::= isImpl(K) [function, klabel(isImpl1)]
     rule isImpl => isImpl(#configuration)
     rule isImpl(<generatedTop>... <options>... SetItem(NO-IMPL) ...</options> ...</generatedTop>) => false
     rule isImpl(_) => true [owise]

endmodule
