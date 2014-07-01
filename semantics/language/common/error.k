module C-ERROR-SYNTAX
     // Deprecated...
     syntax KItem ::= ERROR(String, String)
     syntax KItem ::= ERROR(String, String, KList)
     syntax KItem ::= ERROR(String, String, String, String)

     // Error code, desc., C11 citation.
     syntax KItem ::= UNDEF(String, String, String)
     syntax KItem ::= UNSPEC(String, String, String)
     syntax KItem ::= CV(String, String, String)
     syntax KItem ::= CVUB(String, String, String)

     syntax KResult ::= Bool
     syntax Error ::= "errorDummy"
     syntax KItem ::= assert(K, Error) [strict(1)]

     syntax KItem ::= EXIT(String)
endmodule

module C-ERROR
     imports C-ERROR-SYNTAX

     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX

     imports COMPAT-SYNTAX

     rule assert(true, _) => .
     rule assert(A:KResult, K:K) => K
          when A =/=K true

     syntax String ::= ErrorMsg(String, String, String, KList) [function]
     rule ErrorMsg(Title:String, Msg:String, ErrType:String, Citation:String)  => 
          "Error: " 
          +String Title
          +String "\n"
          +String "Description: " 
          +String Msg
          +String "\n"
          +String "Type: " 
          +String ErrType
          +String "\n"
          +String "Citation: " 
          +String Citation

     syntax ErrorRef ::= Int

     rule ERROR(Title:String, Msg:String)
          => EXIT(ErrorMsg(Title, Msg, "", ""))
     rule ERROR(Title:String, Msg:String, _:KList)
          => EXIT(ErrorMsg(Title, Msg, "", ""))

     rule UNDEF(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg(Title, Msg, "Undefined behavior.", Citation))
     rule UNSPEC(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg(Title, Msg, "Unspecified value or behavior.", Citation))
     rule CV(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg(Title, Msg, "Constraint violation.", Citation))
     rule CVUB(Title:String, Msg:String, Citation:String)
          => EXIT(ErrorMsg(Title, Msg, "Constraint violation or undefined behavior.", Citation))
          
     // See C-COMMON-EXPR-IDENTIFIER.
     rule <k> (. => ERROR("00021a", "Trying to look up identifier " 
               +String S +String 
               ", but no such identifier is in scope.", 
               (305,, 332)) ) ~>
               Identifier(S:String)
          ...</k>
          <env> Env:Map </env>
          <types> Types:Map </types>
          when (notBool (Identifier(S:String) in keys(Env)))
               andBool (notBool (Identifier(S:String) in keys(Types)))
          [structural]
     rule <k> (. => ERROR("00021b", "No definition found for identifier " 
               +String S +String ".") ) ~>
               Identifier(S:String)
          ...</k>
          <env> Env:Map </env>
          <types>... Identifier(S) |-> T:Type ...</types>
          when (notBool (Identifier(S) in keys(Env)))
               andBool (notBool isFunctionType(T))
          [structural]

endmodule
