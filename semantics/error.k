module C-ERROR-SYNTAX

endmodule

module C-ERROR
     imports C-ERROR-SYNTAX
     imports C-SEMANTIC-SYNTAX
     imports C-COMPAT-SYNTAX
     imports C-SETTINGS

     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-TYPING-MISC-SYNTAX
     imports C-EXPRESSION-CONDITIONAL-SYNTAX
     imports C-EXPRESSION-BITWISE-SYNTAX
     imports C-EXPRESSION-ADDITIVE-OPERATORS-SYNTAX

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
          
     syntax K ::= "ERROR"

     rule [err00001]: 
          <k> (. => ERROR) ~> cast(t(_, T:K), emptyValue) ... </k>
          <br/>
          (.Bag => <errorCell> Error("00001", "Casting empty value to type other than void.") </errorCell>)
          when T:K =/=K void
          [structural, large]
         
     rule [err00002]:
          <k> (. => ERROR) ~> assert(false, 2) ...</k>
          <br/>
          (.Bag => <errorCell> Error("00002", "Reading outside the bounds of an object.") </errorCell>)
          [structural, large]
     rule [err00003]:
          <k> (. => ERROR) ~> assert(false, 3) ...</k>
          <br/>
          (.Bag => <errorCell> Error("00003", "Unsequenced side effect on scalar object with value computation of same object.") </errorCell>)
          [structural, large]

      rule [err00005]:
           <k> (. => ERROR) ~> extractByteFromMem(loc(B:SymBase, _:Int, _:Int)) ...</k>
           <br/>
           (.Bag => <errorCell> ICE("00005", "Referring to an object outside of its lifetime.") </errorCell>)
           <mem> M:Map </mem>
           when notBool SetItem(B) in keys (M:Map)
           [structural, large]
     
     rule [err00006]:
          <k> (. => ERROR) ~> joinIntegerBytes-aux(T:KResult, (_:KList,, piece(unknown(Len:Int), Len:Int)), _:K) ...</k>
          <br/>
          (.Bag => <errorCell> Error("00006", "Reading unspecified (possibly uninitialized) memory, or trying to read a pointer or float through an integer type.") </errorCell>)
          when notBool isCharType(T:KResult)
          [structural, large]
          
     rule [err00007]:
          <k> (. => ERROR) ~> checkValidLoc-aux(loc(B:SymBase, _:Int, _:Int)) ...</k>
          <br/>
          (.Bag => <errorCell> Error("00007", "Referring to an object outside of its lifetime.") </errorCell>)
          <mem> M:Map </mem>
          when notBool SetItem(B) in (keys M:Map)
          [structural, large]
     
     rule [err00008]:
          <k> (. => ERROR) ~> concretize(t(_, pointerType(_)), dataList((piece(unknown(Len:Int), Len:Int),, _))) ...</k>
          <br/>
          (.Bag => <errorCell> Error("00008", "Reading uninitialized memory.") </errorCell>)
          [structural, large]
     
     rule [err00009]:
          <k> (. => ERROR) ~> concretize(T:KResult, dataList((piece(unknown(Len:Int), Len:Int),, _))) ...</k>
          <br/>
          (.Bag => <errorCell> Error("00009", "Reading uninitialized memory.") </errorCell>)
          when isFloatType(T:KResult)
          [structural, large]
          
     rule [err00010]:
          <k> (. => ERROR) ~> checkValidLoc-aux(loc(Base:SymBase, Offset:Int, _:Int)) ...</k>
          <mem>... Base |-> memblock(Len:Int, _, _) ...</mem>
          <br/>
          (.Bag => <errorCell> Error("00010", "Found pointer that refers outside the bounds of an object + 1.") </errorCell>)
          when Offset:Int >Int Len:Int
          [structural, large]
          
     rule [err00011]:
          <k> (. => ERROR) ~> tv(_, T:KResult) < tv(_, T':KResult) ...</k>
          <br/>
          (.Bag => <errorCell> Error("00011", "Directly comparing an integer type with a pointer type.") </errorCell>)
          when (hasIntegerType(T:KResult) andBool isPointerType(T':KResult))
          orBool (isPointerType(T:KResult) andBool hasIntegerType(T':KResult))
          [structural, large]
     rule [err00012]:
          <k> (. => ERROR) ~> tv(_, T:KResult) <= tv(_, T':KResult) ...</k>
          <br/>
          (.Bag => <errorCell> Error("00012", "Directly comparing an integer type with a pointer type.") </errorCell>)
          when (hasIntegerType(T:KResult) andBool isPointerType(T':KResult))
          orBool (isPointerType(T:KResult) andBool hasIntegerType(T':KResult))
          [structural, large] 
     rule [err00013]:
          <k> (. => ERROR) ~> tv(_, T:KResult) > tv(_, T':KResult) ...</k>
          <br/>
          (.Bag => <errorCell> Error("00013", "Directly comparing an integer type with a pointer type.") </errorCell>)
          when (hasIntegerType(T:KResult) andBool isPointerType(T':KResult))
          orBool (isPointerType(T:KResult) andBool hasIntegerType(T':KResult))
          [structural, large] 
     rule [err00014]:
          <k> (. => ERROR) ~> tv(_, T:KResult) >= tv(_, T':KResult) ...</k>
          <br/>
          (.Bag => <errorCell> Error("00014", "Directly comparing an integer type with a pointer type.") </errorCell>)
          when (hasIntegerType(T:KResult) andBool isPointerType(T':KResult))
          orBool (isPointerType(T:KResult) andBool hasIntegerType(T':KResult))
          [structural, large] 
          
     rule [err00015]:
          <k> (. => ERROR) ~> arithInterpret(T:Type, I:Int) ...</k>
          <br/>
          (.Bag => <errorCell> Error("00015", "Signed overflow.") </errorCell>)
          when hasSignedIntegerType(T)
          andBool notBool ((min(T) <=Int I:Int) andBool (max(T) >=Int I:Int))
          [structural, large]      
          
          
     rule [err00016]:
          <k> (. => ERROR) ~> writeByte(Loc:SymLoc, _) ...</k>
          <locsWrittenTo> Locs:Bag </locsWrittenTo>
          <br/>
          (.Bag => <errorCell> Error("00016", "Unsequenced side effect on scalar object with side effect of same object.") </errorCell>)
          when BagItem(Loc) in Locs:Bag
          [structural, large] 
          
     rule [err00017]:
          <k> (. => ERROR) ~> tv(_:Int, T:KResult) / tv(0, T:KResult) ...</k>
          <br/>
          (.Bag => <errorCell> Error("00017", "Division by 0.") </errorCell>)
          when hasIntegerType(T:KResult)
          andBool isPromoted(T:KResult)
          [structural, large]
     
     rule [err00018]:
          <k> (. => ERROR) ~> tv(_:Int, T:KResult) % tv(0, T:KResult) ...</k>
          <br/>
          (.Bag => <errorCell> Error("00018", "Modulus by 0.") </errorCell>)
          when hasIntegerType(T:KResult)
          andBool isPromoted(T:KResult)
          [structural, large]
          
     rule [err00019]:
          <k> (. => ERROR) ~> tv(I1:Int, T:KResult) % tv(I2:Int, T:KResult) ...</k>
          <br/>
          (.Bag => <errorCell> Error("00019", "Signed overflow.") </errorCell>)
          when hasIntegerType(T:KResult)
          andBool notBool (min(T:KResult) <=Int I1:Int /Int I2:Int andBool max(T:KResult) >=Int I1:Int /Int I2:Int)
          andBool isPromoted(T:KResult)
          andBool I2:Int =/=Int 0
          [structural, large]
          
     rule [err00020]:
          <k> (. => ERROR) ~> writeByte(loc(Base:SymBase, Offset:Int, _:Int), _) ...</k>
          <mem>... Base |-> memblock(Len:Int, _, _) ...</mem>
          <br/>
          (.Bag => <errorCell> Error("00020", "Tried to write outside the bounds of an object.") </errorCell>)
          when notBool Offset:Int <Int Len:Int
          [structural, large] 
          
     rule [err00021]:
          <k> (. => ERROR) ~> Identifier(S:String) ...</k>
          <env> M:Map </env>
          <br/>
          (.Bag => <errorCell> Error("00021", "Trying to look up identifier  " +String S:String +String " , but no such identifier is in scope.") </errorCell>)
          when notBool $hasMapping(M:Map, Identifier(S:String))
          [structural, large]
          
     rule [err00022]:
          <k> (. => ERROR) ~> leftShiftInterpret(T:KResult, _:Int, tv(E1:Int, T:KResult)) ...</k>
          <br/>
          (.Bag => <errorCell> Error("00022", "Trying to left-shift a negative signed value.") </errorCell>)
          when hasSignedIntegerType(T)
               andBool E1 <Int 0
          [structural, large]
          
     rule [err00023]:
          <k> (. => ERROR) ~> leftShiftInterpret(T:KResult, I:Int, tv(_:Int, T:KResult)) ...</k>
          <br/>
          (.Bag => <errorCell> Error("00023", "Trying to left-shift a signed value, but the result is not representable in the result type.") </errorCell>)
          when hasSignedIntegerType(T:KResult)
               andBool notBool (I:Int <=Int (2 ^Int absInt(numBits(T:KResult))))
          [structural, large]
     
     rule [err00024a]:
          <k> (. => ERROR) ~> tv(_:SymLoc, _) & _ ...</k>
          <br/>
          (.Bag => <errorCell> Error("00024", "Bitwise & used on a symbolic address.") </errorCell>)
          [structural, large]
     rule [err00024b]:
          <k> (. => ERROR) ~> _ & tv(_:SymLoc, _) ...</k>
          <br/>
          (.Bag => <errorCell> Error("00024", "Bitwise & used on a symbolic address.") </errorCell>)
          [structural, large]
     rule [err00024c]:
          <k> (. => ERROR) ~> tv(_:Float, _) & _ ...</k>
          <br/>
          (.Bag => <errorCell> Error("00024", "Bitwise & used on a float.") </errorCell>)
          [structural, large]
     rule [err00024d]:
          <k> (. => ERROR) ~> _ & tv(_:Float, _) ...</k>
          <br/>
          (.Bag => <errorCell> Error("00024", "Bitwise & used on a float.") </errorCell>)
          [structural, large]
          
     rule [err00025]:
          <k> (. => ERROR) ~> callMain-aux(t(_, functionType(t(_, T:K), _:KList)), _:Int, _:Id, _) ...</k>
          <br/>
          (.Bag => <errorCell> Error("00025", "Main must return an int.") </errorCell>)
          when T:K =/=K int
          [structural, large]
     rule [err00026]:
          <k> 
               (. => ERROR) ~> callMain-aux(t(_, functionType(t(_, int), (typedDeclaration(t(_, T:K), _:Id),, _:KList))), _:Int, _:Id, _) 
          ...</k>
          <br/>
          (.Bag => <errorCell> Error("00026", "If main has arguments, the type of the first argument must be equivalent to \"int\".") </errorCell>)
          when T:K =/=K int andBool T:K =/=K void
          [structural, large]
          
     syntax Bool ::= isArgvType(Type) [function]
     
     rule isArgvType(t(_, T:K)) => false
          when notBool (
               getKLabel(T:K) ==KLabel 'incompleteArrayType 
               orBool getKLabel(T:K) ==KLabel 'incompleteArrayType
          )
          
     rule isArgvType(t(_, incompleteArrayType(t(_, T:K)))) => false
          when notBool getKLabel(T:K) ==KLabel 'pointerType
     rule isArgvType(t(_, incompleteArrayType(t(_, pointerType(t(_, T:K)))))) => false
          when T:K =/=K char
          
     rule isArgvType(t(_, pointerType(t(_, T:K)))) => false
          when notBool getKLabel(T:K) ==KLabel 'pointerType
     rule isArgvType(t(_, pointerType(t(_, pointerType(t(_, T:K)))))) => false
          when T:K =/=K char
     
     rule [err00027]:
          <k>
               (. => ERROR) ~> callMain-aux(t(_, functionType(t(_, int), (typedDeclaration(t(_, int), _:Id),, typedDeclaration(T:KResult, _:Id)))), _:Int, _:Id, _) 
          ...</k>
          <br/>
          (.Bag => <errorCell> Error("00027", "If main has arguments, the type of the second argument must be equivalent to  char** .") </errorCell>)
          when notBool isArgvType(T:KResult)
          [structural, large]
     rule [err00028]:
          <k>
               (. => ERROR) ~> callMain-aux(t(_, functionType(t(_, int), (_:KResult,, _:KResult,, _:KResult,, _:KList))), _:Int, _:Id, _) 
          ...</k>
          <br/>
          (.Bag => <errorCell> Error("00028", "Main can only have zero or two arguments.") </errorCell>)
          [structural, large]
     rule [err00029]:
          <k> 
               (. => ERROR) ~> callMain-aux(t(_, functionType(t(_, int), (typedDeclaration(t(_, T:K), _:Id)))), _:Int, _:Id, _)
          ...</k>
          <br/>
          (.Bag => <errorCell> Error("00029", "Main can only have zero or two arguments.") </errorCell>)
          when T:K =/=K void
          [structural, large]
          
     rule [err00030]:
          <k> 
               (. => ERROR) ~> tv(loc(Base:SymBase, _:Int, _:Int), T:KResult) < tv(loc(Base':SymBase, _:Int, _:Int), T:KResult)
          ...</k>
          <br/>
          (.Bag => <errorCell> Error("00030", "Cannot compare pointers with different base objects using '<'.") </errorCell>)
          when Base =/=K Base'
          [structural, large]
     rule [err00031]:
          <k> 
               (. => ERROR) ~> tv(loc(Base:SymBase, _:Int, _:Int), T:KResult) > tv(loc(Base':SymBase, _:Int, _:Int), T:KResult)
          ...</k>
          <br/>
          (.Bag => <errorCell> Error("00031", "Cannot compare pointers with different base objects using '>'.") </errorCell>)
          when Base =/=K Base'
          [structural, large]
     rule [err00032]:
          <k> 
               (. => ERROR) ~> tv(loc(Base:SymBase, _:Int, _:Int), T:KResult) <= tv(loc(Base':SymBase, _:Int, _:Int), T:KResult)
          ...</k>
          <br/>
          (.Bag => <errorCell> Error("00032", "Cannot compare pointers with different base objects using '<='.") </errorCell>)
          when Base =/=K Base'
          [structural, large]
     rule [err00033]:
          <k> 
               (. => ERROR) ~> tv(loc(Base:SymBase, _:Int, _:Int), T:KResult) >= tv(loc(Base':SymBase, _:Int, _:Int), T:KResult)
          ...</k>
          <br/>
          (.Bag => <errorCell> Error("00033", "Cannot compare pointers with different base objects using '>='.") </errorCell>)
          when Base =/=K Base'
          [structural, large]
          
     rule [err00034]:
          <k> 
               (. => ERROR) ~> cast(t(_, T:K), skipval)
          ...</k>
          <br/>
          (.Bag => <errorCell> Error("00034", "Casting void type to non-void type.") </errorCell>)
          when (T:K =/=K void)
          [structural, large]
          
     rule [err00035]:
          <k> 
               (. => ERROR) ~> write(lv(_:SymLoc, t(SetItem(Const) _, _)), _)
          ...</k>
          <br/>
          (.Bag => <errorCell> Error("00035", "Trying to write through a const lvalue.") </errorCell>)
          [structural, large]
     
     rule [err00036]:
          <k> (. => ERROR) ~> checkDerefLoc(NullPointer) ...</k>
          <br/>
          (.Bag => <errorCell> Error("00036", "Trying to dereference a null pointer.") </errorCell>)
          [structural, large]
          
     rule [err00037]:
          <k> (. => ERROR) ~> read-aux(NullPointer, _, _) ...</k>
          <br/>
          (.Bag => <errorCell> Error("00037", "Trying to read through a null pointer.") </errorCell>)
          [structural, large]
          
     rule [err00038]:
          <k> (. => ERROR) ~> ArrayType(_:KResult, tv(0, _), _)  ...</k>
          <br/>
          (.Bag => <errorCell> Error("00038", "Arrays cannot be of 0 length.") </errorCell>)
          [structural, large]
     
     rule [err00039]:
          <k> (. => ERROR) ~> addUnion(_:Id, .KList)  ...</k>
          <br/>
          (.Bag => <errorCell> Error("00039", "Unions cannot be empty.") </errorCell>)
          [structural, large]
     rule [err00040]:
          <k> (. => ERROR) ~> addStruct(_:Id, .KList)  ...</k>
          <br/>
          (.Bag => <errorCell> Error("00040", "Structs cannot be empty.") </errorCell>)
          [structural, large]
          
     rule [err00041]:
          <k> (. => ERROR) ~> types((t(_, void),, t(_, T:K)))  ...</k>
          <br/>
          (.Bag => <errorCell> Error("00041", "If one of a conditional expression's branches has void type, the other must also have void type.") </errorCell>)
          when T:K =/=K void
          [structural, large]
     rule [err00042]:
          <k> (. => ERROR) ~> types((t(_, T:K),, t(_, void)))  ...</k>
          <br/>
          (.Bag => <errorCell> Error("00042", "If one of a conditional expression's branches has void type, the other must also have void type.") </errorCell>)
          when T:K =/=K void
          [structural, large]
     rule [err00043]:
          <k> (. => ERROR) ~> types((T1:KResult,, T2:KResult))  ...</k>
          <br/>
          (.Bag => <errorCell> Error("00043", "If one of a conditional expression's branches has struct or union type, the other must have the same type.") </errorCell>)
          when (T1:KResult =/=K T2:KResult)
               andBool (isStructType(T1:KResult) orBool isUnionType(T1:KResult))
               andBool (isStructType(T2:KResult) orBool isUnionType(T2:KResult))
          [structural, large]
          
     rule [err00044]:
          <k> (. => ERROR) ~> addToPointer(_:SymLoc, T:KResult, I:Int, tv(_:Int, _))  ...</k>
          <br/>
          (.Bag => <errorCell> Error("00044", "An array subscript is out of range.") </errorCell>)
          when notBool ifFromArrayInBounds(T:KResult, I:Int)
          [structural, large]
          
     rule [err00045]:
          <k> (. => ERROR) ~> writeByte(loc(Base:SymBase, _, _), _)  ...</k>
          <mem>... Base |-> memblock(_, (_ BagItem(mconst)), _) ...</mem>
          <br/>
          (.Bag => <errorCell> Error("00045", "Trying to modify a string literal or an object declared with const type.") </errorCell>)
          [structural, large]
          
     rule [err00046]:
          <k> (. => ERROR) ~> concretize(T:KResult, dataList((piece(N:Int, _:Int),, _))) ...</k>
          <br/>
          (.Bag => <errorCell> Error("00046", "Trying to reinterpret integer bytes as floating bytes.") </errorCell>)
          when isFloatType(T:KResult) andBool (N >=Int 0)
          [structural, large]
          
     rule [err00047]:
          <k> (. => ERROR) ~> writeByte(Loc:SymLoc, _)  ...</k>
          <notWritable>... Loc |-> _ ...</notWritable>
          <br/>
          (.Bag => <errorCell> Error("00047", "Trying to modify an object declared with const type.") </errorCell>)
          [structural, large]
     
     syntax K ::= "datarace" "(" SymLoc "," Int "," SymLoc "," Int ")"

     // TODO(chathhorn): comparing SymLocs, elided
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
    //       <br/>
    //       (.Bag => <errorCell> Error("00048", "Have a read-write datarace.")
    //       // ~> datarace(Loc:SymLoc, BitSize:Int, Loc':SymLoc, BitSize':Int) 
    //       </errorCell>)
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
    //       <br/>
    //       (.Bag => <errorCell> Error("00049", "Have a write-write datarace.")
    //       // ~> datarace(Loc:Int, BitSize:Int, Loc':Int, BitSize':Int) 
    //       </errorCell>)
    //       when (Loc <=Loc Loc' andBool Loc' <Loc (Loc +bytes bitsToBytes(BitSize)))
    //            orBool (Loc >Loc Loc' andBool (Loc' +bytes bitsToBytes(BitSize')) >Loc Loc)
    //       [computational, large]        

endmodule
