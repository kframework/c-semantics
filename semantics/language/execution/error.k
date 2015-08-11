module C-EXECUTION-ERROR
     imports C-ERROR-SYNTAX

     imports C-EXECUTION-INIT-SYNTAX

     imports C-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-BITS-SYNTAX
     imports C-BITSIZE-SYNTAX

     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-CONVERSION-SYNTAX

     imports C-IO-BUFFERED-SYNTAX

     imports C-CONFIGURATION

     imports LIBC-STDIO-SYNTAX

     imports DEBUG-SYNTAX

     rule (<k> EXIT(Msg:String) ~> K:K </k>
          => <final-computation> #write(2, Msg +String printStackTrace(L, Loc, S) +String "\n") ~> K </final-computation>)
          <call-stack> L:List </call-stack>
          <curr-program-loc> Loc:CabsLoc </curr-program-loc>
          <curr-scope> S:Scope </curr-scope>

     syntax String ::= printStackTrace(List, CabsLoc, Scope) [function]

     rule printStackTrace(L:List, Loc:CabsLoc, fileScope)
          => "\n  at <file-scope>(" +String printStackTrace(L, Loc, .K)
     rule printStackTrace(L:List, Loc:CabsLoc, blockScope(Identifier(S:String), _))
          => "\n  at " +String S +String "(" +String printStackTrace(L, Loc, .K)
     rule printStackTrace(L:List, CabsLoc(File:String, Line:Int, _, _), .K)
          => File +String ":" +String Int2String(Line) +String ")" +String printStackTrace(L, .K, .K)
     rule printStackTrace(L:List, UnknownCabsLoc, .K)
          => "<unknown>)" +String printStackTrace(L, .K, .K)
     rule printStackTrace(ListItem(<call-stack-frame>...
               <stack-curr-program-loc> Loc:CabsLoc </stack-curr-program-loc>
               <stack-curr-scope> S:Scope </stack-curr-scope>
          ...</call-stack-frame>) L:List, .K, .K)
          => printStackTrace(L, Loc, S)
     rule printStackTrace(.List, .K, .K) => ""

     rule cast(t(N:Set, T:SimpleType), emptyValue)
          => castHold(t(N, T:SimpleType), emptyValue)
          requires T =/=K void

     rule [err00037]:
          (.K => UNDEF("CEER1", "Trying to read through a null pointer.", "6.3.2.1:1") ) ~>
          read(NullPointer, _)
          [structural]
     rule [err00046]:
          (.K => ERROR("CEER2", "Trying to reinterpret integer bytes as floating bytes.") ) ~>
          concretize(_:FloatType, dataList(ListItem(piece(N:Int, _)) _))
          requires (N >Int 0)
          [structural]

     rule (.K => UNDEF("CEER3",
               "printf: Format string expects type of size " +String
               Int2String(value(A):>Int) +String ", but got an argument of size "
               +String Int2String(value(B):>Int) +String ".", "7.21.6.1:9") ) ~>
          nextvarg-aux(_, _, A:RValue, B:RValue)
          requires value(A):>Int =/=Int value(B):>Int
          [structural]

     // TODO(chathhorn): Silly way to do things. Probably need to allow
     // multiple error cells at least. Also, add more details (loc?).
     // FIXME possible to miss dataraces with bitfields
     rule [read-write-race]:
          <k> (.K => ERROR("00048", "Have a read-write datarace.")) ~>
               read(Loc:SymLoc, T:Type)
          ...</k>
          <k> (.K => ERROR("00048", "Have a read-write datarace.")) ~>
               write(Loc':SymLoc, _, T':Type)
          ...</k>
          requires sameBase(Loc, Loc') andBool
               ((Loc <=bytes Loc'
                    andBool Loc' <bytes (Loc +bytes byteSizeofType(T)))
               orBool (Loc >bytes Loc'
                    andBool (Loc' +bytes byteSizeofType(T')) >bytes Loc))
          [computational]

      rule [write-write-race]:
          <k> (.K => ERROR("00049", "Have a write-write datarace.")) ~>
               write(Loc:SymLoc, _, T:Type)
          ...</k>
          <k> (.K => ERROR("00049", "Have a write-write datarace.")) ~>
               write(Loc':SymLoc, _, T':Type)
          ...</k>
          requires sameBase(Loc, Loc') andBool
               ((Loc <=bytes Loc'
                    andBool Loc' <bytes (Loc +bytes byteSizeofType(T)))
               orBool (Loc >bytes Loc'
                    andBool (Loc' +bytes byteSizeofType(T')) >bytes Loc))
          [computational]
endmodule
