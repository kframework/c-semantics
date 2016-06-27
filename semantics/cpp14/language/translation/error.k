module C-ERROR-SYNTAX
     imports LIST
     imports STRING-SYNTAX
     imports ERROR-SYNTAX

     syntax KItem ::= "EXT-UNDEF" "(" String "," String "," String "," String ")"

endmodule

module C-ERROR
     imports C-ERROR-SYNTAX
     imports ERROR-SYNTAX
     imports COMPAT-SYNTAX
     rule EXT-UNDEF(Title:String, Msg:String, Document:String, Citation:String)
          => EXIT(ErrorMsg("UB-" +String Title, Msg, "Undefined behavior.", ListItem(Document) ListItem(Citation)))
          requires checkOptions(Undef(), Title, true)

endmodule
