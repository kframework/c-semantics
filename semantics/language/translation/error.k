module C-TRANSLATION-ERROR
     imports C-ERROR-SYNTAX

     imports C-BITS-SYNTAX
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DECL-GLOBAL-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     imports COMPAT-SYNTAX
     imports DEBUG-SYNTAX

     rule <k> EXIT(Msg:String)
          => #write(2, Msg +String "\n")
          ~> #write(2, "File: " +String File
               +String "\nLine: " +String Int2String(Line)
               +String "\n")
          ~> HALT ...</k>
          <curr-program-loc>
               CabsLoc(File:String, Line:Int, _, _)
          </curr-program-loc>
     rule <k> EXIT(Msg:String)
          => #write(2, Msg +String "\n")
          ~> HALT ...</k>
          <curr-program-loc> UnknownCabsLoc </curr-program-loc>

endmodule
