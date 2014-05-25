module C-BITS-SYNTAX

     syntax Bits ::= Int

     syntax Trap ::= "trap"
     syntax Unknown ::= "unknown"
     syntax Bits ::= Trap
     syntax Bits ::= Unknown

     syntax Bits ::= piece(Bits, Int)
     syntax Bits ::= Bits "bit::" Bits

     // original number, from, to inclusive
     syntax Bits ::= bitRange(Bits, Int, Int)

     // loc, size in bytes
     syntax Bits ::= encodedFloat(Float)
     // object, start piece, end piece
     syntax Bits ::= subObject(SymLoc, Int, Int)

     syntax K ::= fillToBytes(K) [strict] 
     syntax K ::= "fillToBytes-aux" "(" K "," List ")" [function]

     syntax DataList ::= dataList(List)
     syntax KResult ::= DataList

     syntax Bits ::= 
                   "~Bits" Bits
                   [function, latex(\mathop{\sim_{\scriptstyle\it Bits}}{#1})]
                   > left:
                   Bits "/Bits" Bits
                   [function, left, latex({#1}\mathrel{\div_{\scriptstyle\it Bits}}{#2})]
                   > left:
                   Bits "&Bits" Bits
                   [function, left, latex({#1}\mathrel{\&_{\scriptstyle\it Bits}}{#2})]
                   > left:
                   Bits "xorBits" Bits
                   [function, left, latex({#1}\mathrel{\oplus_{\scriptstyle\it Bits}}{#2})]
                   > left:
                   Bits "|Bits" Bits
                   [function, left, latex({#1}\mathrel{|_{\scriptstyle\it Bits}}{#2})]

endmodule

module C-BITS
     imports C-BITS-SYNTAX

     imports C-SETTINGS-SYNTAX

     // this maintains byte order
     rule fillToBytes(dataList(L:List)) 
          => fillToBytes-aux(dataList(L), .List) 
          [structural]
     rule fillToBytes-aux(dataList(
               L:List ListItem(piece(N:Bits, Len:Int))), 
               L':List)
          => fillToBytes-aux(dataList(L), ListItem(piece(N, Len)) L')
          when Len ==Int cfg:bitsPerByte
          [structural]
     
     rule fillToBytes-aux(dataList(ListItem(piece(N:Bits, Len:Int))), L':List)
          => fillToBytes-aux(dataList(
               ListItem(piece(0, 1)) ListItem(piece(N, Len))),
               L')
          when Len <Int cfg:bitsPerByte
          [structural]
          
     rule fillToBytes-aux(dataList(
               L:List ListItem(piece(N:Bits, Len:Int))
               ListItem(piece(N':Bits, Len':Int))), L':List)
          => fillToBytes-aux(dataList(L ListItem(piece(piece(N, Len) 
               bit:: piece(N', Len'), Len +Int Len'))), L')
          when Len +Int Len' <=Int cfg:bitsPerByte
          [structural]
                    
     rule fillToBytes-aux(dataList(.List), L:List) => dataList(L)
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
     rule piece(0, 0) bit:: N:Bits => N
          [structural, anywhere]
     rule piece(piece(N:Bits, Len:Int), Len:Int) => piece(N, Len) 
          [structural, anywhere]

     rule bitRange(N:Bits bit:: piece(_, Len:Int), Pos:Int, Pos)
          => bitRange(N, absInt(Pos -Int Len), absInt(Pos -Int Len))
          when (Pos >Int 0) andBool (Pos -Int Len >=Int 0)
          [structural, anywhere]
          
     rule bitRange(_ bit:: piece(N:Bits, 1), 0, 0) => piece(N, 1)
          [structural, anywhere]
     rule bitRange(piece(N:Bits, 1), 0, 0) => piece(N, 1)
          [structural, anywhere]
          
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
          
     rule piece(N:Int, Len:Int) bit:: piece(N':Int, Len':Int)
          => piece((N <<Int Len') |Int N', Len +Int Len')
          [structural, anywhere]

     // Shouldn't really ever see traps or unknowns here, but it might be nice
     // to at least support unknowns in these operations at some point.
     rule ~Bits N:Int => ~Int N
     rule ~Bits trap => trap
     rule ~Bits unknown => unknown
     
     rule M:Int /Bits N:Int => M /Int N
     rule trap /Bits M:Int => trap
          when M =/=Int 0
     rule unknown /Bits M:Int => unknown
          when M =/=Int 0

     rule M:Int xorBits N:Int => M xorInt N
     rule _ xorBits trap => trap
     rule trap xorBits _ => trap
     rule _ xorBits unknown => unknown
     rule unknown xorBits _ => unknown

     rule X:Int |Bits Y:Int => X |Int Y
     rule _ |Bits trap => trap
     rule trap |Bits _ => trap
     rule _ |Bits unknown => unknown
     rule unknown |Bits _ => unknown

     rule X:Int &Bits Y:Int => X &Int Y
     rule _ &Bits trap => trap
     rule trap &Bits _ => trap
     rule 0 &Bits unknown => 0
     rule N:Int &Bits unknown => unknown
          when N =/=Int 0 
     rule unknown &Bits 0 => 0
     rule unknown &Bits N:Int => unknown
          when N =/=Int 0

endmodule
