module C-EXECUTION-ERROR
     imports C-ERROR-SYNTAX

     imports C-EXECUTION-INIT-SYNTAX

     imports C-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-BITS-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-SETTINGS-SYNTAX

     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-CONVERSION-SYNTAX

     imports C-IO-BUFFERED-SYNTAX

     imports C-CONFIGURATION

     imports LIBC-STDIO-SYNTAX

     imports DEBUG-SYNTAX

     syntax KItem ::= error(String, String)

     rule (<k> EXIT(Msg:String) ~> K:K </k>
          => <final-computation> #write(2, Msg +String "\n" +String printStackTrace(L, Loc, S)) ~> K </final-computation>)
          <call-stack> L:List </call-stack>
          <curr-program-loc> Loc:CabsLoc </curr-program-loc>
          <curr-scope> S:Scope </curr-scope>
          requires notBool isErrorRecovery andBool notBool isCSV

     rule <k> EXIT(Msg:String) => #write(2, Msg +String "\n" +String printStackTrace(L, Loc, S)) ~> HALT ...</k>
          <call-stack> L:List </call-stack>
          <curr-program-loc> Loc:CabsLoc </curr-program-loc>
          <curr-scope> S:Scope </curr-scope>
          <previous-errors> Errors:Set => Errors SetItem(error(Msg, printStackTrace(L, Loc, S))) </previous-errors>
          requires isErrorRecovery andBool notBool isCSV
               andBool notBool error(Msg, printStackTrace(L, Loc, S)) in Errors

     rule <k> EXIT(Msg:String) => HALT ...</k>
          <call-stack> L:List </call-stack>
          <curr-program-loc> Loc:CabsLoc </curr-program-loc>
          <curr-scope> S:Scope </curr-scope>
          <previous-errors> Errors:Set </previous-errors>
          requires isErrorRecovery andBool notBool isCSV
               andBool error(Msg, printStackTrace(L, Loc, S)) in Errors

     rule <result-value> unknown => (139 ~> #write(2, "Unspecified value returned from main function.\n")):>Int </result-value>
     requires notBool isCSV

     rule <file-commands> openWriteThenClose(File:String, Line:String) => writeThenClose(#open(File, "wac"), Line) ...</file-commands>
     rule <file-commands> writeThenClose(Fd:Int, Line:String) => #write(Fd, Line) ~> close(Fd) ...</file-commands>
     rule <file-commands> close(Fd:Int) => #close(Fd) ...</file-commands>

     rule <k> EXIT(Msg:String) => openWriteThenClose(Report, Msg +String ",\"" +String printStackTrace(L, Loc, S) +String "\"\r\n") ~> HALT ...</k>
          <call-stack> L:List </call-stack>
          <curr-program-loc> Loc:CabsLoc </curr-program-loc>
          <curr-scope> S:Scope </curr-scope>
          <options>... SetItem(CSV(Report:String)) ...</options>
          requires isErrorRecovery

     rule <result-value> unknown => 139 </result-value>
          <file-commands> .K => openWriteThenClose(Report, "CEER6,Unspecified value returned from main function.,Unspecified value or behavior.,5.1.2.2.3:1,unknown\r\n") ...</file-commands>
          <options>... SetItem(CSV(Report:String)) ...</options>

     syntax String ::= printStackTrace(List, CabsLoc, Scope) [function]

     rule printStackTrace(L:List, Loc:CabsLoc, fileScope)
          => "  at <file-scope>(" +String printStackTrace(L, Loc, .K)
     rule printStackTrace(L:List, Loc:CabsLoc, blockScope(Identifier(S:String), _))
          => "  at " +String S +String "(" +String printStackTrace(L, Loc, .K)
     rule printStackTrace(L:List, CabsLoc(File:String, Line:Int, _, _), .K)
          => File +String ":" +String Int2String(Line) +String ")\n" +String printStackTrace(L, .K, .K)
     rule printStackTrace(L:List, UnknownCabsLoc, .K)
          => "<unknown>)\n" +String printStackTrace(L, .K, .K)
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
          (.K => UNDEF("CEER1", "Trying to read through a null pointer.", "6.3.2.1:1, J.2:1 item 19") ) ~>
          read(NullPointer, _)
          [structural]
     rule [err00046]:
          (.K => UNSPEC("CEER2", "Trying to reinterpret integer bytes as floating bytes.", "6.2.6.1:1, J.1:1 item 9") ) ~>
          concretize(_:FloatType, dataList(ListItem(piece(N:Int, _)) _))
          requires (N >Int 0)
          [structural]

     rule (.K => UNDEF("STDIO1",
               "printf: Format string expects type of size " +String
               Int2String(value(A):>Int) +String ", but got an argument of size "
               +String Int2String(value(B):>Int) +String ".", "7.21.6.1:9, J.2:1 item 153") ) ~>
          nextvarg-aux(_, _, A:RValue, B:RValue)
          requires value(A):>Int =/=Int value(B):>Int
          [structural]

     // TODO(chathhorn): Silly way to do things. Probably need to allow
     // multiple error cells at least. Also, add more details (loc?).
     // FIXME possible to miss dataraces with bitfields
     rule [read-write-race]:
          <k> (.K => UNDEF("CEER4", "Have a read-write datarace.", "5.1.2.4:25, J.2:1 item 5")) ~>
               read(Loc:SymLoc, T:Type)
          ...</k>
          <k> (.K => UNDEF("CEER4", "Have a read-write datarace.", "5.1.2.4:25, J:2.1 item 5")) ~>
               write(Loc':SymLoc, _, T':Type)
          ...</k>
          requires sameBase(Loc, Loc') andBool
               ((Loc <=bytes Loc'
                    andBool Loc' <bytes (Loc +bytes byteSizeofType(T)))
               orBool (Loc >bytes Loc'
                    andBool (Loc' +bytes byteSizeofType(T')) >bytes Loc))
          [computational]

      rule [write-write-race]:
          <k> (.K => UNDEF("CEER5", "Have a write-write datarace.", "5.1.2.4:25, J.2:1 item 5")) ~>
               write(Loc:SymLoc, _, T:Type)
          ...</k>
          <k> (.K => UNDEF("CEER5", "Have a write-write datarace.", "5.1.2.4:25, J.2:1 item 5")) ~>
               write(Loc':SymLoc, _, T':Type)
          ...</k>
          requires sameBase(Loc, Loc') andBool
               ((Loc <=bytes Loc'
                    andBool Loc' <bytes (Loc +bytes byteSizeofType(T)))
               orBool (Loc >bytes Loc'
                    andBool (Loc' +bytes byteSizeofType(T')) >bytes Loc))
          [computational]

     rule <k> (.K => CV("CID1",
               "Trying to look up identifier " +String S +String
               ", but no such identifier is in scope.",
               "6.5.1:2") )
               ~> Identifier(S:String)
          ...</k>
          <env> Env:Map </env>
          <types> Types:Map </types>
          requires (notBool (Identifier(S) in_keys(Env)))
               andBool (notBool (Identifier(S) in_keys(Types)))
          [structural]
     rule <k> (.K => UNDEF("CID2",
               "No definition found for identifier " +String S +String ".", "6.3.2.1:1, J.2:1 item 19") )
               ~> Identifier(S:String)
          ...</k>
          <env> Env:Map </env>
          <types>... Identifier(S) |-> _ ...</types>
          requires (notBool (Identifier(S) in_keys(Env)))
          [structural]


endmodule
