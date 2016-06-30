module TRANSLATION-ERROR
     imports C-ERROR-SYNTAX

     imports C-TYPING-SYNTAX
     imports C-CONFIGURATION

     syntax KItem ::= error(String, CabsLoc)
     rule <k> EXIT(_) => HALT ...</k>
          <curr-program-loc> CabsLoc(_, _, _, _, true) </curr-program-loc>
          requires notBool warnSystemHeaders

     rule <k> EXIT(Msg:String)
          => #write(2, Msg +String "\n")
          ~> #write(2, "File: " +String File
               +String "\nLine: " +String Int2String(Line)
               +String "\n")
          ~> HALT ...</k>
          <curr-eval-context> eval </curr-eval-context>
          <curr-program-loc>
               CabsLoc(File:String, Line:Int, _, _, SysHead:Bool)
          </curr-program-loc>
          <result-value> _ => 1 </result-value>
          <previous-errors> Errors:Set => Errors SetItem(error(Msg, CabsLoc(File, Line, .K, .K, .K))) </previous-errors>
          requires notBool isCSV andBool notBool error(Msg, CabsLoc(File, Line, .K, .K, .K)) in Errors andBool (notBool SysHead orBool warnSystemHeaders)
     rule <k> EXIT(Msg:String)
          => #write(2, Msg +String "\n")
          ~> HALT ...</k>
          <curr-eval-context> eval </curr-eval-context>
          <curr-program-loc> UnknownCabsLoc </curr-program-loc>
          <result-value> _ => 1 </result-value>
          <previous-errors> Errors:Set => Errors SetItem(error(Msg, UnknownCabsLoc)) </previous-errors>
          requires notBool isCSV andBool notBool error(Msg, UnknownCabsLoc) in Errors

     rule <k> EXIT(Msg:String) => HALT ...</k>
          <curr-eval-context> eval </curr-eval-context>
          <curr-program-loc> C:CabsLoc </curr-program-loc>
          <result-value> _ => 1 </result-value>
          <previous-errors> Errors:Set </previous-errors>
          requires notBool isCSV andBool error(Msg, stripColumns(C)) in Errors

     syntax CabsLoc ::= stripColumns(CabsLoc) [function]
     rule stripColumns(CabsLoc(File:String, Line:Int, _, _, _)) => CabsLoc(File, Line, .K, .K, .K)
     rule stripColumns(C:CabsLoc) => C [owise]

     rule <k> EXIT(Msg:String)
          => openWriteThenClose(Report, Msg +String "," +String File +String ":" +String Int2String(Line) +String "\r\n")
          ~> HALT ...</k>
          <curr-eval-context> eval </curr-eval-context>
          <curr-program-loc>
               CabsLoc(File:String, Line:Int, _, _, SysHead:Bool)
          </curr-program-loc>
          <result-value> _ => 1 </result-value>
          <options>... SetItem(CSV(Report:String)) ...</options>
          requires notBool SysHead orBool warnSystemHeaders
     rule <k> EXIT(Msg:String)
          => openWriteThenClose(Report, Msg +String ",unknown\r\n")
          ~> HALT ...</k>
          <curr-eval-context> eval </curr-eval-context>
          <curr-program-loc> UnknownCabsLoc </curr-program-loc>
          <result-value> _ => 1 </result-value>
          <options>... SetItem(CSV(Report:String)) ...</options>

endmodule
