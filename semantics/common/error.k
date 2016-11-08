module ERROR-SYNTAX
     imports LIST
     imports STRING-SYNTAX

     syntax ErrorMsg ::= ErrorMsg(String, String, String, String)
                       | ErrorMsg(String, String, String) [function, klabel(ErrorMsgS)]

     syntax String ::= formatErrorMsg(ErrorMsg, String, Bool) [function]
     syntax String ::= formatCitations(String, Bool) [function]

     syntax Bool ::= "isCSV" [function]
                   | "isNoWrap" [function]
                   | "warnSystemHeaders" [function]
                   | checkOptions(K, String, Bool) [function]

     syntax Opts ::= Undef() | Unspec() | Impl() | Cond() | Ill() | Drafting()
                   | No(Opts)
                   | Warn(String)
                   | CSV(String)
                   | NoWrap()
     syntax KItem ::= EXIT(ErrorMsg)
     syntax ErrorExit ::= "HALT"

     syntax Error
     syntax K ::= assert(Bool, Error)

     syntax K ::= doError(ErrorMsg, String) [function]
     syntax K ::= openWriteThenClose(String, String) [function]
     syntax K ::= writeThenClose(Int, String) [function]
     syntax K ::= close(Int, K) [function]

     syntax KItem ::= "EXT" "-" "UNDEF" "(" String "," String ")" [function, klabel(LinkUndef)]
     syntax KItem ::= "EXT" "-" "UNDEF" "(" String "," String "," String ")"
                    | ILL(String, String)
endmodule

module ERROR
     imports ERROR-SYNTAX
     imports C-CONFIGURATION
     imports K-IO
     imports K-REFLECTION
     imports CITATIONS
     imports STRING

     rule ErrorMsg(Title:String, Msg:String, ErrType:String)
          => ErrorMsg(Title, Msg, ErrType, "")

     rule formatCitations(Title:String, IsCSV:Bool) => formatCitationsWithDelims(citations(Title), IsCSV, isNoWrap)

     syntax String ::= formatCitationsWithDelims(List, Bool, Bool) [function]
     rule formatCitationsWithDelims(.List, _, _) => ""
     rule formatCitationsWithDelims(ListItem(Citation:KItem) Citations::List, IsCSV::Bool, IsNoWrap::Bool)
          => formatCitationWithDelims(Citation, IsCSV, IsNoWrap) +String formatCitationsWithDelims(Citations:List, IsCSV, IsNoWrap)

     syntax String ::= formatCitationWithDelims(K, Bool, Bool) [function]
     rule formatCitationWithDelims(citation(Source::String, Section::String, Details::String), IsCSV:Bool, IsNoWrap:Bool)
          => {#if IsNoWrap #then "" #else "\n" #fi}:>String +String {#if IsCSV #then "" #else "   see " #fi}:>String +String Source
             +String {#if IsCSV #then "," #else " section " #fi}:>String +String Section
             +String {#if IsCSV #then "," +String Details #else #if Details =/=String "" #then ":" +String Details #else "" #fi  #fi}:>String
             +String {#if IsCSV #then "," #else " " #fi}:>String +String citationURL(Source, Section)

     syntax String ::= replaceAllMap(String, Map) [function]
     rule replaceAllMap(Source:String, .Map) => Source
     rule replaceAllMap(Source:String, Key:String |-> Value:String Rest:Map) => replaceAllMap(replaceAll(Source, Key, Value), Rest)

     syntax String ::= percenteEncode(String) [function]
     rule percenteEncode(Source:String) => replaceAllMap(replaceAll(Source, "%", "%25"),
             "!" |-> "%21" "#" |-> "%23" "$" |-> "%24" "&" |-> "%26" "'" |-> "%27" "(" |-> "%28" ")" |-> "%29"
             "*" |-> "%2A" "+" |-> "%2B" "," |-> "%2C" "/" |-> "%2F" ":" |-> "%3A" ";" |-> "%3B" "=" |-> "%3D"
             "?" |-> "%3F" "@" |-> "%40" "[" |-> "%5B" "]" |-> "%5D" " " |-> "%20")

     syntax String ::= citationURL(String, String) [function]
     rule citationURL(Source:String, Section:String)
          => "http://rvdoc.org/" +String percenteEncode(Source) +String "/" +String percenteEncode(Section)

     rule doError(Err::ErrorMsg, StackTrace::String)
          => openWriteThenClose(#getenv("HOME") +String "/.kcc-report.csv", formatErrorMsg(Err, StackTrace, true) +String "\r\n")
          ~> #write(2, formatErrorMsg(Err, StackTrace, false) +String "\n")

     rule openWriteThenClose(File:String, Line:String) => writeThenClose(#open(File, "wac"), Line)
     rule writeThenClose(Fd:Int, Line:String) => close(Fd, #write(Fd, Line))
     rule close(Fd:Int, .K) => #close(Fd)

     syntax Bool ::= isCSV(K) [function, klabel(isCSV1)]
     rule isCSV => isCSV(#configuration)
     rule isCSV(<generatedTop>... <options>... SetItem(CSV(_)) ...</options> ...</generatedTop>) => true
     rule isCSV(_) => false [owise]

     syntax Bool ::= isNoWrap(K) [function, klabel(isNoWrap1)]
     rule isNoWrap => isNoWrap(#configuration)
     rule isNoWrap(<generatedTop>... <options>... SetItem(NoWrap()) ...</options> ...</generatedTop>) => true
     rule isNoWrap(_) => false [owise]


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

     rule EXT-UNDEF(Title:String, Msg:String)
          => EXT-UNDEF(Title, Msg, "")
     rule EXT-UNDEF(Title:String, Msg:String, Reason:String)
          => EXIT(ErrorMsg("UB-" +String Title, Msg, "Undefined behavior", Reason))
          requires checkOptions(Undef(), Title, true)

     rule ILL(Title:String, Msg:String)
          => EXIT(ErrorMsg("ILF-" +String Title, Msg, "Ill-formed program."))
          requires checkOptions(Ill(), Title, true)

     rule EXT-UNDEF(Title:String, _, _) => HALT
          requires notBool checkOptions(Undef(), Title, true)

     rule ILL(Title:String, _) => HALT
          requires notBool checkOptions(Ill(), Title, true)

endmodule
