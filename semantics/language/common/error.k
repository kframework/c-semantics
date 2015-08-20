module C-ERROR-SYNTAX
     imports BASIC-K
     imports STRING-SYNTAX
     imports BOOL-SYNTAX
     // Deprecated...
     syntax KItem ::= ERROR(String, String)
     syntax KItem ::= ERROR(String, String, String, String)

     // Error code, desc., C11 citation.
     syntax KItem ::= UNDEF(String, String, String)
     syntax KItem ::= UNSPEC(String, String, String)
     syntax KItem ::= CV(String, String, String)
     syntax KItem ::= CVUB(String, String, String)

     syntax KResult ::= Bool
     syntax Error
     syntax K ::= assert(Bool, Error)

     syntax KItem ::= EXIT(String)
     syntax ErrorExit

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

     imports C-CONFIGURATION

     rule assert(B, E) => #if B #then .K #else E #fi [macro]

     rule _:ErrorExit ~> _:Error => .K
          requires isErrorRecovery

     syntax String ::= ErrorMsg(String, String, String, String) [function]
     rule ErrorMsg(Title:String, Msg:String, ErrType:String, Citation:String)
          => "Error: "
          +String Title
          +String "\n"
          +String "Description: "
          +String Msg
          +String "\n"
          +String "Type: "
          +String ErrType
          +String "\n"
          +String "See also: C11 sec. "
          +String Citation
          requires Citation =/=String ""
     rule ErrorMsg(Title:String, Msg:String, ErrType:String, Citation:String)
          => "Error: "
          +String Title
          +String "\n"
          +String "Description: "
          +String Msg
          +String "\n"
          +String "Type: "
          +String ErrType
          requires Citation ==String ""

     syntax ErrorRef ::= Int

     rule ERROR(Title:String, Msg:String)
          => EXIT(ErrorMsg(Title, Msg, "", ""))

     rule UNDEF(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg(Title, Msg, "Undefined behavior.", Citation))
     rule UNSPEC(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg(Title, Msg, "Unspecified value or behavior.", Citation))
     rule CV(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg(Title, Msg, "Constraint violation.", Citation))
     rule CVUB(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg(Title, Msg, "Constraint violation or undefined behavior.", Citation))

endmodule
