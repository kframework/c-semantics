module C-BITS-SYNTAX
     syntax Ptr ::= Int | SymLoc

     syntax Bits ::= Int

     syntax Bits ::= piece(Bits, Int)
     syntax Bits ::= unknown(Int)
     syntax Bits ::= Bits "bit::" Bits

     // original number, from, to inclusive
     syntax Bits ::= bitRange(Bits, Int, Int)

     // loc, size in bytes
     syntax Bits ::= encodedFloat(Float)
     // object, start piece, end piece
     syntax Bits ::= subObject(Ptr, K, K)

     syntax Int ::= bitsToBytes(Int) [function]

     syntax K ::= fillToBytes(K) [strict] 
     syntax K ::= "fillToBytes-aux" "(" K "," KList ")" [function]

     syntax KResult ::= dataList(KList)

     syntax Bits ::= right:
                   "~Bits" Bits
                   [function, right, latex(\mathop{\sim_{\scriptstyle\it Bits}}{#1})]
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
     rule [fillToBytes-start]:
          fillToBytes(dataList(L:KList)) 
          => fillToBytes-aux(dataList(L), .KList) 
          [structural]
     rule [fillToBytes-foundByte]:
          fillToBytes-aux(dataList((L:KList,, 
               piece(N:Bits, Len:Int))), L':KList)
          => fillToBytes-aux(dataList(L), (piece(N, Len),, L'))
          when Len ==Int cfg:bitsPerByte
          [structural]
     
     rule [fillToBytes-addBit]:
          fillToBytes-aux(dataList(piece(N:Bits, Len:Int)), L':KList)
          => fillToBytes-aux(dataList((piece(0, 1),, piece(N, Len))), L')
          when Len <Int cfg:bitsPerByte
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
     rule piece(0, 0) bit:: N:Bits => N
          [structural, anywhere]
     rule piece(piece(N:Bits, Len:Int), Len:Int) => piece(N, Len) 
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
          
     rule piece(N:Int, Len:Int) bit:: piece(N':Int, Len':Int)
          => piece((N <<Int Len') |Int N', Len +Int Len')
          [structural, anywhere]

     //- derived
     rule bitsToBytes(N:Int) => absInt(N:Int /Int cfg:bitsPerByte)
          when cfg:bitsPerByte dividesInt N:Int
     rule bitsToBytes(N:Int) => absInt((N:Int /Int cfg:bitsPerByte) +Int 1) 
          when notBool cfg:bitsPerByte dividesInt N:Int

     // these could be so much better...
     rule ~Bits X:Int => ~Int X
     rule [bnot-unknown]: 
          ~Bits piece(unknown(Len:Int), Len:Int) 
          => piece(unknown(Len:Int), Len:Int)
     
     rule X:Int /Bits Y:Int => X /Int Y

     rule X:Int xorBits Y:Int => X xorInt Y
     rule [xor-unknown-right]: 
          _:Bits xorBits piece(unknown(Len:Int), Len:Int) 
          => piece(unknown(Len:Int), Len:Int)
     rule [xor-unknown-left]: 
          piece(unknown(Len:Int), Len:Int) xorBits _:Bits 
          => piece(unknown(Len:Int), Len:Int)

     rule X:Int |Bits Y:Int => X |Int Y
     rule [or-unknown-right]: 
          _:Bits |Bits piece(unknown(Len:Int), Len:Int) 
          => piece(unknown(Len:Int), Len:Int)
     rule [or-unknown-left]: 
          piece(unknown(Len:Int), Len:Int) |Bits _:Bits 
          => piece(unknown(Len:Int), Len:Int)

     rule X:Int &Bits Y:Int => X &Int Y
     rule [and-unknown-zero-right]:
          N:Int &Bits piece(unknown(Len:Int), Len)
          => 0
          when N ==Int 0 
     rule [and-unknown-right]:
          N:Int &Bits piece(unknown(Len:Int), Len)
          => 0
          when N =/=Int 0 
     rule [and-unknown-zero-left]:
          piece(unknown(Len:Int), Len) &Bits N:Int
          => 0
          when N ==Int 0 
     rule [and-unknown-left]:
          piece(unknown(Len:Int), Len) &Bits N:Int
          => 0
          when N =/=Int 0

endmodule
