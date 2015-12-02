module C-TRANSLATION-ERROR
     imports C-ERROR-SYNTAX

     imports C-BITS-SYNTAX
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DECL-GLOBAL-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-EXPR-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-CONFIGURATION

     rule <k> EXIT(Msg:String)
          => #write(2, Msg +String "\n")
          ~> #write(2, "File: " +String File
               +String "\nLine: " +String Int2String(Line)
               +String "\n")
          ~> HALT ...</k>
          <curr-scope> S:Scope </curr-scope>
          <curr-program-loc>
               CabsLoc(File:String, Line:Int, _, _)
          </curr-program-loc>
          <result-value> _ => 1 </result-value>
          requires notBool isCSV andBool S =/=K noEvalScope
     rule <k> EXIT(Msg:String)
          => #write(2, Msg +String "\n")
          ~> HALT ...</k>
          <curr-scope> S:Scope </curr-scope>
          <curr-program-loc> UnknownCabsLoc </curr-program-loc>
          <result-value> _ => 1 </result-value>
          requires notBool isCSV andBool S =/=K noEvalScope

     rule <k> EXIT(Msg:String)
          => openWriteThenClose(Report, Msg +String "," +String File +String ":" +String Int2String(Line) +String "\r\n")
          ~> HALT ...</k>
          <curr-scope> S:Scope </curr-scope>
          <curr-program-loc>
               CabsLoc(File:String, Line:Int, _, _)
          </curr-program-loc>
          <result-value> _ => 1 </result-value>
          <options>... SetItem(CSV(Report:String)) ...</options>
          requires S =/=K noEvalScope
     rule <k> EXIT(Msg:String)
          => openWriteThenClose(Report, Msg +String ",unknown\r\n")
          ~> HALT ...</k>
          <curr-scope> S:Scope </curr-scope>
          <curr-program-loc> UnknownCabsLoc </curr-program-loc>
          <result-value> _ => 1 </result-value>
          <options>... SetItem(CSV(Report:String)) ...</options>
          requires S =/=K noEvalScope

endmodule
