module C-EXECUTION-ERROR-SYNTAX
     imports LIST
     imports STRING-SYNTAX
     imports COMMON-SORTS
     imports C-DYNAMIC-SORTS
     syntax String ::= printStackTrace(List, CabsLoc, Scope) [function]
     syntax KItem ::= error(String, String)
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

     rule assert(B::Bool, E::Error) => #if B #then .K #else E #fi [macro]


     rule (<k> EXIT(Msg:String) ~> K:K </k>
          => <final-computation> #write(2, Msg +String stackPrefix(L, Loc, S) +String printStackTrace(L, Loc, S) +String "\n") ~> K </final-computation>)
          <call-stack> L:List </call-stack>
          <curr-program-loc> Loc:CabsLoc </curr-program-loc>
          <curr-scope> S:Scope </curr-scope>
          requires notBool isErrorRecovery andBool notBool isCSV

     rule <k> EXIT(Msg:String) => #write(2, Msg +String stackPrefix(L, Loc, S) +String printStackTrace(L, Loc, S) +String "\n") ~> HALT ...</k>
          <call-stack> L:List </call-stack>
          <curr-program-loc> Loc:CabsLoc </curr-program-loc>
          <curr-scope> S:Scope </curr-scope>
          <previous-errors> Errors:Set => Errors SetItem(error(Msg, printStackTrace(L, Loc, S))) </previous-errors>
          requires isErrorRecovery andBool notBool isCSV
               andBool notBool error(Msg, printStackTrace(L, Loc, S)) in Errors

     rule <k> EXIT(Msg:String) => HALT ...</k>
          <call-stack> L:List </call-stack>
          <curr-program-loc> Loc:CabsLoc </curr-program-loc>
          <curr-scope> S:Scope </curr-scope>
          <previous-errors> Errors:Set </previous-errors>
          requires isErrorRecovery andBool notBool isCSV
               andBool error(Msg, printStackTrace(L, Loc, S)) in Errors

     rule <k> EXIT(Msg:String) => openWriteThenClose(Report, Msg +String ",\"" +String printStackTrace(L, Loc, S) +String "\"\r\n") ~> HALT ...</k>
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

     rule printStackTrace(L:List, UnknownCabsLoc, none)
          => printStackTrace(L, .K, .K)
     rule printStackTrace(L:List, Loc:CabsLoc, fileScope)
          => "  at <file-scope>(" +String printStackTrace(L, Loc, .K)
     rule printStackTrace(L:List, Loc:CabsLoc, blockScope(X::CId, _))
          => "  at " +String idToString(X) +String "(" +String printStackTrace(L, Loc, .K)
     rule printStackTrace(L:List, CabsLoc(File:String, Line:Int, _, _, _), .K)
          => File +String ":" +String Int2String(Line) +String ")" +String stackSeparator(L) +String printStackTrace(L, .K, .K)
     rule printStackTrace(L:List, UnknownCabsLoc, .K)
          => "<unknown>)" +String stackSeparator(L) +String printStackTrace(L, .K, .K)
     rule printStackTrace(ListItem(<call-stack-frame>...
               <stack-function-control> <function-control>...
                    <curr-program-loc> Loc:CabsLoc </curr-program-loc>
                    <curr-scope> S:Scope </curr-scope>
               ...</function-control> </stack-function-control>
          ...</call-stack-frame>) L:List, .K, .K)
          => printStackTrace(L, Loc, S)
     rule printStackTrace(.List, .K, .K) => ""

endmodule
