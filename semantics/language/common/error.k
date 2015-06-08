module C-ERROR-SYNTAX
     imports KAST
     imports STRING-SYNTAX
     // Deprecated...
     syntax KItem ::= ERROR(String, String)
     syntax KItem ::= ERROR(String, String, String, String)

     // Error code, desc., C11 citation.
     syntax KItem ::= UNDEF(String, String, String)
     syntax KItem ::= UNSPEC(String, String, String)
     syntax KItem ::= CV(String, String, String)
     syntax KItem ::= CVUB(String, String, String)

     syntax KResult ::= Bool
     syntax Error ::= "errorDummy"
     syntax KItem ::= assert(K, Error) [strict(1)]

     syntax ErrorExit ::= EXIT(String)

     syntax Bool ::= "isErrorRecovery" [function, hook(C-SEMANTICS:isErrorRecovery), impure]
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

     imports C-CONFIGURATION

     rule assert(true, _) => .K
     rule assert(A:KResult, K::Error) => K
          requires A =/=K true

     syntax KItem ::= EXITFunc(String) [function, hook(C-SEMANTICS:error), impure]

     syntax String ::= ErrorMsg(String, String, String, KList) [function]
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
          => EXITFunc(ErrorMsg(Title, Msg, "", ""))

     rule UNDEF(Title:String, Msg:String, Citation:String)
          => EXITFunc(ErrorMsg(Title, Msg, "Undefined behavior.", Citation))
     rule UNSPEC(Title:String, Msg:String, Citation:String)
          => EXITFunc(ErrorMsg(Title, Msg, "Unspecified value or behavior.", Citation))
     rule CV(Title:String, Msg:String, Citation:String)
          => EXITFunc(ErrorMsg(Title, Msg, "Constraint violation.", Citation))
     rule CVUB(Title:String, Msg:String, Citation:String)
          => EXITFunc(ErrorMsg(Title, Msg, "Constraint violation or undefined behavior.", Citation))

     // defined as a K rule for if the hook is not defined
     rule EXITFunc(S:String) => EXIT(S)
     rule isErrorRecovery => false

     rule <k> (.K => CV("CID1",
               "Trying to look up identifier " +String S +String
               ", but no such identifier is in scope.",
               "6.5.1:2") )
               ~> Identifier(S:String)
          ...</k>
          <env> Env:Map </env>
          <types> Types:Map </types>
          requires (notBool (Identifier(S:String) in keys(Env)))
               andBool (notBool (Identifier(S:String) in keys(Types)))
          [structural]
     rule <k> (.K => UNDEF("CID2",
               "No definition found for identifier " +String S +String ".", "6.3.2.1:1") )
               ~> Identifier(S:String)
          ...</k>
          <env> Env:Map </env>
          <types>... Identifier(S) |-> _ ...</types>
          requires (notBool (Identifier(S) in keys(Env)))
          [structural]

endmodule
