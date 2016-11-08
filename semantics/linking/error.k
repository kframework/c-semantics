module TRANSLATION-ERROR
     imports C-CONFIGURATION
     imports STRING
     imports K-IO
     imports ERROR-SYNTAX

     syntax KItem ::= error(ErrorMsg, CabsLoc)
     rule <k> EXIT(_) => HALT ...</k>
          <curr-program-loc> CabsLoc(_, _, _, _, true) </curr-program-loc>
          requires notBool warnSystemHeaders

     syntax String ::= formatLocation(String, Int, Int) [function]
     rule formatLocation(File:String, Line:Int, Column:Int)
          => File +String ":" +String Int2String(Line) +String ":" +String Int2String(Column)

     rule formatErrorMsg(ErrorMsg(Title:String, Msg:String, ErrType:String, Reason:String),Location:String, false)
          => {#if Location ==String "" #then "" #else Location +String ": " #fi}:>String
          +String getErrorType(Title) +String ": "
          +String Msg
          +String {#if Reason ==String "" #then "" #else "\n" +String Reason #fi}:>String
          +String {#if isNoWrap #then "  " #else "\n  " #fi}:>String +String ErrType +String " (" +String Title +String ")."
          +String formatCitations(Title, false)

     rule formatErrorMsg(ErrorMsg(Title:String, Msg:String, ErrType:String, Reason:String),Location:String, true)
          => Title
          +String ",\"" +String Msg +String "\""
          +String ","   +String ErrType
          +String ",\"" +String formatCitations(Title, true) +String "\""
          +String ",\"" +String Reason +String "\""
          +String ",\"" +String Location +String "\""

     syntax String ::= getErrorType(String) [function]
     rule getErrorType(S:String) => {#if "L-" ==String substrString(S,0,2) orElseBool "IMPL-" ==String substrString(S,0,5) #then "warning" #else "error" #fi}:>String

     rule <k> EXIT(Msg:ErrorMsg)
          => doError(Msg, formatLocation(File, Line, Column))
          ~> HALT ...</k>
          <curr-eval-context> eval </curr-eval-context>
          <curr-program-loc>
               CabsLoc(File:String, Line:Int, Column:Int, _, SysHead:Bool)
          </curr-program-loc>
          <result-value> _ => 1 </result-value>
          <previous-errors> Errors:Set => Errors SetItem(error(Msg, CabsLoc(File, Line, Column, .K, .K))) </previous-errors>
          requires notBool isCSV andBool notBool error(Msg, CabsLoc(File, Line, Column, .K, .K)) in Errors andBool (notBool SysHead orBool warnSystemHeaders)
     rule <k> EXIT(Msg:ErrorMsg)
          => doError(Msg, "<unknown>")
          ~> HALT ...</k>
          <curr-eval-context> eval </curr-eval-context>
          <curr-program-loc> UnknownCabsLoc </curr-program-loc>
          <result-value> _ => 1 </result-value>
          <previous-errors> Errors:Set => Errors SetItem(error(Msg, UnknownCabsLoc)) </previous-errors>
          requires notBool isCSV andBool notBool error(Msg, UnknownCabsLoc) in Errors

     rule <k> EXIT(Msg:ErrorMsg) => HALT ...</k>
          <curr-eval-context> eval </curr-eval-context>
          <curr-program-loc> C:CabsLoc </curr-program-loc>
          <result-value> _ => 1 </result-value>
          <previous-errors> Errors:Set </previous-errors>
          requires notBool isCSV andBool error(Msg, stripCabsLoc(C)) in Errors

     syntax CabsLoc ::= stripCabsLoc(CabsLoc) [function]
     rule stripCabsLoc(CabsLoc(File:String, Line:Int, Column:Int, _, _)) => CabsLoc(File, Line, Column, .K, .K)
     rule stripCabsLoc(C:CabsLoc) => C [owise]

     rule <k> EXIT(Msg:ErrorMsg)
          => openWriteThenClose(Report, formatErrorMsg(Msg, formatLocation(File, Line, Column), true) +String "\r\n")
          ~> HALT ...</k>
          <curr-eval-context> eval </curr-eval-context>
          <curr-program-loc>
               CabsLoc(File:String, Line:Int, Column:Int, _, SysHead:Bool)
          </curr-program-loc>
          <result-value> _ => 1 </result-value>
          <options>... SetItem(CSV(Report:String)) ...</options>
          requires notBool SysHead orBool warnSystemHeaders
     rule <k> EXIT(Msg:ErrorMsg)
          => openWriteThenClose(Report, formatErrorMsg(Msg, "unknown", true) +String "\r\n")
          ~> HALT ...</k>
          <curr-eval-context> eval </curr-eval-context>
          <curr-program-loc> UnknownCabsLoc </curr-program-loc>
          <result-value> _ => 1 </result-value>
          <options>... SetItem(CSV(Report:String)) ...</options>

endmodule
