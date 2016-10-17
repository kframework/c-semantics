module ERROR-SYNTAX
     imports LIST
     imports STRING-SYNTAX

     syntax ErrorMsg ::= ErrorMsg(String, String, String, String, List)
                       | ErrorMsg(String, String, String, List) [function, klabel(ErrorMsgS)]

     syntax String ::= formatCitations(List) [function]

     syntax Bool ::= "isCSV" [function]
                   | "warnSystemHeaders" [function]
                   | checkOptions(K, String, Bool) [function]

     syntax Opts ::= Undef() | Unspec() | Impl() | Cond() | Undiag()
                   | No(Opts)
                   | Warn(String)
                   | CSV(String)
     syntax KItem ::= EXIT(ErrorMsg)
     syntax ErrorExit ::= "HALT"

     syntax Error
     syntax K ::= assert(Bool, Error)

     syntax K ::= openWriteThenClose(String, String) [function]
     syntax K ::= writeThenClose(Int, String) [function]
     syntax K ::= close(Int, K) [function]

     syntax KItem ::= "EXT" "-" "UNDEF" "(" String "," String "," String "," String ")" [function, klabel(ExtUndef)]
     syntax KItem ::= "EXT" "-" "UNDEF" "(" String "," String "," String "," String "," String ")"
     syntax KItem ::= UNDIAG(String, String, String)
endmodule

module ERROR
     imports ERROR-SYNTAX
     imports C-CONFIGURATION
     imports K-IO
     imports K-REFLECTION
     imports STRING

     rule ErrorMsg(Title:String, Msg:String, ErrType:String, L:List)
          => ErrorMsg(Title, Msg, ErrType, "", L)


     rule formatCitations(L:List) => formatCitationsStart({#if isCSV #then "" #else " See " #fi}:>String, L)

     syntax String ::= formatCitationsStart(String, List) [function]
     rule formatCitationsStart(Start:String, ListItem(Document:String) ListItem(Citation:String) L:List)
          => Start
          +String Document +String " sec. " +String Citation
          +String formatCitationsStart("; ", L)

     rule formatCitationsStart(_, .List) => ""

     rule openWriteThenClose(File:String, Line:String) => writeThenClose(#open(File, "wac"), Line)
     rule writeThenClose(Fd:Int, Line:String) => close(Fd, #write(Fd, Line))
     rule close(Fd:Int, .K) => #close(Fd)

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
          => EXT-UNDEF(Title, Msg, Document, Citation, "")
     rule EXT-UNDEF(Title:String, Msg:String, Document:String, Citation:String, Reason:String)
          => EXIT(ErrorMsg("UB-" +String Title, Msg, "Undefined behavior", Reason, ListItem(Document) ListItem(Citation)))
          requires checkOptions(Undef(), Title, true)
     rule UNDIAG(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg("URV-" +String Title, Msg, "Undiagnosable Rule violation", ListItem("C++14") ListItem(Citation)))
          requires checkOptions(Undiag(), Title, true)

     rule EXT-UNDEF(Title:String, _, _, _, _) => HALT
          requires notBool checkOptions(Undef(), Title, true)
     rule UNDIAG(Title:String, _, _) => HALT
          requires notBool checkOptions(Undiag(), Title, true)

endmodule
