module C-EXECUTION-ERROR
     imports C-ERROR-SYNTAX
     imports C-ERROR-MAP-SYNTAX
     imports C-CONSTRAINT-MAP-SYNTAX

     imports C-EXECUTION-INIT-SYNTAX

     imports C-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-BITS-SYNTAX

     imports C-TYPING-MISC-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-COMMON-EXPR-BITWISE-SYNTAX
     imports C-COMMON-EXPR-CONDITIONAL-SYNTAX
     imports C-COMMON-EXPR-ADDITIVE-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-CHECK-LOC-SYNTAX

     imports COMPAT-SYNTAX

     imports LIBC-STDIO-SYNTAX

     imports DEBUG-SYNTAX

     rule [err00001]: 
          (. => ERROR("00001", "Casting empty value to type other than void.", 89)) ~>
          cast(t(_, T:K), emptyValue)
          when T:K =/=K void
          [structural, large]
         
     rule [err00002]:
          (. => ERROR("00002", "Reading outside the bounds of an object.", 
               (19,, 43,, 47,, 62)) ) ~>
          assert(false, 2)
          [structural, large]
     rule [err00003]:
          (. => ERROR("00003", "Unsequenced side effect on scalar object with value computation of same object.", 315) ) ~>
          assert(false, 3)
          [structural, large]

    //  rule [err00005]:
    //       <k> 
    //            (. => ICE("00005", "Referring to an object outside of its lifetime.") ) ~>
    //            readByte(loc(B:SymBase, _:Int, _:Int)) 
    //       ...</k>
    //       <mem> M:Map </mem>
    //       when notBool SetItem(B) in keys (M:Map)
    //       [structural, large]
     
     rule [err00006]:
          (. => ERROR("00006", "Reading unspecified (possibly uninitialized) memory, or trying to read a pointer or float through an integer type.", 
               21) ) ~>
          joinIntegerBytes-aux(T:Type, (_:KList,, piece(unknown(Len:Int), Len:Int)), _:K)
          when notBool isCharType(T)
          [structural, large]
          
     rule [err00007]:
          <k> 
               (. => ERROR("00007", "Referring to an object outside of its lifetime.",
                    (9,, 10)) ) ~>
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
          (. => ERROR("00009", "Reading uninitialized memory.",
               21) ) ~>
          concretize(T:Type, dataList((piece(unknown(Len:Int), Len:Int),, _)))
          when isFloatType(T)
          [structural, large]
          
     rule [err00010]:
          <k> 
               (. => ERROR("00010", "Found pointer that refers outside the bounds of an object + 1.", 62) ) ~>
               checkValidLoc-aux(loc(Base:SymBase, Offset:Int, _:Int)) 
          ...</k>
          <mem>... Base |-> memblock(Len:Int, _, _) ...</mem>
          when Offset:Int >Int Len:Int
          [structural, large]
          
     rule [err00015]:
          (. => ERROR("00015", "Signed overflow.", 36) ) ~>
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
          (. => ERROR("00017", "Division by 0.", 319) ) ~>
          tv(_:Int, T:Type) / tv(0, T:Type)
          when hasIntegerType(T) andBool isPromoted(T)
          [structural, large]
     
     rule [err00018]:
          (. => ERROR("00018", "Modulus by 0.", 320) ) ~>
          tv(_:Int, T:Type) % tv(0, T:Type)
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
          
     rule [err00020]:
          <k> 
               (. => ERROR("00020", "Tried to write outside the bounds of an object.") ) ~>
               writeByte(loc(Base:SymBase, Offset:Int, _:Int), _) 
          ...</k>
          <mem>... Base |-> memblock(Len:Int, _, _) ...</mem>
          when notBool Offset <Int Len
          [structural, large] 
          
     rule [err00022]:
          (. => ERROR("00022", "Trying to left-shift a negative signed value.", 52) ) ~>
          leftShiftInterpret(T:Type, _:Int, tv(E1:Int, T:Type))
          when hasSignedIntegerType(T)
               andBool E1 <Int 0
          [structural, large]
          
     rule [err00023]:
          (. => ERROR("00023", "Trying to left-shift a signed value, but the result is not representable in the result type.", 52) ) ~>
          leftShiftInterpret(T:Type, I:Int, tv(_:Int, T:Type))
          when hasSignedIntegerType(T)
               andBool notBool (I <=Int (2 ^Int absInt(numBits(T))))
          [structural, large]
     
     rule [err00025a]:
          (. => ERROR("00025a", "Main must return an int.", 4) ) ~>
          callMain-aux(t(_, functionType(t(_, T:SimpleType), _:KList)), _:Int, _:Id, _)
          when T =/=K int
          [structural, large]
     rule [err00025b]:
          <k> 
               (. => ERROR("00025b", "Main must exist.", 4) ) ~>
               callMain(_, _)
          ...</k>
          <mainTU> .K </mainTU>
          [structural, large]
     rule [err00026]:
          (. => ERROR("00026", "If main has arguments, the type of the first argument must be equivalent to \"int\".", 4) ) ~>
          callMain-aux(t(_, functionType(t(_, int), (typedDeclaration(t(_, T:SimpleType), _:Id),, _:KList))), _:Int, _:Id, _) 
          when T =/=K int andBool T =/=K void
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
          callMain-aux(t(_, functionType(t(_, int), (_:Type,, _:Type,, _:Type,, _:KList))), _:Int, _:Id, _) 
          [structural, large]
     rule [err00029]:
          (. => ERROR("00029", "Main can only have zero or two arguments.") ) ~>
          callMain-aux(t(_, functionType(t(_, int), (typedDeclaration(t(_, T:SimpleType), _:Id)))), _:Int, _:Id, _)
          when T =/=K void
          [structural, large]
          
     rule [err00034]:
          (. => ERROR("00034", "Casting void type to non-void type.", 308) ) ~>
          cast(t(_, T:K), skipval)
          when (T:K =/=K void)
          [structural, large]
          
     rule [err00035]:
          (. => ERROR("00035", "Trying to write through a const lvalue.", cv("6.5.16.1:1")) ) ~>
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
          
     rule [err00041]:
          (. => ERROR("00041", "If one of a conditional expression's branches has void type, the other must also have void type.", cv("6.5.15:3")) ) ~>
          types((t(_, void),, t(_, T:K)))
          when T:K =/=K void
          [structural, large]
     rule [err00042]:
          (. => ERROR("00042", "If one of a conditional expression's branches has void type, the other must also have void type.") ) ~>
          types((t(_, T:K),, t(_, void)))
          when T:K =/=K void
          [structural, large]
     rule [err00043]:
          (. => ERROR("00043", "If one of a conditional expression's branches has struct or union type, the other must have the same type.", cv("6.5.15:3")) ) ~>
          types((T:Type,, T':Type))
          when (T =/=K T')
               andBool (isStructType(T) orBool isUnionType(T))
               andBool (isStructType(T') orBool isUnionType(T'))
          [structural, large]
          
     rule [err00044]:
          (. => ERROR("00044", "An array subscript is out of range.", (46,, 49)) ) ~>
          addToPointer(_:SymLoc, T:Type, I:Int, tv(_:Int, _))
          when notBool ifFromArrayInBounds(T, I)
          [structural, large]
          
     rule [err00045]:
          <k> 
               (. => ERROR("00045", "Trying to modify a string literal or an object declared with const type.", (33,, 64,, cv("6.5.16.1:1"))) ) ~>
               writeByte(loc(Base:SymBase, _, _), _)
          ...</k>
          <mem>... Base |-> memblock(_, (_ BagItem(mconst)), _) ...</mem>
          [structural, large]
          
     rule [err00046]:
          (. => ERROR("00046", "Trying to reinterpret integer bytes as floating bytes.", 37) ) ~>
          concretize(T:Type, dataList((piece(N:Int, _:Int),, _)))
          when isFloatType(T) andBool (N >=Int 0)
          [structural, large]
          
     rule [err00047]:
          <k> 
               (. => ERROR("00047", "Trying to modify an object declared with const type.", 64) ) ~>
               writeByte(Loc:SymLoc, _)
          ...</k>
          <notWritable>... Loc |-> _ ...</notWritable>
          [structural, large]

     rule
          (. => ERROR("00500", 
               "printf: Format string expects type of size " +String
               Int2String(value(A)) +String ", but got an argument of size "
               +String Int2String(value(B)) +String ".", 409) ) ~>
          nextvarg-aux(_, _, A:TypedValue, B:TypedValue)
          when value(A) =/=Int value(B)
          [structural, large]
     
     // TODO(chathhorn): Silly way to do things. Probably need to allow
     // multiple error cells at least. Also, add more details (loc?).
     // fixme possible to miss dataraces with bitfields
     rule [read-write-race]:
          <k> 
               (. => ERROR("00048", "Have a read-write datarace.")) ~> 
               read-aux(Loc:SymLoc, _, BitSize:Int) 
          ...</k>
          <k> 
               (. => ERROR("00048", "Have a read-write datarace.")) ~> 
               write-aux(Loc':SymLoc, _, BitSize':Int) 
          ...</k>
          when sameBase(Loc, Loc') andBool
               ((Loc <=bytes Loc' 
                    andBool Loc' <bytes (Loc +bytes bitsToBytes(BitSize)))
               orBool (Loc >bytes Loc' 
                    andBool (Loc' +bytes bitsToBytes(BitSize')) >bytes Loc))
          [computational, large]
           
      rule [write-write-race]:
          <k> 
               (. => ERROR("00049", "Have a write-write datarace.")) ~>
               write-aux(Loc:SymLoc, _, BitSize:Int) 
          ...</k>
          <k> 
               (. => ERROR("00049", "Have a write-write datarace.")) ~>
               write-aux(Loc':SymLoc, _, BitSize':Int) 
          ...</k>
          when sameBase(Loc, Loc') andBool
               ((Loc <=bytes Loc' 
                    andBool Loc' <bytes (Loc +bytes bitsToBytes(BitSize)))
               orBool (Loc >bytes Loc' 
                    andBool (Loc' +bytes bitsToBytes(BitSize')) >bytes Loc))
          [computational, large]        
endmodule
