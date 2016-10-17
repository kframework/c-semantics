module C-EXECUTION-ERROR-SYNTAX
     imports LIST
     imports STRING-SYNTAX
     imports COMMON-SORTS
     imports C-DYNAMIC-SORTS
     imports ERROR-SYNTAX
     syntax String ::= printStackTrace(List, CabsLoc, Scope) [function]
                     | printStackTraceStart(String, List, CabsLoc, Scope) [function]
                     | formatErrorMsg(ErrorMsg, String, Bool) [function]
     syntax KItem ::= error(ErrorMsg, String)
endmodule

module C-EXECUTION-ERROR
     imports C-ERROR-SYNTAX
     imports C-EXECUTION-ERROR-SYNTAX
     imports C-CONFIGURATION
     imports K-IO
     imports STRING
     imports BITS-SYNTAX
     imports SETTINGS-SYNTAX
     imports C-DYNAMIC-SYNTAX

     rule formatErrorMsg(ErrorMsg(Title:String, Msg:String, ErrType:String, Reason:String, L:List), Trace:String, false)
          => " " +String Msg
          +String {#if Trace ==String "" #then "" #else "\n" +String Trace #fi}:>String
          +String {#if Reason ==String "" #then "" #else "\n  " +String Reason #fi}:>String
          +String "\n  " +String ErrType +String " (" +String Title +String ")."
          +String formatCitations(L)

     rule formatErrorMsg(ErrorMsg(Title:String, Msg:String, ErrType:String, Reason:String, L:List), Trace:String, true)
          => Title
          +String ",\""
          +String Msg
          +String "\","
          +String ErrType
          +String ",\""
          +String formatCitations(L)
          +String "\""
          +String ",\"" +String Reason +String "\""
          +String ",\"" +String Trace +String "\""


     rule assert(B::Bool, E::Error) => #if B #then .K #else E #fi [macro]


     rule (<k> EXIT(Msg:ErrorMsg) ~> K:K </k>
          => <final-computation> #write(2, formatErrorMsg(Msg, printStackTrace(L, Loc, S), false) +String "\n") ~> K </final-computation>)
          <call-stack> L:List </call-stack>
          <curr-program-loc> Loc:CabsLoc </curr-program-loc>
          <curr-scope> S:Scope </curr-scope>
          requires notBool isErrorRecovery andBool notBool isCSV

     rule <k> EXIT(Msg:ErrorMsg) => #write(2, formatErrorMsg(Msg, printStackTrace(L, Loc, S), false) +String "\n") ~> HALT ...</k>
          <call-stack> L:List </call-stack>
          <curr-program-loc> Loc:CabsLoc </curr-program-loc>
          <curr-scope> S:Scope </curr-scope>
          <previous-errors> Errors:Set => Errors SetItem(error(Msg, printStackTrace(L, Loc, S))) </previous-errors>
          requires isErrorRecovery andBool notBool isCSV
               andBool notBool error(Msg, printStackTrace(L, Loc, S)) in Errors

     rule <k> EXIT(Msg:ErrorMsg) => HALT ...</k>
          <call-stack> L:List </call-stack>
          <curr-program-loc> Loc:CabsLoc </curr-program-loc>
          <curr-scope> S:Scope </curr-scope>
          <previous-errors> Errors:Set </previous-errors>
          requires isErrorRecovery andBool notBool isCSV
               andBool error(Msg, printStackTrace(L, Loc, S)) in Errors

     rule <k> EXIT(Msg:ErrorMsg) => openWriteThenClose(Report, formatErrorMsg(Msg, printStackTrace(L, Loc, S), true) +String "\r\n") ~> HALT ...</k>
          <call-stack> L:List </call-stack>
          <curr-program-loc> Loc:CabsLoc </curr-program-loc>
          <curr-scope> S:Scope </curr-scope>
          <options>... SetItem(CSV(Report:String)) ...</options>
          requires isErrorRecovery

     syntax String ::= stackPrefix(List, CabsLoc, Scope) [function]
     rule stackPrefix(.List, UnknownCabsLoc, none) => ""
     rule stackPrefix(_, _, _) => "\n" [owise]

     syntax String ::= stackSeparator(List) [function]
     rule stackSeparator(.List) => ""
     rule stackSeparator(ListItem(_)) => ""
     rule stackSeparator(_) => "\n" [owise]

     rule printStackTrace(L:List, Loc:CabsLoc, S:Scope) => printStackTraceStart("   at ", L, Loc, S)

     rule printStackTraceStart(Start:String, L:List, UnknownCabsLoc, none)
          => printStackTraceStart(Start, L, .K, .K)
     rule printStackTraceStart(Start:String, L:List, Loc:CabsLoc, fileScope)
          => Start +String "<file-scope>(" +String printStackTraceStart("   by ", L, Loc, .K)
     rule printStackTraceStart(Start:String, L:List, Loc:CabsLoc, blockScope(X::CId, _))
          => Start +String idToString(X) +String "(" +String printStackTraceStart("   by ", L, Loc, .K)
     rule printStackTraceStart(Start:String, L:List, CabsLoc(File:String, Line:Int, Column:Int, _, _), .K)
          => File +String ":" +String Int2String(Line) +String ":" +String Int2String(Column) +String ")" +String stackSeparator(L) +String printStackTraceStart(Start, L, .K, .K)
     rule printStackTraceStart(Start:String, L:List, CabsLoc(File:String, Line:Int, .K, _, _), .K)
          => File +String ":" +String Int2String(Line) +String ")" +String stackSeparator(L) +String printStackTraceStart(Start, L, .K, .K)
     rule printStackTraceStart(Start:String, L:List, UnknownCabsLoc, .K)
          => "<unknown>)" +String stackSeparator(L) +String printStackTraceStart(Start, L, .K, .K)
     rule printStackTraceStart(Start:String, ListItem(<call-stack-frame>...
               <stack-function-control> <function-control>...
                    <curr-program-loc> Loc:CabsLoc </curr-program-loc>
                    <curr-scope> S:Scope </curr-scope>
               ...</function-control> </stack-function-control>
          ...</call-stack-frame>) L:List, .K, .K)
          => printStackTraceStart(Start, L, Loc, S)
     rule printStackTraceStart(Start:String, .List, .K, .K) => ""

endmodule
