module ERROR-SYNTAX
     imports LIST
     imports STRING-SYNTAX

     syntax String ::= ErrorMsg(String, String, String, List) [function]
                     | ErrorMsg(List) [function, klabel(ErrorMsg1)]

     syntax Bool ::= "isCSV" [function]
                   | "warnSystemHeaders" [function]
                   | checkOptions(K, String, Bool) [function]

     syntax Opts ::= Undef() | Unspec() | Impl() | Cond() | Undiag()
                   | No(Opts)
                   | Warn(String)
                   | CSV(String)
     syntax KItem ::= EXIT(String)
     syntax ErrorExit ::= "HALT"

     syntax Error
     syntax K ::= assert(Bool, Error)

     syntax KItem ::= openWriteThenClose(String, String)
     syntax KItem ::= writeThenClose(Int, String)
     syntax KItem ::= close(Int)

     syntax KItem ::= "EXT" "-" "UNDEF" "(" String "," String "," String "," String ")"
     syntax KItem ::= UNDIAG(String, String, String)
endmodule

module ERROR
     imports ERROR-SYNTAX
     imports C-CONFIGURATION
     imports K-IO
     imports K-REFLECTION
     imports STRING

     rule ErrorMsg(Title:String, Msg:String, ErrType:String, L:List)
          => "Error: "
          +String Title
          +String "\n"
          +String "Description: "
          +String Msg
          +String "\n"
          +String "Type: "
          +String ErrType
          +String ErrorMsg(L)
          requires notBool isCSV

     rule ErrorMsg(ListItem(Document:String) ListItem(Citation:String) L:List)
          => "\n"
          +String "See also: "
          +String Document
          +String " sec. "
          +String Citation
          +String ErrorMsg(L)
          requires notBool isCSV

     rule ErrorMsg(Title:String, Msg:String, ErrType:String, L:List)
          => Title
          +String ",\""
          +String Msg
          +String "\","
          +String ErrType
          +String ",\""
          +String ErrorMsg(L)
          +String "\""
          requires isCSV

     rule ErrorMsg(ListItem(Document:String) ListItem(Citation:String) L:List)
          => Document
          +String " sec. "
          +String Citation
          +String "\n"
          +String ErrorMsg(L)
          requires isCSV
          
     rule ErrorMsg(.List) => ""

     rule openWriteThenClose(File:String, Line:String) => writeThenClose(#open(File, "wac"), Line)
     rule writeThenClose(Fd:Int, Line:String) => #write(Fd, Line) ~> close(Fd)
     rule close(Fd:Int) => #close(Fd)

     syntax Bool ::= isCSV(K) [function, klabel(isCSV1)]
     rule isCSV => isCSV(#configuration)
     rule isCSV(<generatedTop>... <options>... SetItem(CSV(_)) ...</options> ...</generatedTop>) => true
     rule isCSV(_) => false [owise]

     rule warnSystemHeaders => checkOptionsCateg(Warn("system-headers"), false, #configuration)

     syntax Bool ::= checkOptions(K, String, Bool, K) [function, klabel(checkOptions1)]
                   | checkOptionsCateg(K, Bool, K) [function, klabel(checkOptions2)]
     rule checkOptions(Opt:Opts, S:String, B:Bool) => checkOptions(Opt, S, B, #configuration)
     rule checkOptions(_, S:String, _, <generatedTop>... <options>... SetItem(Warn(S))...</options> ...</generatedTop>) => true
     rule checkOptions(_, S:String, _, <generatedTop>... <options>... SetItem(No(Warn(S)))...</options> ...</generatedTop>) => false
     rule checkOptions(Opt:Opts, _, B:Bool, Config:K) => checkOptionsCateg(Opt, B, Config) [owise]

     rule checkOptionsCateg(Opt:Opts, _, <generatedTop>... <options>... SetItem(No(Opt))...</options> ...</generatedTop>) => false
     rule checkOptionsCateg(Opt:Opts, _, <generatedTop>... <options>... SetItem(Opt)...</options> ...</generatedTop>) => true
     rule checkOptionsCateg(_, B:Bool, _) => B [owise]

     rule EXT-UNDEF(Title:String, Msg:String, Document:String, Citation:String)
          => EXIT(ErrorMsg("UB-" +String Title, Msg, "Undefined behavior.", ListItem(Document) ListItem(Citation)))
          requires checkOptions(Undef(), Title, true)
     rule UNDIAG(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg("URV-" +String Title, Msg, "Undiagnosable Rule violation.", ListItem("C++14") ListItem(Citation)))
          requires checkOptions(Undiag(), Title, true)

     rule EXT-UNDEF(Title:String, _, _, _) => HALT
          requires notBool checkOptions(Undef(), Title, true)
     rule UNDIAG(Title:String, _, _) => HALT
          requires notBool checkOptions(Undiag(), Title, true)

endmodule
