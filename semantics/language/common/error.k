module C11-ERROR-SYNTAX
     syntax K ::= ERROR(String, String)
     syntax K ::= ERROR(String, String, KList)
endmodule

module C11-ERROR
     imports C11-ERROR-SYNTAX
     imports C11-ERROR-MAP-SYNTAX
     imports C11-CONSTRAINT-MAP-SYNTAX

     syntax String ::= Error(String, String, KList) [function]
     rule Error(Title:String, Msg:String, _:KList)  => 
          "Error: " 
          +String Title
          +String "\n"
          +String "Description: " 
          +String Msg
     //     +String citeErrors(Refs)

     syntax ErrorRef ::= Int

     syntax String ::= citeError(ErrorTxt) [function]
     syntax String ::= citeConstraint(String, String) [function]
     syntax String ::= citeErrors(KList) [function]

     rule citeError(err(Passage:String, Ref:String)) => 
          "Undefined if (" +String Ref +String "): \"" +String Passage +String "\""
     rule citeConstraint(Passage:String, Ref:String) => 
          "Constraint violated (" +String Ref +String "): \"" +String Passage +String "\""

     rule citeErrors((Ref:Int,, Refs:KList)) =>
          "\n" +String citeError(Errors(Ref)) +String citeErrors(Refs)
     rule citeErrors((cv(Ref:String),, Refs:KList)) =>
          "\n" +String citeConstraint(Constraints(Ref), Ref) +String citeErrors(Refs)
     rule citeErrors(.KList) => ""

     rule ERROR(Title:String, Msg:String) => ERROR(Title, Msg, .KList)
     rule (<k> ERROR(Title:String, Msg:String, Refs:KList) ~> K:K </k> 
          => <finalComputation> K </finalComputation>)
          (.Bag => <errorCell> Error(Title, Msg, Refs) </errorCell>)

endmodule
