module C-EXECUTION-ERROR
     imports C-ERROR-SYNTAX

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
     imports C-COMMON-EXPR-CONDITIONAL-SYNTAX
     imports C-CONVERSION-SYNTAX

     imports C-IO-BUFFERED-SYNTAX

     imports COMPAT-SYNTAX

     imports LIBC-STDIO-SYNTAX

     imports DEBUG-SYNTAX

     rule (<k> EXIT(Msg:String) ~> K:K </k> 
          => <final-computation> K </final-computation>)
          (. => <error-cell> Msg </error-cell>)

     rule cast(t(N:Set, T:SimpleType), emptyValue)
	  => castHold(t(N, T:SimpleType), emptyValue)
          requires T =/=K void

     rule [err00001]: 
          (. => ERROR("00001", "Casting empty value to type other than void.", 89)) ~>
          castHold(t(_, T:SimpleType), emptyValue)
          requires T =/=K void
          [structural]
         
    //  rule [err00005]:
    //       <k> 
    //            (. => ICE("00005", "Referring to an object outside of its lifetime.") ) ~>
    //            readByte(loc(B:SymBase, _)) 
    //       ...</k>
    //       <mem> M:Map </mem>
    //       requires notBool SetItem(B) in keys(M:Map)
    //       [structural]
     
     // rule [err00006]:
     //      (. => ERROR("00006", "Reading unspecified (possibly uninitialized) memory, or trying to read a pointer or float through an integer type.", 
     //           21) ) ~>
     //      joinIntegerBytes-aux(t(_, T:SimpleType), _ ListItem(piece(trap(Len:Int), Len)), _)
     //      requires T =/=K unsigned-char
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
     //      requires hasFloatType(T)
     //      [structural]
          

     rule cast(t(N:Set, T:SimpleType), skipval)
	  => castHold(t(N, T:SimpleType), skipval)
          requires (T =/=K void)

     rule [err00034]:
          (. => ERROR("00034", "Casting void type to non-void type.", 308) ) ~>
          castHold(t(_, T:SimpleType), skipval)
          requires (T =/=K void)
          [structural]
          
     rule [err00037]:
          (. => ERROR("00037", "Trying to read through a null pointer.") ) ~>
          read(NullPointer, _)
          [structural]
          
     rule [err00041]:
          (. => ERROR("00041", "If one of a conditional expression's branches has void type, the other must also have void type.", "6.5.15:3") ) ~>
          types(trItem(t(_, void)) ts:: trItem(t(_, T:SimpleType)))
          requires T =/=K void
          [structural]
     rule [err00042]:
          (. => ERROR("00042", "If one of a conditional expression's branches has void type, the other must also have void type.") ) ~>
          types(trItem(t(_, T:SimpleType)) ts:: trItem(t(_, void)))
          requires T =/=K void
          [structural]
     rule [err00043]:
          (. => ERROR("00043", "If one of a conditional expression's branches has struct or union type, the other must have the same type.", "6.5.15:3") ) ~>
          types(trItem(T:Type) ts:: trItem(T':Type))
          requires (T =/=K T')
               andBool (isStructType(T) orBool isUnionType(T))
               andBool (isStructType(T') orBool isUnionType(T'))
          [structural]
          
     rule [err00046]:
          (. => ERROR("00046", "Trying to reinterpret integer bytes as floating bytes.", 37) ) ~>
          concretize(T:Type, dataList(ListItem(piece(N:Int, _)) _))
          requires hasFloatType(T) andBool (N >Int 0)
          [structural]

     rule (. => ERROR("00500", 
               "printf: Format string expects type of size " +String
               Int2String(value(A)) +String ", but got an argument of size "
               +String Int2String(value(B)) +String ".", 409) ) ~>
          nextvarg-aux(_, _, A:TypedValue, B:TypedValue)
          requires value(A) =/=Int value(B)
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
          requires sameBase(Loc, Loc') andBool
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
          requires sameBase(Loc, Loc') andBool
               ((Loc <=bytes Loc' 
                    andBool Loc' <bytes (Loc +bytes byteSizeofType(T)))
               orBool (Loc >bytes Loc' 
                    andBool (Loc' +bytes byteSizeofType(T')) >bytes Loc))
          [computational]
endmodule
