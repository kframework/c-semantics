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
     imports C-BITSIZE-SYNTAX

     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-COMMON-EXPR-BITWISE-SYNTAX
     imports C-COMMON-EXPR-CONDITIONAL-SYNTAX
     imports C-CONVERSION-SYNTAX

     imports C-IO-BUFFERED-SYNTAX

     imports COMPAT-SYNTAX

     imports LIBC-STDIO-SYNTAX

     imports DEBUG-SYNTAX

     rule (<k> EXIT(Msg:String) ~> K:K </k> 
          => <final-computation> K </final-computation>)
          (.Bag => <error-cell> Msg </error-cell>)

     rule [err00001]: 
          (. => ERROR("00001", "Casting empty value to type other than void.", 89)) ~>
          cast(t(_, T:SimpleType), emptyValue)
          when T =/=K void
          [structural]
         
    //  rule [err00005]:
    //       <k> 
    //            (. => ICE("00005", "Referring to an object outside of its lifetime.") ) ~>
    //            readByte(loc(B:SymBase, _, _)) 
    //       ...</k>
    //       <mem> M:Map </mem>
    //       when notBool SetItem(B) in keys(M:Map)
    //       [structural]
     
     // rule [err00006]:
     //      (. => ERROR("00006", "Reading unspecified (possibly uninitialized) memory, or trying to read a pointer or float through an integer type.", 
     //           21) ) ~>
     //      joinIntegerBytes-aux(t(_, T:SimpleType), _ ListItem(piece(trap(Len:Int), Len)), _)
     //      when T =/=K unsigned-char
     //      [structural]
          
     // rule [err00008]:
     //      (. => ERROR("00008", "Reading uninitialized memory.") ) ~>
     //      concretize(t(_, pointerType(_)),
     //           dataList(ListItem(piece(trap(Len:Int), Len:Int)) _:List))
     //      [structural]
     // 
     // rule [err00009]:
     //      (. => ERROR("00009", "Reading uninitialized memory.",
     //           21) ) ~>
     //      concretize(T:Type,
     //           dataList(ListItem(piece(trap(Len:Int), Len:Int)) _:List))
     //      when hasFloatType(T)
     //      [structural]
          
          
     rule [err00016]:
          <k> (. => ERROR("00016", "Unsequenced side effect on scalar object with side effect of same object.") ) ~>
               checkWrite(Loc:SymLoc, _) 
          ...</k>
          <locs-written> Locs:Bag </locs-written>
          when BagItem(Loc) in Locs:Bag
          [structural] 

     rule [err00020]:
          <k> (. => ERROR("00020", "Trying to write outside the bounds of an object.") ) ~>
               checkWrite(loc(Base:SymBase, Offset:Int, _), _) 
          ...</k>
          <mem>... Base |-> memblock(Len:Int, _, _) ...</mem>
          when notBool Offset <Int Len
          [structural] 
          
     rule [err00022]:
          (. => ERROR("00022", "Trying to left-shift a negative signed value.", 52) ) ~>
          leftShiftInterpret(T:Type, _:Int, tv(E1:Int, T:Type))
          when hasSignedIntegerType(T)
               andBool E1 <Int 0
          [structural]
          
     rule [err00023]:
          (. => ERROR("00023", "Trying to left-shift a signed value, but the result is not representable in the result type.", 52) ) ~>
          leftShiftInterpret(T:Type, I:Int, tv(_:Int, T:Type))
          when hasSignedIntegerType(T)
               andBool notBool (I <=Int (2 ^Int absInt(numBits(T))))
          [structural]
          
     rule [err00034]:
          (. => ERROR("00034", "Casting void type to non-void type.", 308) ) ~>
          cast(t(_, T:SimpleType), skipval)
          when (T =/=K void)
          [structural]
          
     rule [err00037]:
          (. => ERROR("00037", "Trying to read through a null pointer.") ) ~>
          read(NullPointer, _)
          [structural]
          
     rule [err00041]:
          (. => ERROR("00041", "If one of a conditional expression's branches has void type, the other must also have void type.", cv("6.5.15:3")) ) ~>
          types(ListItem(t(_, void)) ListItem(t(_, T:SimpleType)))
          when T =/=K void
          [structural]
     rule [err00042]:
          (. => ERROR("00042", "If one of a conditional expression's branches has void type, the other must also have void type.") ) ~>
          types(ListItem(t(_, T:SimpleType)) ListItem(t(_, void)))
          when T =/=K void
          [structural]
     rule [err00043]:
          (. => ERROR("00043", "If one of a conditional expression's branches has struct or union type, the other must have the same type.", cv("6.5.15:3")) ) ~>
          types(ListItem(T:Type) ListItem(T':Type))
          when (T =/=K T')
               andBool (isStructType(T) orBool isUnionType(T))
               andBool (isStructType(T') orBool isUnionType(T'))
          [structural]
          
     rule [err00045]:
          <k> (. => ERROR("00045", "Trying to modify a string literal or an object declared with const type.", (33,, 64,, cv("6.5.16.1:1"))) ) ~>
               checkWrite(loc(Base:SymBase, _, _), _)
          ...</k>
          <mem>... Base |-> memblock(_, (_ BagItem(mconst)), _) ...</mem>
          [structural]
          
     rule [err00045b]:
          <k> (. => ERROR("00045b", "Trying to modify an object declared with volatile type through a non-volatile lvalue.", (33,, 64,, cv("6.5.16.1:1"))) ) ~>
               checkWrite(loc(Base:SymBase, _, _), T:Type)
          ...</k>
          <mem>... Base |-> memblock(_, (_ BagItem(mvolatile)), _) ...</mem>
          when notBool isVolatileType(T)
          [structural]
          
     rule [err00046]:
          (. => ERROR("00046", "Trying to reinterpret integer bytes as floating bytes.", 37) ) ~>
          concretize(T:Type, dataList(ListItem(piece(N:Int, _)) _))
          when hasFloatType(T) andBool (N >=Int 0)
          [structural]
          
     rule [err00047]:
          <k> (. => ERROR("00047", "Trying to modify an object declared with const type.", 64) ) ~>
               checkWrite(Loc:SymLoc, _)
          ...</k>
          <not-writable>... SetItem(Loc) ...</not-writable>
          [structural]

     rule (. => ERROR("00500", 
               "printf: Format string expects type of size " +String
               Int2String(value(A)) +String ", but got an argument of size "
               +String Int2String(value(B)) +String ".", 409) ) ~>
          nextvarg-aux(_, _, A:TypedValue, B:TypedValue)
          when value(A) =/=Int value(B)
          [structural]
     
     // TODO(chathhorn): Silly way to do things. Probably need to allow
     // multiple error cells at least. Also, add more details (loc?).
     // FIXME possible to miss dataraces with bitfields
     rule [read-write-race]:
          <k> (. => ERROR("00048", "Have a read-write datarace.")) ~> 
               read(Loc:SymLoc, T:Type) 
          ...</k>
          <k> (. => ERROR("00048", "Have a read-write datarace.")) ~> 
               write(Loc':SymLoc, _, T':Type) 
          ...</k>
          when sameBase(Loc, Loc') andBool
               ((Loc <=bytes Loc' 
                    andBool Loc' <bytes (Loc +bytes byteSizeofType(T)))
               orBool (Loc >bytes Loc' 
                    andBool (Loc' +bytes byteSizeofType(T')) >bytes Loc))
          [computational]
           
      rule [write-write-race]:
          <k> (. => ERROR("00049", "Have a write-write datarace.")) ~>
               write(Loc:SymLoc, _, T:Type) 
          ...</k>
          <k> (. => ERROR("00049", "Have a write-write datarace.")) ~>
               write(Loc':SymLoc, _, T':Type) 
          ...</k>
          when sameBase(Loc, Loc') andBool
               ((Loc <=bytes Loc' 
                    andBool Loc' <bytes (Loc +bytes byteSizeofType(T)))
               orBool (Loc >bytes Loc' 
                    andBool (Loc' +bytes byteSizeofType(T')) >bytes Loc))
          [computational]
endmodule
