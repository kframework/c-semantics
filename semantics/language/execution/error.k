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
          (.Bag => <error-cell> Msg </error-cell>)


     rule [err00037]:
          (. => ERROR("00037", "Trying to read through a null pointer.") ) ~>
          read(NullPointer, _)
          [structural]

     rule [err00046]:
          (. => ERROR("00046", "Trying to reinterpret integer bytes as floating bytes.", 37) ) ~>
          concretize(T:Type, dataList(ListItem(piece(N:Int, _)) _))
          when hasFloatType(T) andBool (N >Int 0)
          [structural]

     rule (. => ERROR("00500", 
               "printf: Format string expects type of size " +String
               Int2String(value(A)) +String ", but got an argument of size "
               +String Int2String(value(B)) +String ".", 409) ) ~>
          nextvarg-aux(_, _, A:RValue, B:RValue)
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
