module C11-ERROR
     imports C11-ERROR-MAP-SYNTAX

     imports C-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-BITS-SYNTAX

     imports C-TYPING-MISC-SYNTAX

     imports C-DECLARATION-SYNTAX
     imports C-DECLARATION-GENERAL-SYNTAX

     imports COMPAT-SYNTAX

     imports DEBUG-SYNTAX

     syntax String ::= Error(String, String, KList) [function]
     rule Error(Title:String, Msg:String, _:KList)  => 
          "Error: " 
          +String Title
          +String "\n"
          +String "Description: " 
          +String Msg
     //     +String citeErrors(Refs)

     syntax String ::= citeError(ErrorRef) [function]
     syntax String ::= citeErrors(KList) [function]

     rule citeError(err(Passage:String, Ref:String)) => 
          "Undefined if (" +String Ref +String "): \"" +String Passage +String "\""
     rule citeErrors((Ref:Int,, Refs:KList)) =>
          "\n" +String citeError(Errors(Ref)) +String citeErrors(Refs)
     rule citeErrors(.KList) => ""

     // syntax K ::= ICE(String, String) [function]
     // rule ICE(Title:String, Msg:String) =>
     //      Error(Title, Msg)
     //      +String "\nNOTE: Please send a test case exhibiting this bug to celliso2@illnois.edu; it could indicate an internal error in KCC."

     syntax K ::= ERROR(String, String)
     syntax K ::= ERROR(String, String, KList)

     rule ERROR(Title:String, Msg:String) => ERROR(Title, Msg, .KList)
     rule (<k> ERROR(Title:String, Msg:String, Refs:KList) ~> K:K </k> 
          => <finalComputation> K </finalComputation>)
          (.Bag => <errorCell> Error(Title, Msg, Refs) </errorCell>)

     // dynamic exp
     // rule [err00001]: 
     //      (. => ERROR("00001", "Casting empty value to type other than void.", 89)) ~>
     //      cast(t(_, T:K), emptyValue)
     //      when T:K =/=K void
     //      [structural, large]
         
     // rule [err00002]:
     //      (. => ERROR("00002", "Reading outside the bounds of an object.", 
     //           (19,, 43,, 47,, 62)) ) ~>
     //      assert(false, 2)
     //      [structural, large]
     // rule [err00003]:
     //      (. => ERROR("00003", "Unsequenced side effect on scalar object with value computation of same object.", 315) ) ~>
     //      assert(false, 3)
     //      [structural, large]
     // dynamic memory
     // rule [err00007]:
     //      <k> 
     //           (. => ERROR("00007", "Referring to an object outside of its lifetime.",
     //                (9,, 10)) ) ~>
     //           checkValidLoc-aux(loc(B:SymBase, _:Int, _:Int)) 
     //      ...</k>
     //      <mem> M:Map </mem>
     //      when notBool SetItem(B) in (keys M:Map)
     //      [structural, large]
     
     // rule [err00008]:
     //      (. => ERROR("00008", "Reading uninitialized memory.") ) ~>
     //      concretize(t(_, pointerType(_)), dataList((piece(unknown(Len:Int), Len:Int),, _)))
     //      [structural, large]
     // 
     // rule [err00009]:
     //      (. => ERROR("00009", "Reading uninitialized memory.",
     //           21) ) ~>
     //      concretize(T:Type, dataList((piece(unknown(Len:Int), Len:Int),, _)))
     //      when isFloatType(T)
     //      [structural, large]
          
     // rule [err00010]:
     //      <k> 
     //           (. => ERROR("00010", "Found pointer that refers outside the bounds of an object + 1.", 62) ) ~>
     //           checkValidLoc-aux(loc(Base:SymBase, Offset:Int, _:Int)) 
     //      ...</k>
     //      <mem>... Base |-> memblock(Len:Int, _, _) ...</mem>
     //      when Offset:Int >Int Len:Int
     //      [structural, large]
          
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
     // dynamic exp
     // rule [err00015]:
     //      (. => ERROR("00015", "Signed overflow.", 36) ) ~>
     //      arithInterpret(T:Type, I:Int)
     //      when hasSignedIntegerType(T)
     //           andBool notBool ((min(T) <=Int I:Int) andBool (max(T) >=Int I:Int))
     //      [structural, large]      
          
          
     // rule [err00016]:
     //      <k> 
     //           (. => ERROR("00016", "Unsequenced side effect on scalar object with side effect of same object.") ) ~>
     //           writeByte(Loc:SymLoc, _) 
     //      ...</k>
     //      <locsWrittenTo> Locs:Bag </locsWrittenTo>
     //      when BagItem(Loc) in Locs:Bag
     //      [structural, large] 
     //      
     // rule [err00017]:
     //      (. => ERROR("00017", "Division by 0.", 319) ) ~>
     //      tv(_:Int, T:Type) / tv(0, T:Type)
     //      when hasIntegerType(T) andBool isPromoted(T)
     //      [structural, large]
     
     // rule [err00018]:
     //      (. => ERROR("00018", "Modulus by 0.", 320) ) ~>
     //      tv(_:Int, T:Type) % tv(0, T:Type)
     //      when hasIntegerType(T) andBool isPromoted(T)
     //      [structural, large]
     //      
     // rule [err00019]:
     //      (. => ERROR("00019", "Signed overflow.", 36) ) ~>
     //      tv(I1:Int, T:Type) % tv(I2:Int, T:Type)
     //      when hasIntegerType(T)
     //           andBool notBool (min(T) <=Int I1 /Int I2
     //                andBool max(T) >=Int I1 /Int I2)
     //           andBool isPromoted(T)
     //           andBool I2 =/=Int 0
     //      [structural, large]
          
     // rule [err00020]:
     //      <k> 
     //           (. => ERROR("00020", "Tried to write outside the bounds of an object.") ) ~>
     //           writeByte(loc(Base:SymBase, Offset:Int, _:Int), _) 
     //      ...</k>
     //      <mem>... Base |-> memblock(Len:Int, _, _) ...</mem>
     //      when notBool Offset <Int Len
     //      [structural, large] 
          
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
     // dynamic exp     
     // rule [err00022]:
     //      (. => ERROR("00022", "Trying to left-shift a negative signed value.", 52) ) ~>
     //      leftShiftInterpret(T:Type, _:Int, tv(E1:Int, T:Type))
     //      when hasSignedIntegerType(T)
     //           andBool E1 <Int 0
     //      [structural, large]
     //      
     // rule [err00023]:
     //      (. => ERROR("00023", "Trying to left-shift a signed value, but the result is not representable in the result type.", 52) ) ~>
     //      leftShiftInterpret(T:Type, I:Int, tv(_:Int, T:Type))
     //      when hasSignedIntegerType(T)
     //           andBool notBool (I <=Int (2 ^Int absInt(numBits(T))))
     //      [structural, large]
     
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
          
   //   rule [err00025a]:
   //        (. => ERROR("00025a", "Main must return an int.", 4) ) ~>
   //        callMain-aux(t(_, functionType(t(_, T:SimpleType), _:KList)), _:Int, _:Id, _)
   //        when T =/=K int
   //        [structural, large]
   //   rule [err00025b]:
   //        <k> 
   //             (. => ERROR("00025b", "Main must exist.", 4) ) ~>
   //             callMain(_, _)
   //        ...</k>
   //        <mainTU> .K </mainTU>
   //        [structural, large]
   //   rule [err00026]:
   //        (. => ERROR("00026", "If main has arguments, the type of the first argument must be equivalent to \"int\".", 4) ) ~>
   //        callMain-aux(t(_, functionType(t(_, int), (typedDeclaration(t(_, T:SimpleType), _:Id),, _:KList))), _:Int, _:Id, _) 
   //        when T =/=K int andBool T =/=K void
   //        [structural, large]
   //        
   //   syntax Bool ::= #isArgvType(Type) [function]
   //   
   //   rule #isArgvType(t(_, T:SimpleType)) => false
   //        when notBool (
   //             getKLabel(T) ==KLabel 'incompleteArrayType 
   //             orBool getKLabel(T) ==KLabel 'pointerType
   //        )
   //   rule #isArgvType(t(_, incompleteArrayType(t(_, T:SimpleType)))) 
   //        => false
   //        when notBool getKLabel(T) ==KLabel 'pointerType
   //   rule #isArgvType(t(_, incompleteArrayType(t(_, pointerType(t(_, T:SimpleType)))))) 
   //        => false
   //        when T =/=K char
   //   rule #isArgvType(t(_, pointerType(t(_, T:SimpleType)))) 
   //        => false
   //        when notBool getKLabel(T) ==KLabel 'pointerType
   //   rule #isArgvType(t(_, pointerType(t(_, pointerType(t(_, T:SimpleType)))))) 
   //        => false
   //        when T =/=K char
   //   
   //   rule [err00027]:
   //        (. => ERROR("00027", "If main has arguments, the type of the second argument must be equivalent to  char** .") ) ~>
   //        callMain-aux(t(_, functionType(t(_, int), (typedDeclaration(t(_,
   //        int), _:Id),, typedDeclaration(T:Type, _:Id)))), _:Int, _:Id, _) 
   //        when #isArgvType(T) ==K false
   //        [structural, large]
   //   rule [err00028]:
   //        (. => ERROR("00028", "Main can only have zero or two arguments.") ) ~>
   //        callMain-aux(t(_, functionType(t(_, int), (_:Type,, _:Type,, _:Type,, _:KList))), _:Int, _:Id, _) 
   //        [structural, large]
   //   rule [err00029]:
   //        (. => ERROR("00029", "Main can only have zero or two arguments.") ) ~>
   //        callMain-aux(t(_, functionType(t(_, int), (typedDeclaration(t(_, T:SimpleType), _:Id)))), _:Int, _:Id, _)
   //        when T =/=K void
   //        [structural, large]
          
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
          
     // dynamic exp
     // rule [err00034]:
     //      (. => ERROR("00034", "Casting void type to non-void type.", 308) ) ~>
     //      cast(t(_, T:K), skipval)
     //      when (T:K =/=K void)
     //      [structural, large]
          
     // rule [err00035]:
     //      (. => ERROR("00035", "Trying to write through a const lvalue.", 501) ) ~>
     //      write(lv(_:SymLoc, t(SetItem(Const) _, _)), _)
     //      [structural, large]
     // 
     // rule [err00036]:
     //      (. => ERROR("00036", "Trying to dereference a null pointer.") ) ~>
     //      checkDerefLoc(NullPointer)
     //      [structural, large]
     //      
     // rule [err00037]:
     //      (. => ERROR("00037", "Trying to read through a null pointer.") ) ~>
     //      read-aux(NullPointer, _, _)
     //      [structural, large]
          
     rule [err00038]:
          (. => ERROR("00038", "Arrays cannot be of 0 length.", 503) ) ~>
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
     // dynamic exp
     // rule [err00041]:
     //      (. => ERROR("00041", "If one of a conditional expression's branches has void type, the other must also have void type.", 502) ) ~>
     //      types((t(_, void),, t(_, T:K)))
     //      when T:K =/=K void
     //      [structural, large]
     // rule [err00042]:
     //      (. => ERROR("00042", "If one of a conditional expression's branches has void type, the other must also have void type.") ) ~>
     //      types((t(_, T:K),, t(_, void)))
     //      when T:K =/=K void
     //      [structural, large]
     // rule [err00043]:
     //      (. => ERROR("00043", "If one of a conditional expression's branches has struct or union type, the other must have the same type.", 502) ) ~>
     //      types((T:Type,, T':Type))
     //      when (T =/=K T')
     //           andBool (isStructType(T) orBool isUnionType(T))
     //           andBool (isStructType(T') orBool isUnionType(T'))
     //      [structural, large]
          
     // rule [err00044]:
     //      (. => ERROR("00044", "An array subscript is out of range.", (46,, 49)) ) ~>
     //      addToPointer(_:SymLoc, T:Type, I:Int, tv(_:Int, _))
     //      when notBool ifFromArrayInBounds(T, I)
     //      [structural, large]
          
     // rule [err00045]:
     //      <k> 
     //           (. => ERROR("00045", "Trying to modify a string literal or an object declared with const type.", (33,, 64,, 501)) ) ~>
     //           writeByte(loc(Base:SymBase, _, _), _)
     //      ...</k>
     //      <mem>... Base |-> memblock(_, (_ BagItem(mconst)), _) ...</mem>
     //      [structural, large]
          
     // rule [err00046]:
     //      (. => ERROR("00046", "Trying to reinterpret integer bytes as floating bytes.", 37) ) ~>
     //      concretize(T:Type, dataList((piece(N:Int, _:Int),, _)))
     //      when isFloatType(T) andBool (N >=Int 0)
     //      [structural, large]
          
     // rule [err00047]:
     //      <k> 
     //           (. => ERROR("00047", "Trying to modify an object declared with const type.", 64) ) ~>
     //           writeByte(Loc:SymLoc, _)
     //      ...</k>
     //      <notWritable>... Loc |-> _ ...</notWritable>
     //      [structural, large]

     syntax K ::= verifySpecifiers(Id) | verifyCompat(Type, Id)
     syntax K ::= qs(Set) | tup(String, Id)

     // TODO(chathhorn): a lot of this is likely redundant (e.g., "preTypes").
     rule <k> verifyDecl(typedDeclaration(T:Type, X:Id))
          => verifyCompat(T, X) ~> saveSpecifiers(T, X)  ~> verifySpecifiers(X) ...</k>
          when notBool (isStaticType(T) andBool isExternType(T))

     // rule <k> verifyCompat(T:Type, X:Id) => . ...</k>
     //      <currTU> Tu:String </currTU>
     //      <rawTypes> Types:Map (. => tup(Tu, X) |-> qs(SetItem(T))) </rawTypes>
     //      when notBool (tup(Tu, X) in keys Types)
     // rule <k> verifyCompat(T:Type, X:Id) => . ...</k>
     //      <currTU> Tu:String </currTU>
     //      <rawTypes>... tup(Tu, X) |-> qs(_ (. => SetItem(T))) </rawTypes>

     rule <k> verifySpecifiers(X:Id) => . ...</k>
          <currTU> Tu:String </currTU>
          <typeSpecifiers>... tup(Tu, X) |-> qs(Qs:Set) </typeSpecifiers>
          when notBool (SetItem(Static) in Qs andBool SetItem(Extern) in Qs)

     syntax K ::= saveSpecifiers(Type, Id)
     rule <k> saveSpecifiers(T:Type, X:Id) => . ...</k>
          <currTU> Tu:String </currTU>
          <typeSpecifiers> Decls:Map (. => tup(Tu, X) |-> qs(getQualifiers(T))) </typeSpecifiers>
          when notBool (X in keys Decls)
          [structural] 
     rule <k> saveSpecifiers(T:Type, X:Id) => . ...</k>
          <currTU> Tu:String </currTU>
          <typeSpecifiers>...  tup(Tu, X) |-> qs(_ (. => getQualifiers(T))) </typeSpecifiers>
          [structural] 

     rule (. => ERROR("00208a",
               "The declaration of " +String S +String " appears with both"
               +String " static and extern specifiers.", 8)) ~>
          verifyDecl(typedDeclaration(T:Type, Identifier(S:String)))
          when isStaticType(T) andBool isExternType(T)

     rule <k> (. => ERROR("00208b",
               "The declaration of " +String S +String " appears with both"
               +String " static and extern specifiers (at different locations in the same translation unit).", 8)) ~>
               verifySpecifiers(Identifier(S:String))
          ...</k>
          <currTU> Tu:String </currTU>
          <typeSpecifiers>... 
               tup(Tu, Identifier(S)) |-> qs(_ SetItem(Static) SetItem(Extern))
          ...</typeSpecifiers>

     rule <k> verifyCompat(T:Type, X:Id) => . ...</k>
          <currTU> Tu:String </currTU>
          <rawTypes> Types:Map (. => tup(Tu, X) |-> T) </rawTypes>
          when notBool (tup(Tu, X) in keys Types)
     rule <k> verifyCompat(T:Type, X:Id) => . ...</k>
          <currTU> Tu:String </currTU>
          <rawTypes>... tup(Tu, X) |-> (PrevT:Type => T) </rawTypes>
          when isTypeCompatible(unqualifyType(PrevT), unqualifyType(T))

     rule <k> (. => ERROR("002015",
               "Found multiple declarations of " +String S 
               +String " with incompatible types.", 15)) ~>
               verifyCompat(T:Type, Identifier(S:String)) 
          ...</k>
          <currTU> Tu:String </currTU>
          <rawTypes>... tup(Tu, Identifier(S)) |-> PrevT:Type </rawTypes>
          when notBool isTypeCompatible(unqualifyType(PrevT), unqualifyType(T))

endmodule
