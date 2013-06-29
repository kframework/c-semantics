module C-HELPERS-SYNTAX
     syntax Bits ::= Bits "bit::" Bits

     syntax Int ::= "bitsToBytes" "(" Int ")" [function]

     syntax String ::= firstChar(String) [function]
     syntax String ::= "nthChar" "(" String "," Int ")" [function]
     syntax String ::= "butFirstChar" "(" String ")" [function]
     
     syntax List ::= "stringToList" "(" String ")" [function]
     syntax String ::= listToString(List) [function]

     syntax Bool ::= isUnknown(K) [function] // Ints, Bits, SymLocs
     
     syntax String ::= toUpperCase(String) [function]
     syntax K ::= "getString" "(" K ")"
     syntax Value ::= "str" "(" String ")"
     syntax K ::= "writeString" "(" SymLoc "," String ")"
     syntax K ::= "writeWString" "(" SymLoc "," KList ")"
     // fixme might be messing things up elsewhere
     syntax String ::= pointerToString(SymLoc) [function]
     syntax String ::= subPointerToString(SymBase) [function]

     //syntax KList ::=  Int "to" Int [function]

     syntax K ::= "fillToBytes" "(" K ")" [strict] 
     // original number, from, to inclusive
     syntax Bits ::= "bitRange" "(" Bits "," Int "," Int ")"
     
     syntax Type ::= "type" "(" K ")"
     syntax K ::= "value" "(" K ")"

endmodule

module C-HELPERS
     imports C-HELPERS-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-COMPAT-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-MEMORY-SYNTAX
     imports C-SETTINGS-SYNTAX

     rule stringToList("") => .List
     rule stringToList(S:String)
               => ListItem(firstChar(S:String)) 
                    stringToList(butFirstChar(S:String))
          when S:String =/=String ""
          
     rule listToString(.List) => ""
     rule listToString((ListItem(S:String) L:List))
               => S:String +String listToString(L:List)
     
     rule [isUnknown-piece]: isUnknown(piece(_, _)) => true
     rule [isUnknown-ptr]: isUnknown(loc(_:SymBase, _:Int, _:Int)) => false
     rule [isUnknown-int]: isUnknown(I:Int) => false
          // TODO(chathhorn): silly sort check
          when (I <=Int 0) orBool (I >Int 0)

     // this maintains byte order
     syntax K ::= "fillToBytes-aux" "(" K "," KList ")"
     rule [fillToBytes-start]:
          fillToBytes(dataList(L:KList)) 
          => fillToBytes-aux(dataList(L:KList), .KList) 
          [structural]
     rule [fillToBytes-foundByte]:
          fillToBytes-aux(dataList((L:KList,, 
               piece(N:Bits, Len:Int))), L':KList)
          => fillToBytes-aux(dataList(L:KList), (piece(N, Len),, L'))
          when Len ==Int cfg:bitsPerByte
          [structural]
     
     rule [fillToBytes-addBit]:
          fillToBytes-aux(dataList(piece(N:Bits, Len:Int)), L':KList)
          => fillToBytes-aux(dataList((piece(0, 1),, piece(N, Len))), L')
          when Len:Int <Int cfg:bitsPerByte
          [structural]
          
     rule [fillToBytes-combineBits]:
          fillToBytes-aux(dataList((L:KList,, piece(N:Bits, Len:Int),, 
               piece(N':Bits, Len':Int))), L':KList)
          => fillToBytes-aux(dataList((L,, piece(piece(N, Len) 
               bit:: piece(N', Len'), Len +Int Len'))), L')
          when Len +Int Len' <=Int cfg:bitsPerByte
          [structural]
                    
     rule [fillToBytes-done]:
          fillToBytes-aux(dataList(.KList), L:KList) => dataList(L)
          [structural]
          
     // coallesce bitranges that are adjacent
     rule piece(bitRange(N:Bits, SuccTo:Int, To':Int), Len:Int) 
               bit:: piece(bitRange(N, From:Int, To:Int), Len':Int)
          => piece(bitRange(N, From, To'), Len +Int Len')
          when (Len +Int Len' <=Int cfg:bitsPerByte)
               andBool (SuccTo ==Int To +Int 1)
          [structural, anywhere]
     
     rule piece(N:Bits bit:: N':Bits, Len:Int) bit:: piece(N'':Bits, Len':Int)
          => piece((N bit:: N') bit:: piece(N'', Len'), Len +Int Len')
          [structural, anywhere]

     rule piece(N'':Bits, Len':Int) bit:: piece(N:Bits bit:: N':Bits, Len:Int)
          => piece((piece(N'', Len') bit:: N) bit:: N', Len +Int Len')
          [structural, anywhere]

     rule bitRange(N:Bits bit:: piece(_, Len:Int), Pos:Int, Pos:Int)
          => bitRange(N, absInt(Pos -Int Len), absInt(Pos -Int Len))
          when (Pos >Int 0) andBool (Pos -Int Len >=Int 0)
          [structural, anywhere]
          
     rule bitRange(_ bit:: piece(N:Bits, 1), 0, 0) => piece(N, 1)
          [anywhere, anywhere]
     rule bitRange(piece(N:Bits, 1), 0, 0) => piece(N, 1)
          [anywhere, anywhere]
          
     rule bitRange(piece(bitRange(N:Bits, Start:Int, End:Int), Len:Int), 0, 0)
          => bitRange(piece(bitRange(N, Start, Start), 1), 0, 0)
          when Start +Int Len ==Int End +Int 1
          [structural, anywhere]
     
     rule bitRange(N:Int, Pos:Int, Pos:Int) => 1 &Int (N >>Int Pos)
          when N >=Int 0
          [structural, anywhere]
     rule bitRange(piece(N:Int, 1), Pos:Int, Pos:Int) => 1 &Int (N >>Int Pos)
          when N >=Int 0
          [structural, anywhere]
          
     rule bitRange(N:Bits, 0, To:Int) => N
          when To +Int 1 ==Int cfg:bitsPerByte
          [structural, anywhere]
     
     rule bitRange(_ bit:: piece(N:Bits, Len:Int), Start:Int, End:Int)
          => bitRange(piece(N, Len), Start, End)
          when End +Int 1 <=Int Len
          [structural, anywhere]
     
     rule bitRange(piece(N:Bits, SuccEnd:Int), 0, End:Int)
          => piece(N, End +Int 1)
          when SuccEnd ==Int End +Int 1
          [structural, anywhere]
     rule bitRange(_ bit:: piece(N:Bits, SuccEnd:Int), 0, End:Int)
          => piece(N, End +Int 1)
          when SuccEnd ==Int End +Int 1
          [structural, anywhere]
          
     rule bitRange(piece(N:Int, _), Pos:Int, Pos:Int) 
          => (N >>Int Pos) &Int 1
          when N >=Int 0
          [structural, anywhere]
     
     // this should probably go in the k prelude
     rule K:K in (ListItem(K:K) _:List) => true
     rule _:K in .List => false
     rule K:K in (ListItem(K':K) L:List) => K:K in L:List
          when K:K =/=K K':K
          [structural]
     
     //- derived
     rule bitsToBytes(N:Int) => absInt(N:Int /Int cfg:bitsPerByte)
          when cfg:bitsPerByte dividesInt N:Int
          [structural]
     rule bitsToBytes(N:Int) => absInt((N:Int /Int cfg:bitsPerByte) +Int 1) 
          when notBool cfg:bitsPerByte dividesInt N:Int
          [structural]
          
     rule numBytes(t(_, unsigned-char)) => numBytes(t(.Set, signed-char))
     rule numBytes(t(_, unsigned-short-int)) => numBytes(t(.Set, short-int))
     rule numBytes(t(_, unsigned-int)) => numBytes(t(.Set, int))
     rule numBytes(t(_, unsigned-long-int)) => numBytes(t(.Set, long-int))
     rule numBytes(t(_, unsigned-long-long-int)) 
          => numBytes(t(.Set, long-long-int))
     
     rule [firstChar]:
          firstChar(S:String) => substrString(S:String, 0, 1)
          [structural]

     rule [nthChar]:
          nthChar(S:String, N:Int) => substrString(S:String, N:Int, 1)
          [structural]

     rule [butFirstChar]:
          butFirstChar(S:String) 
          => substrString(S:String, 1, lengthString(S:String))
          [structural]
          
     rule toUpperCase(S:String)
          => toUpperCase(firstChar(S:String))
               +String toUpperCase(butFirstChar(S:String))
          when lengthString(S) >Int 1

     rule toUpperCase(C:String)
          => C:String
          when (lengthString(C) ==Int 1)
               andBool (asciiString(C) <Int asciiString("a")
                    orBool asciiString(C) >Int asciiString("z"))
     rule toUpperCase(C:String)
          => #charString(absInt(asciiString(C) 
               -Int (asciiString("a") -Int asciiString("A"))))
          when (lengthString(C) ==Int 1)
               andBool (asciiString(C) >=Int asciiString("a")
                    andBool asciiString(C) <=Int asciiString("z"))
          
     // getString returns the string without the null terminator
     syntax K ::= "getString-aux" "(" SymLoc "," String ")"
     rule getString(Loc:SymLoc) => getString-aux(Loc, "")
          [structural, anywhere]
     rule getString(tv(Loc:SymLoc, _)) => getString-aux(Loc, "")
          [structural, anywhere]
     
     rule [getString-pre]:
          (. => read(Loc, t(.Set, char)))
          ~> getString-aux((Loc:SymLoc => Loc +bytes 1), _)
          [structural]
          
     rule [getString]:
          tv(N:Int, _) ~> getString-aux(Loc:SymLoc, S:String)
          => getString-aux(Loc, S +String #charString(N))
          when N =/=Int 0
          [structural]
     rule [getString-done]:
          tv(0, _) ~> getString-aux(_, S:String)
          => str(S)
          [structural]
          
     // writeString and writeWString expect the user to add the '\0' to the end
     // of the strings passed

     rule [write-string]:
          writeString(Loc:SymLoc, S:String)
          => Computation((* tv(Loc, t(.Set, pointerType(t(.Set, char))))) 
               := tv(asciiString(firstChar(S:String)), t(.Set, char)))
          ~> writeString(Loc +bytes 1, butFirstChar(S:String))
          when S:String =/=String ""
          [structural]
     // fixme this bare 4 needs to be updated to handle different size wchar_ts
     rule [write-wstring]:
          writeWString(Loc:SymLoc, (N:Int,, S:KList))
          => Computation((* tv(Loc, t(.Set, pointerType(cfg:wcharut)))) 
               := tv(N, cfg:wcharut))
          ~> writeWString(Loc +bytes 4, S)
          [structural] 
     rule [write-empty-string]:
          writeString(_, "") => .
          [structural]
     rule [write-empty-wstring]:
          writeWString(_, .KList) => .
          [structural]
          
     rule [pointerToString]:
          pointerToString(loc(N:SymBase, M:Int, 0))
          => "[sym(" +String subPointerToString(N) +String ") + " 
               +String Int2String(M) +String "]"
          [structural]
          
     rule [subPointerToString-auto]:
          subPointerToString(B:Int @ Th:Int)
          => "(" +String Int2String(B) +String 
               " @ " +String Int2String(Th) +String ")"
          [structural]
     rule [sub-pointerToString-allocated]:
          subPointerToString(B:Int @ allocatedDuration)
          => "(" +String Int2String(B) +String 
               " @ " +String "allocatedDuration)" 
          [structural]
     
     rule [pointerToString-done]:
          pointerToString(NullPointer) => "NullPointer" 
          [structural]
          
     rule piece(N:Int, Len:Int) bit:: piece(N':Int, Len':Int)
          => piece((N <<Int Len') |Int N', Len +Int Len')
          [structural, anywhere]
     rule piece(0, 0) bit:: N:Bits => N
          [structural, anywhere]
     rule piece(piece(N:Bits, Len:Int), Len:Int) => piece(N, Len) 
          [structural, anywhere]
     rule value(tv(V:KList, _)) => V:KList
          [structural, anywhere]

     rule type(tv(_, T:KResult)) => T
          [structural, anywhere]
     rule type(T:Type) => T
          [structural, anywhere]
     rule type(lv(_, T:KResult)) => T
          [structural, anywhere]
     rule type(lval(_, T:KResult)) => T
          [structural, anywhere]
     
endmodule

