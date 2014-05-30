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

     rule [err00011]:
          (. => ERROR("00011", "Directly comparing an integer type with a pointer type.") ) ~>
          tv(_, T:Type) < tv(_, T':Type)
          when (hasIntegerType(T) andBool isPointerType(T'))
               orBool (isPointerType(T) andBool hasIntegerType(T'))
          [structural]
     rule [err00012]:
          (. => ERROR("00012", "Directly comparing an integer type with a pointer type.") ) ~>
          tv(_, T:Type) <= tv(_, T':Type)
          when (hasIntegerType(T) andBool isPointerType(T'))
               orBool (isPointerType(T) andBool hasIntegerType(T'))
          [structural] 
     rule [err00013]:
          (. => ERROR("00013", "Directly comparing an integer type with a pointer type.") ) ~>
          tv(_, T:Type) > tv(_, T':Type)
          when (hasIntegerType(T) andBool isPointerType(T'))
               orBool (isPointerType(T) andBool hasIntegerType(T'))
          [structural] 
     rule [err00014]:
          (. => ERROR("00014", "Directly comparing an integer type with a pointer type.") ) ~>
          tv(_, T:Type) >= tv(_, T':Type)
          when (hasIntegerType(T) andBool isPointerType(T'))
               orBool (isPointerType(T) andBool hasIntegerType(T'))
          [structural] 

     rule [err00015]:
          (. => ERROR("00015", "Signed overflow.", 36) ) ~>
          arithInterpret(T:Type, I:Int)
          when hasSignedIntegerType(T)
               andBool notBool ((min(T) <=Int I:Int) andBool (max(T) >=Int I:Int))
          [structural]      
          
     rule [err00017]:
          (. => ERROR("00017", "Division by 0.", 319) ) ~>
          tv(_, T:Type) / tv(0, T:Type)
          when hasIntegerType(T) andBool isPromoted(T)
          [structural]
     
     rule [err00018]:
          (. => ERROR("00018", "Modulus by 0.", 320) ) ~>
          tv(_, T:Type) % tv(0, T:Type)
          when hasIntegerType(T) andBool isPromoted(T)
          [structural]
          
     rule [err00019]:
          (. => ERROR("00019", "Signed overflow.", 36) ) ~>
          tv(I1:Int, T:Type) % tv(I2:Int, T:Type)
          when hasIntegerType(T)
               andBool notBool (min(T) <=Int I1 /Int I2
                    andBool max(T) >=Int I1 /Int I2)
               andBool isPromoted(T)
               andBool I2 =/=Int 0
          [structural]

     // See C-COMMON-EXPR-IDENTIFIER.
     rule [err00021a]:
          <k> (. => ERROR("00021a", "Trying to look up identifier " 
               +String S +String 
               ", but no such identifier is in scope.", 
               (305,, 332)) ) ~>
               Identifier(S:String)
          ...</k>
          <env> Env:Map </env>
          <types> Types:Map </types>
          when (notBool Identifier(S) in keys(Env))
               andBool (notBool Identifier(S) in keys(Types))
          [structural]
     rule [err00021b]:
          <k> (. => ERROR("00021b", "No definition found for identifier " 
               +String S +String ".") ) ~>
               Identifier(S:String)
          ...</k>
          <env> Env:Map </env>
          <types>... Identifier(S) |-> T:Type ...</types>
          when (notBool Identifier(S) in keys(Env))
               andBool (notBool isFunctionType(T))
          [structural]
          
     rule [err00030]:
          (. => ERROR("00030", "Cannot compare pointers with different base objects using '<'.") ) ~>
          tv(loc(Base:SymBase, _), T:Type) < tv(loc(Base':SymBase, _), T:Type)
          when Base =/=K Base'
          [structural]
     rule [err00031]:
          (. => ERROR("00031", "Cannot compare pointers with different base objects using '>'.") ) ~>
          tv(loc(Base:SymBase, _), T:Type) > tv(loc(Base':SymBase, _), T:Type)
          when Base =/=K Base'
          [structural]
     rule [err00032]:
          (. => ERROR("00032", "Cannot compare pointers with different base objects using '<='.") ) ~>
          tv(loc(Base:SymBase, _), T:Type) <= tv(loc(Base':SymBase, _), T:Type)
          when Base =/=K Base'
          [structural]
     rule [err00033]:
          (. => ERROR("00033", "Cannot compare pointers with different base objects using '>='.", 53) ) ~>
          tv(loc(Base:SymBase, _), T:Type) >= tv(loc(Base':SymBase, _), T:Type)
          when Base =/=K Base'
          [structural]

     rule [err00038a]:
          (. => CV("00038", "Arrays must have positive length.", "6.7.6.2:1")) ~>
          ArrayType(_, tv(Len:Int, _), _)
          when Len <=Int 0
          [structural]
     
     rule [err00039]:
          (. => ERROR("00039", "Unions cannot be empty.", 61) ) ~>
          StructDef(_, krlist(.List))
          [structural]
     rule [err00040]:
          (. => ERROR("00040", "Structs cannot be empty.", 61) ) ~>
          UnionDef(_, krlist(.List))
          [structural]
endmodule
