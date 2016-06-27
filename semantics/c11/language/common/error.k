module C-ERROR-SYNTAX
     imports BASIC-K
     imports STRING-SYNTAX
     imports BOOL-SYNTAX
     imports INT-SYNTAX
     imports ERROR-SYNTAX

     // Error code, desc., C11 citation.
     syntax KItem ::= UNDEF(String, String, String)
     syntax KItem ::= UNSPEC(String, String, String)
     syntax KItem ::= CV(String, String, String)
     syntax KItem ::= SE(String, String, String)
     syntax KItem ::= IMPL(String, String, String)
     syntax KItem ::= "EXT-CV" "(" String "," String "," String "," String ")"
     syntax KItem ::= "EXT-UNDEF" "(" String "," String "," String "," String ")"

     syntax KResult ::= Bool
     syntax K ::= assert(Bool, Error)

     syntax String ::= ErrorMsg(String, String, String, String, String) [function, klabel(ErrorMsg5)]

endmodule

module C-ERROR
     imports C-ERROR-SYNTAX

     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports K-REFLECTION
     imports C-CONFIGURATION


     rule ErrorMsg(Title:String, Msg:String, ErrType:String, Document:String, Citation:String)
          => ErrorMsg(Title, Msg, ErrType, ListItem(Document) ListItem(Citation))

     rule UNDEF(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg("UB-" +String Title, Msg, "Undefined behavior.", "C11", Citation))
          requires checkOptions(Undef(), Title, true)
     rule UNSPEC(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg("USP-" +String Title, Msg, "Unspecified value or behavior.", "C11", Citation))
          requires checkOptions(Unspec(), Title, true)
     rule CV(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg("CV-" +String Title, Msg, "Constraint violation.", "C11", Citation))
     rule SE(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg("SE-" +String Title, Msg, "Syntax error.", "C11", Citation))
     rule IMPL(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg("IMPL-" +String Title, Msg, "Implementation defined behavior.", "C11", Citation))
          requires checkOptions(Impl(), Title, true)
     rule EXT-CV(Title:String, Msg:String, Document:String, Citation:String)
          => EXIT(ErrorMsg("CV-" +String Title, Msg, "Constraint violation.", Document, Citation))
     rule EXT-UNDEF(Title:String, Msg:String, Document:String, Citation:String)
          => EXIT(ErrorMsg("UB-" +String Title, Msg, "Undefined behavior.", Document, Citation))
          requires checkOptions(Undef(), Title, true)

     rule UNDEF(Title:String, _, _) => HALT
          requires notBool checkOptions(Undef(), Title, true)
     rule UNSPEC(Title:String, _, _) => HALT
          requires notBool checkOptions(Unspec(), Title, true)
     rule IMPL(Title:String, _, _) => HALT
          requires notBool checkOptions(Impl(), Title, true)
     rule EXT-UNDEF(Title:String, _, _, _) => HALT
          requires notBool checkOptions(Undef(), Title, true)

endmodule
