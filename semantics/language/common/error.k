module C-ERROR-SYNTAX
     syntax K ::= ERROR(String, String)
     syntax K ::= ERROR(String, String, KList)
endmodule

module C-ERROR
     imports C-ERROR-SYNTAX
     imports C-ERROR-MAP-SYNTAX
     imports C-CONSTRAINT-MAP-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-TYPING-MISC-SYNTAX
     imports C-SYMLOC-SYNTAX

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

     // See C-EXPRESSION-IDENTIFIER.
     rule [err00021a]:
          <k> 
               (. => ERROR("00021a", "Trying to look up identifier " 
               +String S +String 
               ", but no such identifier is in scope.", 
               (305,, 332)) ) ~>
               Identifier(S:String)
          ...</k>
          <env> Env:Map </env>
          <types> Types:Map </types>
          when (notBool $hasMapping(Env, Identifier(S)))
               andBool (notBool $hasMapping(Types, Identifier(S)))
          [structural, large]
     rule [err00021b]:
          <k> 
               (. => ERROR("00021b", "No definition found for identifier " 
               +String S +String ".") ) ~>
               Identifier(S:String)
          ...</k>
          <env> Env:Map </env>
          <types>... Identifier(S) |-> T:Type ...</types>
          when (notBool $hasMapping(Env, Identifier(S)))
               andBool (notBool isFunctionType(T))
          [structural, large]
     
     rule [err00024a]:
          (. => ERROR("00024a", "Bitwise & used on a symbolic address.") ) ~>
          tv(_:SymLoc, _) & _
          [structural, large]
     rule [err00024b]:
          (. => ERROR("00024b", "Bitwise & used on a symbolic address.") ) ~>
          _ & tv(_:SymLoc, _)
          [structural, large]
     rule [err00024c]:
          (. => ERROR("00024c", "Bitwise & used on a float.") ) ~>
          tv(_:Float, _) & _
          [structural, large]
     rule [err00024d]:
          (. => ERROR("00024d", "Bitwise & used on a float.") ) ~>
          _ & tv(_:Float, _)
          [structural, large]
          
     rule [err00030]:
          (. => ERROR("00030", "Cannot compare pointers with different base objects using '<'.") ) ~>
          tv(loc(Base:SymBase, _:Int, _:Int), T:Type) < tv(loc(Base':SymBase, _:Int, _:Int), T:Type)
          when Base =/=K Base'
          [structural, large]
     rule [err00031]:
          (. => ERROR("00031", "Cannot compare pointers with different base objects using '>'.") ) ~>
          tv(loc(Base:SymBase, _:Int, _:Int), T:Type) > tv(loc(Base':SymBase, _:Int, _:Int), T:Type)
          when Base =/=K Base'
          [structural, large]
     rule [err00032]:
          (. => ERROR("00032", "Cannot compare pointers with different base objects using '<='.") ) ~>
          tv(loc(Base:SymBase, _:Int, _:Int), T:Type) <= tv(loc(Base':SymBase, _:Int, _:Int), T:Type)
          when Base =/=K Base'
          [structural, large]
     rule [err00033]:
          (. => ERROR("00033", "Cannot compare pointers with different base objects using '>='.", 53) ) ~>
          tv(loc(Base:SymBase, _:Int, _:Int), T:Type) >= tv(loc(Base':SymBase, _:Int, _:Int), T:Type)
          when Base =/=K Base'
          [structural, large]

     rule [err00038]:
          (. => ERROR("00038", "Arrays cannot be of 0 length.", cv("6.7.6.2:1"))) ~>
          ArrayType(_:Type, tv(0, _), _)
          [structural, large]
     
     rule [err00039]:
          (. => ERROR("00039", "Unions cannot be empty.", 61) ) ~>
          addUnion(_:Id, .KList)
          [structural, large]
     rule [err00040]:
          (. => ERROR("00040", "Structs cannot be empty.", 61) ) ~>
          addStruct(_:Id, .KList)
          [structural, large]
endmodule
