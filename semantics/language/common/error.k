module C-ERROR-SYNTAX
     syntax K ::= ERROR(String, String)
     syntax K ::= ERROR(String, String, KList)
     syntax K ::= ERROR(String, String, String, String)

     // Error code, desc., C11 citation.
     syntax K ::= UNDEF(String, String, String)
     syntax K ::= UNSPEC(String, String, String)
     syntax K ::= CV(String, String, String)
     syntax K ::= CVUB(String, String, String)

     syntax KResult ::= Bool
     syntax K ::= Error
     syntax K ::= assert(K, Error) [strict(1)]

     syntax K ::= EXIT(String)
endmodule

module C-ERROR
     imports C-ERROR-SYNTAX
     imports C-ERROR-MAP-SYNTAX
     imports C-CONSTRAINT-MAP-SYNTAX

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
          [structural, large]
     rule [err00012]:
          (. => ERROR("00012", "Directly comparing an integer type with a pointer type.") ) ~>
          tv(_, T:Type) <= tv(_, T':Type)
          when (hasIntegerType(T) andBool isPointerType(T'))
               orBool (isPointerType(T) andBool hasIntegerType(T'))
          [structural, large] 
     rule [err00013]:
          (. => ERROR("00013", "Directly comparing an integer type with a pointer type.") ) ~>
          tv(_, T:Type) > tv(_, T':Type)
          when (hasIntegerType(T) andBool isPointerType(T'))
               orBool (isPointerType(T) andBool hasIntegerType(T'))
          [structural, large] 
     rule [err00014]:
          (. => ERROR("00014", "Directly comparing an integer type with a pointer type.") ) ~>
          tv(_, T:Type) >= tv(_, T':Type)
          when (hasIntegerType(T) andBool isPointerType(T'))
               orBool (isPointerType(T) andBool hasIntegerType(T'))
          [structural, large] 

     rule [err00015]:
          (. => ERROR("00015", "Signed overflow.", 36) ) ~>
          arithInterpret(T:Type, I:Int)
          when hasSignedIntegerType(T)
               andBool notBool ((min(T) <=Int I:Int) andBool (max(T) >=Int I:Int))
          [structural, large]      
          
     rule [err00017]:
          (. => ERROR("00017", "Division by 0.", 319) ) ~>
          tv(_, T:Type) / tv(0, T:Type)
          when hasIntegerType(T) andBool isPromoted(T)
          [structural, large]
     
     rule [err00018]:
          (. => ERROR("00018", "Modulus by 0.", 320) ) ~>
          tv(_, T:Type) % tv(0, T:Type)
          when hasIntegerType(T) andBool isPromoted(T)
          [structural, large]
          
     rule [err00019]:
          (. => ERROR("00019", "Signed overflow.", 36) ) ~>
          tv(I1:Int, T:Type) % tv(I2:Int, T:Type)
          when hasIntegerType(T)
               andBool notBool (min(T) <=Int I1 /Int I2
                    andBool max(T) >=Int I1 /Int I2)
               andBool isPromoted(T)
               andBool I2 =/=Int 0
          [structural, large]

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
          [structural, large]
     rule [err00021b]:
          <k> (. => ERROR("00021b", "No definition found for identifier " 
               +String S +String ".") ) ~>
               Identifier(S:String)
          ...</k>
          <env> Env:Map </env>
          <types>... Identifier(S) |-> T:Type ...</types>
          when (notBool Identifier(S) in keys(Env))
               andBool (notBool isFunctionType(T))
          [structural, large]
     
     rule [err00024a]:
          (. => ERROR("00024a", "Bitwise & used on a pointer type.") ) ~>
          tv(_, T:Type) & _
          when isPointerType(T)
          [structural, large]
     rule [err00024b]:
          (. => ERROR("00024b", "Bitwise & used on a pointer type.") ) ~>
          _ & tv(_, T:Type)
          when isPointerType(T)
          [structural, large]
     rule [err00024c]:
          (. => ERROR("00024c", "Bitwise & used on a float.") ) ~>
          tv(_:Float, _) & _
          [structural, large]
     rule [err00024d]:
          (. => ERROR("00024d", "Bitwise & used on a float.") ) ~>
          _ & tv(_:Float, _)
          [structural, large]

     rule [err00024a]:
          (. => ERROR("00025a", "Bitwise | used on a pointer type.") ) ~>
          tv(_, T:Type) | _
          when isPointerType(T)
          [structural, large]
     rule [err00024b]:
          (. => ERROR("00025b", "Bitwise | used on a pointer type.") ) ~>
          _ | tv(_, T:Type)
          when isPointerType(T)
          [structural, large]
     rule [err00024c]:
          (. => ERROR("00025c", "Bitwise | used on a float.") ) ~>
          tv(_:Float, _) | _
          [structural, large]
     rule [err00024d]:
          (. => ERROR("00025d", "Bitwise | used on a float.") ) ~>
          _ | tv(_:Float, _)
          [structural, large]
          
     rule [err00030]:
          (. => ERROR("00030", "Cannot compare pointers with different base objects using '<'.") ) ~>
          tv(loc(Base:SymBase, _, _), T:Type) < tv(loc(Base':SymBase, _, _), T:Type)
          when Base =/=K Base'
          [structural, large]
     rule [err00031]:
          (. => ERROR("00031", "Cannot compare pointers with different base objects using '>'.") ) ~>
          tv(loc(Base:SymBase, _, _), T:Type) > tv(loc(Base':SymBase, _, _), T:Type)
          when Base =/=K Base'
          [structural, large]
     rule [err00032]:
          (. => ERROR("00032", "Cannot compare pointers with different base objects using '<='.") ) ~>
          tv(loc(Base:SymBase, _, _), T:Type) <= tv(loc(Base':SymBase, _, _), T:Type)
          when Base =/=K Base'
          [structural, large]
     rule [err00033]:
          (. => ERROR("00033", "Cannot compare pointers with different base objects using '>='.", 53) ) ~>
          tv(loc(Base:SymBase, _, _), T:Type) >= tv(loc(Base':SymBase, _, _), T:Type)
          when Base =/=K Base'
          [structural, large]

     rule [err00035]:
          (. => CV("00035", "Trying to write through a const lvalue.", "6.5.16.1:1") ) ~>
          write(_, _, T:Type)
          when isConstType(T)
          [structural, large]

     rule [err00038a]:
          (. => CV("00038", "Arrays must have positive length.", "6.7.6.2:1")) ~>
          ArrayType(_, tv(Len:Int, _), _)
          when Len <=Int 0
          [structural, large]
     
     rule [err00039]:
          (. => ERROR("00039", "Unions cannot be empty.", 61) ) ~>
          StructDef(_, krlist(.List))
          [structural, large]
     rule [err00040]:
          (. => ERROR("00040", "Structs cannot be empty.", 61) ) ~>
          UnionDef(_, krlist(.List))
          [structural, large]
endmodule
