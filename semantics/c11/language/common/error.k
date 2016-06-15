module C-ERROR-SYNTAX
     imports BASIC-K
     imports STRING-SYNTAX
     imports BOOL-SYNTAX
     imports INT-SYNTAX

     // Error code, desc., C11 citation.
     syntax KItem ::= UNDEF(String, String, String)
     syntax KItem ::= UNSPEC(String, String, String)
     syntax KItem ::= CV(String, String, String)
     syntax KItem ::= SE(String, String, String)
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
     syntax KItem ::= writeThenClose(Int, String)
     syntax KItem ::= close(Int)
     syntax Bool ::= "isCSV" [function]
                   | checkOptions(K, String, Bool) [function]

     syntax Opts ::= Undef() | Unspec() | Impl()
                   | No(Opts)
                   | Warn(String)

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
          requires checkOptions(Undef(), Title, true)
     rule UNSPEC(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg("USP-" +String Title, Msg, "Unspecified value or behavior.", "C11", Citation))
          requires checkOptions(Unspec(), Title, true)
     rule CV(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg("CV-" +String Title, Msg, "Constraint violation.", "C11", Citation))
     rule SE(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg("SE-" +String Title, Msg, "Syntax error.", "C11", Citation))
     rule IMPL(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg("IMPL-" +String Title, Msg, "Implementation defined behavior.", "C11", Citation))
          requires checkOptions(Impl(), Title, true)
     rule EXT-CV(Title:String, Msg:String, Document:String, Citation:String)
          => EXIT(ErrorMsg("CV-" +String Title, Msg, "Constraint violation.", Document, Citation))
     rule EXT-UNDEF(Title:String, Msg:String, Document:String, Citation:String)
          => EXIT(ErrorMsg("UB-" +String Title, Msg, "Undefined behavior.", Document, Citation))
          requires checkOptions(Undef(), Title, true)

     rule UNDEF(Title:String, _, _) => HALT
          requires notBool checkOptions(Undef(), Title, true)
     rule UNSPEC(Title:String, _, _) => HALT
          requires notBool checkOptions(Unspec(), Title, true)
     rule IMPL(Title:String, _, _) => HALT
          requires notBool checkOptions(Impl(), Title, true)
     rule EXT-UNDEF(Title:String, _, _, _) => HALT
          requires notBool checkOptions(Undef(), Title, true)

     rule openWriteThenClose(File:String, Line:String) => writeThenClose(#open(File, "wac"), Line)
     rule writeThenClose(Fd:Int, Line:String) => #write(Fd, Line) ~> close(Fd)
     rule close(Fd:Int) => #close(Fd)

     syntax Bool ::= isCSV(K) [function, klabel(isCSV1)]
     rule isCSV => isCSV(#configuration)
     rule isCSV(<generatedTop>... <options>... SetItem(CSV(_)) ...</options> ...</generatedTop>) => true
     rule isCSV(_) => false [owise]

     syntax Bool ::= checkOptions(K, String, Bool, K) [function, klabel(checkOptions1)]
                   | checkOptionsCateg(K, Bool, K) [function, klabel(checkOptions2)]
     rule checkOptions(Opt:Opts, S:String, B:Bool) => checkOptions(Opt, S, B, #configuration)
     rule checkOptions(_, S:String, _, <generatedTop>... <options>... SetItem(Warn(S))...</options> ...</generatedTop>) => true
     rule checkOptions(_, S:String, _, <generatedTop>... <options>... SetItem(No(Warn(S)))...</options> ...</generatedTop>) => false
     rule checkOptions(Opt:Opts, _, B:Bool, Config:K) => checkOptionsCateg(Opt, B, Config) [owise]

     rule checkOptionsCateg(Opt:Opts, _, <generatedTop>... <options>... SetItem(No(Opt))...</options> ...</generatedTop>) => false
     rule checkOptionsCateg(Opt:Opts, _, <generatedTop>... <options>... SetItem(Opt)...</options> ...</generatedTop>) => true
     rule checkOptionsCateg(_, B:Bool, _) => B [owise]
endmodule
