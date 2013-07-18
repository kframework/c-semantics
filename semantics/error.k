module C11-ERROR-SYNTAX
     syntax K ::= assert(Bool, Int) // check, error#
     syntax K ::= "PAUSE" | PAUSE(K) | ASSERT(Bool, K)
endmodule

module C11-ERROR
     imports C11-ERROR-SYNTAX

     imports C-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-MEMORY-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-EXPRESSION-SYNTAX
     imports C-BITS-SYNTAX

     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-TYPING-MISC-SYNTAX
     imports C-EXPRESSION-CONDITIONAL-SYNTAX
     imports C-EXPRESSION-BITWISE-SYNTAX
     imports C-EXPRESSION-CONVERSION-SYNTAX
     imports C-EXPRESSION-ADDITIVE-OPERATORS-SYNTAX

     imports COMPAT-SYNTAX

     imports LIBC-STDIO-SYNTAX

     rule assert(true, _) => . [structural, anywhere]
     rule ASSERT(true, _) => . [structural, anywhere]

     syntax K ::= Error(String, String) [function]
     rule Error(Title:String, Msg:String)  => 
          "Error: " 
          +String Title
          +String "\n"
          +String "Description: " 
          +String Msg
     syntax K ::= ICE(String, String) [function]
     rule ICE(Title:String, Msg:String) =>
          Error(Title, Msg)
          +String "\nNOTE: Please send a test case exhibiting this bug to celliso2@illnois.edu; it could indicate an internal error in KCC."

     syntax K ::= ERROR(String, String)

     rule (<k> ERROR(Title:String, Msg:String) ~> K:K </k> 
          => <finalComputation> K </finalComputation>)
          (.Bag => <errorCell> Error(Title, Msg) </errorCell>)

     rule [err00001]: 
          (. => ERROR("00001", "Casting empty value to type other than void.")) ~>
          cast(t(_, T:K), emptyValue)
          when T:K =/=K void
          [structural, large]
         
     rule [err00002]:
          (. => ERROR("00002", "Reading outside the bounds of an object.") ) ~>
          assert(false, 2)
          [structural, large]
     rule [err00003]:
          (. => ERROR("00003", "Unsequenced side effect on scalar object with value computation of same object.") ) ~>
          assert(false, 3)
          [structural, large]

    //  rule [err00005]:
    //       <k> 
    //            (. => ICE("00005", "Referring to an object outside of its lifetime.") ) ~>
    //            extractByteFromMem(loc(B:SymBase, _:Int, _:Int)) 
    //       ...</k>
    //       <mem> M:Map </mem>
    //       when notBool SetItem(B) in keys (M:Map)
    //       [structural, large]
     
     rule [err00006]:
          (. => ERROR("00006", "Reading unspecified (possibly uninitialized) memory, or trying to read a pointer or float through an integer type.") ) ~>
          joinIntegerBytes-aux(T:KResult, (_:KList,, piece(unknown(Len:Int), Len:Int)), _:K)
          when notBool isCharType(T:KResult)
          [structural, large]
          
     rule [err00007]:
          <k> 
               (. => ERROR("00007", "Referring to an object outside of its lifetime.") ) ~>
               checkValidLoc-aux(loc(B:SymBase, _:Int, _:Int)) 
          ...</k>
          <mem> M:Map </mem>
          when notBool SetItem(B) in (keys M:Map)
          [structural, large]
     
     rule [err00008]:
          (. => ERROR("00008", "Reading uninitialized memory.") ) ~>
          concretize(t(_, pointerType(_)), dataList((piece(unknown(Len:Int), Len:Int),, _)))
          [structural, large]
     
     rule [err00009]:
          (. => ERROR("00009", "Reading uninitialized memory.") ) ~>
          concretize(T:KResult, dataList((piece(unknown(Len:Int), Len:Int),, _)))
          when isFloatType(T:KResult)
          [structural, large]
          
     rule [err00010]:
          <k> 
               (. => ERROR("00010", "Found pointer that refers outside the bounds of an object + 1.") ) ~>
               checkValidLoc-aux(loc(Base:SymBase, Offset:Int, _:Int)) 
          ...</k>
          <mem>... Base |-> memblock(Len:Int, _, _) ...</mem>
          when Offset:Int >Int Len:Int
          [structural, large]
          
     rule [err00011]:
          (. => ERROR("00011", "Directly comparing an integer type with a pointer type.") ) ~>
          tv(_, T:KResult) < tv(_, T':KResult)
          when (hasIntegerType(T:KResult) andBool isPointerType(T':KResult))
               orBool (isPointerType(T:KResult) andBool hasIntegerType(T':KResult))
          [structural, large]
     rule [err00012]:
          (. => ERROR("00012", "Directly comparing an integer type with a pointer type.") ) ~>
          tv(_, T:KResult) <= tv(_, T':KResult)
          when (hasIntegerType(T:KResult) andBool isPointerType(T':KResult))
               orBool (isPointerType(T:KResult) andBool hasIntegerType(T':KResult))
          [structural, large] 
     rule [err00013]:
          (. => ERROR("00013", "Directly comparing an integer type with a pointer type.") ) ~>
          tv(_, T:KResult) > tv(_, T':KResult)
          when (hasIntegerType(T:KResult) andBool isPointerType(T':KResult))
          orBool (isPointerType(T:KResult) andBool hasIntegerType(T':KResult))
          [structural, large] 
     rule [err00014]:
          (. => ERROR("00014", "Directly comparing an integer type with a pointer type.") ) ~>
          tv(_, T:KResult) >= tv(_, T':KResult)
          when (hasIntegerType(T:KResult) andBool isPointerType(T':KResult))
          orBool (isPointerType(T:KResult) andBool hasIntegerType(T':KResult))
          [structural, large] 
          
     rule [err00015]:
          (. => ERROR("00015", "Signed overflow.") ) ~>
          arithInterpret(T:Type, I:Int)
          when hasSignedIntegerType(T)
          andBool notBool ((min(T) <=Int I:Int) andBool (max(T) >=Int I:Int))
          [structural, large]      
          
          
     rule [err00016]:
          <k> 
               (. => ERROR("00016", "Unsequenced side effect on scalar object with side effect of same object.") ) ~>
               writeByte(Loc:SymLoc, _) 
          ...</k>
          <locsWrittenTo> Locs:Bag </locsWrittenTo>
          when BagItem(Loc) in Locs:Bag
          [structural, large] 
          
     rule [err00017]:
          (. => ERROR("00017", "Division by 0.") ) ~>
          tv(_:Int, T:KResult) / tv(0, T:KResult)
          when hasIntegerType(T:KResult)
          andBool isPromoted(T:KResult)
          [structural, large]
     
     rule [err00018]:
          (. => ERROR("00018", "Modulus by 0.") ) ~>
          tv(_:Int, T:KResult) % tv(0, T:KResult)
          when hasIntegerType(T:KResult)
          andBool isPromoted(T:KResult)
          [structural, large]
          
     rule [err00019]:
          (. => ERROR("00019", "Signed overflow.") ) ~>
          tv(I1:Int, T:KResult) % tv(I2:Int, T:KResult)
          when hasIntegerType(T:KResult)
          andBool notBool (min(T:KResult) <=Int I1:Int /Int I2:Int andBool max(T:KResult) >=Int I1:Int /Int I2:Int)
          andBool isPromoted(T:KResult)
          andBool I2:Int =/=Int 0
          [structural, large]
          
     rule [err00020]:
          <k> 
               (. => ERROR("00020", "Tried to write outside the bounds of an object.") ) ~>
               writeByte(loc(Base:SymBase, Offset:Int, _:Int), _) 
          ...</k>
          <mem>... Base |-> memblock(Len:Int, _, _) ...</mem>
          when notBool Offset:Int <Int Len:Int
          [structural, large] 
          
     // See C-EXPRESSION-IDENTIFIER.
     rule [err00021a]:
          <k> 
               (. => ERROR("00021a", "Trying to look up identifier " +String S:String +String ", but no such identifier is in scope.") ) ~>
               Identifier(S:String)
          ...</k>
          <env> Env:Map </env>
          <types> Types:Map </types>
          when (notBool $hasMapping(Env, Identifier(S)))
               andBool (notBool $hasMapping(Types, Identifier(S)))
          [structural, large]
     rule [err00021b]:
          <k> 
               (. => ERROR("00021b", "Trying to look up identifier " +String S:String +String ", but no such identifier is in scope.") ) ~>
               Identifier(S:String)
          ...</k>
          <env> Env:Map </env>
          <types>... Identifier(S) |-> T:Type ...</types>
          when (notBool $hasMapping(Env, Identifier(S)))
               andBool (notBool isFunctionType(T))
          [structural, large]
          
     rule [err00022]:
          (. => ERROR("00022", "Trying to left-shift a negative signed value.") ) ~>
          leftShiftInterpret(T:KResult, _:Int, tv(E1:Int, T:KResult))
          when hasSignedIntegerType(T)
               andBool E1 <Int 0
          [structural, large]
          
     rule [err00023]:
          (. => ERROR("00023", "Trying to left-shift a signed value, but the result is not representable in the result type.") ) ~>
          leftShiftInterpret(T:KResult, I:Int, tv(_:Int, T:KResult))
          when hasSignedIntegerType(T:KResult)
               andBool notBool (I:Int <=Int (2 ^Int absInt(numBits(T:KResult))))
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
          
     rule [err00025a]:
          (. => ERROR("00025a", "Main must return an int.") ) ~>
          callMain-aux(t(_, functionType(t(_, T:K), _:KList)), _:Int, _:Id, _)
          when T:K =/=K int
          [structural, large]
     rule [err00025b]:
          <k> 
               (. => ERROR("00025b", "Main must exist.") ) ~>
               callMain(_, _)
          ...</k>
          <mainTU> .K </mainTU>
          [structural, large]
     rule [err00026]:
          (. => ERROR("00026", "If main has arguments, the type of the first argument must be equivalent to \"int\".") ) ~>
          callMain-aux(t(_, functionType(t(_, int), (typedDeclaration(t(_, T:K), _:Id),, _:KList))), _:Int, _:Id, _) 
          when T:K =/=K int andBool T:K =/=K void
          [structural, large]
          
     syntax Bool ::= #isArgvType(Type) [function]
     
     rule #isArgvType(t(_, T:SimpleType)) => false
          when notBool (
               getKLabel(T) ==KLabel 'incompleteArrayType 
               orBool getKLabel(T) ==KLabel 'pointerType
          )
     rule #isArgvType(t(_, incompleteArrayType(t(_, T:SimpleType)))) 
          => false
          when notBool getKLabel(T) ==KLabel 'pointerType
     rule #isArgvType(t(_, incompleteArrayType(t(_, pointerType(t(_, T:SimpleType)))))) 
          => false
          when T =/=K char
     rule #isArgvType(t(_, pointerType(t(_, T:SimpleType)))) 
          => false
          when notBool getKLabel(T) ==KLabel 'pointerType
     rule #isArgvType(t(_, pointerType(t(_, pointerType(t(_, T:SimpleType)))))) 
          => false
          when T =/=K char
     
     rule [err00027]:
          (. => ERROR("00027", "If main has arguments, the type of the second argument must be equivalent to  char** .") ) ~>
          callMain-aux(t(_, functionType(t(_, int), (typedDeclaration(t(_,
          int), _:Id),, typedDeclaration(T:Type, _:Id)))), _:Int, _:Id, _) 
          when #isArgvType(T) ==K false
          [structural, large]
     rule [err00028]:
          (. => ERROR("00028", "Main can only have zero or two arguments.") ) ~>
          callMain-aux(t(_, functionType(t(_, int), (_:KResult,, _:KResult,, _:KResult,, _:KList))), _:Int, _:Id, _) 
          [structural, large]
     rule [err00029]:
          (. => ERROR("00029", "Main can only have zero or two arguments.") ) ~>
          callMain-aux(t(_, functionType(t(_, int), (typedDeclaration(t(_, T:K), _:Id)))), _:Int, _:Id, _)
          when T:K =/=K void
          [structural, large]
          
     rule [err00030]:
          (. => ERROR("00030", "Cannot compare pointers with different base objects using '<'.") ) ~>
          tv(loc(Base:SymBase, _:Int, _:Int), T:KResult) < tv(loc(Base':SymBase, _:Int, _:Int), T:KResult)
          when Base =/=K Base'
          [structural, large]
     rule [err00031]:
          (. => ERROR("00031", "Cannot compare pointers with different base objects using '>'.") ) ~>
          tv(loc(Base:SymBase, _:Int, _:Int), T:KResult) > tv(loc(Base':SymBase, _:Int, _:Int), T:KResult)
          when Base =/=K Base'
          [structural, large]
     rule [err00032]:
          (. => ERROR("00032", "Cannot compare pointers with different base objects using '<='.") ) ~>
          tv(loc(Base:SymBase, _:Int, _:Int), T:KResult) <= tv(loc(Base':SymBase, _:Int, _:Int), T:KResult)
          when Base =/=K Base'
          [structural, large]
     rule [err00033]:
          (. => ERROR("00033", "Cannot compare pointers with different base objects using '>='.") ) ~>
          tv(loc(Base:SymBase, _:Int, _:Int), T:KResult) >= tv(loc(Base':SymBase, _:Int, _:Int), T:KResult)
          when Base =/=K Base'
          [structural, large]
          
     rule [err00034]:
          (. => ERROR("00034", "Casting void type to non-void type.") ) ~>
          cast(t(_, T:K), skipval)
          when (T:K =/=K void)
          [structural, large]
          
     rule [err00035]:
          (. => ERROR("00035", "Trying to write through a const lvalue.") ) ~>
          write(lv(_:SymLoc, t(SetItem(Const) _, _)), _)
          [structural, large]
     
     rule [err00036]:
          (. => ERROR("00036", "Trying to dereference a null pointer.") ) ~>
          checkDerefLoc(NullPointer)
          [structural, large]
          
     rule [err00037]:
          (. => ERROR("00037", "Trying to read through a null pointer.") ) ~>
          read-aux(NullPointer, _, _)
          [structural, large]
          
     rule [err00038]:
          (. => ERROR("00038", "Arrays cannot be of 0 length.") ) ~>
          ArrayType(_:KResult, tv(0, _), _)
          [structural, large]
     
     rule [err00039]:
          (. => ERROR("00039", "Unions cannot be empty.") ) ~>
          addUnion(_:Id, .KList)
          [structural, large]
     rule [err00040]:
          (. => ERROR("00040", "Structs cannot be empty.") ) ~>
          addStruct(_:Id, .KList)
          [structural, large]
          
     rule [err00041]:
          (. => ERROR("00041", "If one of a conditional expression's branches has void type, the other must also have void type.") ) ~>
          types((t(_, void),, t(_, T:K)))
          when T:K =/=K void
          [structural, large]
     rule [err00042]:
          (. => ERROR("00042", "If one of a conditional expression's branches has void type, the other must also have void type.") ) ~>
          types((t(_, T:K),, t(_, void)))
          when T:K =/=K void
          [structural, large]
     rule [err00043]:
          (. => ERROR("00043", "If one of a conditional expression's branches has struct or union type, the other must have the same type.") ) ~>
          types((T1:KResult,, T2:KResult))
          when (T1:KResult =/=K T2:KResult)
               andBool (isStructType(T1:KResult) orBool isUnionType(T1:KResult))
               andBool (isStructType(T2:KResult) orBool isUnionType(T2:KResult))
          [structural, large]
          
     rule [err00044]:
          (. => ERROR("00044", "An array subscript is out of range.") ) ~>
          addToPointer(_:SymLoc, T:KResult, I:Int, tv(_:Int, _))
          when notBool ifFromArrayInBounds(T:KResult, I:Int)
          [structural, large]
          
     rule [err00045]:
          <k> 
               (. => ERROR("00045", "Trying to modify a string literal or an object declared with const type.") ) ~>
               writeByte(loc(Base:SymBase, _, _), _)
          ...</k>
          <mem>... Base |-> memblock(_, (_ BagItem(mconst)), _) ...</mem>
          [structural, large]
          
     rule [err00046]:
          (. => ERROR("00046", "Trying to reinterpret integer bytes as floating bytes.") ) ~>
          concretize(T:KResult, dataList((piece(N:Int, _:Int),, _)))
          when isFloatType(T:KResult) andBool (N >=Int 0)
          [structural, large]
          
     rule [err00047]:
          <k> 
               (. => ERROR("00047", "Trying to modify an object declared with const type.") ) ~>
               writeByte(Loc:SymLoc, _)
          ...</k>
          <notWritable>... Loc |-> _ ...</notWritable>
          [structural, large]

     rule
          (. => ERROR("00500", 
               "printf: Format string expects type of size " +String
               Int2String(value(A)) +String ", but got an argument of size "
               +String Int2String(value(B)) +String ".") ) ~>
          nextvarg-aux(_, _, A:Value, B:Value)
          when value(A) =/=Int value(B)
          [structural, large]
     
     syntax K ::= "datarace" "(" SymLoc "," Int "," SymLoc "," Int ")"

     // TODO(chathhorn): comparing SymLocs, elided. Also, should computation be
     // halted in this case? Should all k cells be frozen? Clearly ERROR
     // doesn't work so well with this.
     // fixme possible to miss dataraces with bitfields
    //  rule [read-write-race]:
    //       <T> 
    //            _ 
    //            <threads> 
    //            (    _
    //                 <thread> _ <k> read-aux(Loc:SymLoc, _, BitSize:Int) ...</k> </thread>
    //                 <thread> _ <k> write-aux(Loc':SymLoc, _, BitSize':Int) ...</k> </thread> => .Bag)
    //            </threads> 
    //       </T>
    //       (. => ERROR("00048", "Have a read-write datarace.")
    //       // ~> datarace(Loc:SymLoc, BitSize:Int, Loc':SymLoc, BitSize':Int) 
    //       )
    //       when (Loc <=Loc Loc' andBool Loc' <Loc (Loc +bytes bitsToBytes(BitSize)))
    //            orBool (Loc >Loc Loc' andBool (Loc' +bytes bitsToBytes(BitSize')) >Loc Loc)
    //       [computational, large]
    //       
    //  rule [write-write-race]:
    //       <T> 
    //            _ 
    //            <threads> 
    //            (    _
    //                 <thread> _ <k> write-aux(Loc:SymLoc, _, BitSize:Int) ...</k> </thread>
    //                 <thread> _ <k> write-aux(Loc':SymLoc, _, BitSize':Int) ...</k> </thread> => .Bag)
    //            </threads> 
    //       </T>
    //       (. => ERROR("00049", "Have a write-write datarace.")
    //       // ~> datarace(Loc:Int, BitSize:Int, Loc':Int, BitSize':Int) 
    //       )
    //       when (Loc <=Loc Loc' andBool Loc' <Loc (Loc +bytes bitsToBytes(BitSize)))
    //            orBool (Loc >Loc Loc' andBool (Loc' +bytes bitsToBytes(BitSize')) >Loc Loc)
    //       [computational, large]        

endmodule
