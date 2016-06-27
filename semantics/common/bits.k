module BITS-SYNTAX
     imports SYMLOC-SYNTAX

     syntax Trap ::= "trap" [klabel(trap)]
     syntax Unknown ::= unknown(Int)
     syntax Bits ::= Trap
     syntax Bits ::= Unknown

     syntax Bits ::= piece(Bits, Int)
     syntax Bits ::= Bits "bit::" Bits

     syntax Bits ::= Int

     // original number, from, to inclusive
     syntax Bits ::= bitRange(Bits, Int, Int)

     // object, start piece, end piece
     syntax SubObject ::= subObject(SymLoc, Int, Int)
     syntax Bits ::= SubObject
     syntax IntPtr ::= SubObject

     syntax DataList ::= dataList(List)
     syntax KResult ::= DataList

     syntax SymLoc ::= locOf(SubObject) [function]

endmodule

module BITS
     imports BITS-SYNTAX
     imports COMPAT-SYNTAX
     imports SETTINGS-SYNTAX

     rule base(subObject(S:SymLoc, _, _)) => base(S)
     rule sameBase((subObject(S:SymLoc, _, _) => S), _)
     rule sameBase(_, (subObject(S:SymLoc, _, _) => S))
     rule locOf(subObject(S:SymLoc, _, _)) => S

     // coallesce bitranges that are adjacent
     rule piece(bitRange(N::Bits, SuccTo:Int, To':Int), Len:Int)
               bit:: piece(bitRange(N, From:Int, To:Int), Len':Int)
          => piece(bitRange(N, From, To'), Len +Int Len')
          requires (Len +Int Len' <=Int cfg:bitsPerByte)
               andBool (SuccTo ==Int To +Int 1)
          [structural, anywhere]

     rule piece(N::Bits bit:: N'::Bits, Len:Int) bit:: piece(N''::Bits, Len':Int)
          => piece((N bit:: N') bit:: piece(N'', Len'), Len +Int Len')
          [structural, anywhere]
     rule piece(N''::Bits, Len':Int) bit:: piece(N::Bits bit:: N'::Bits, Len:Int)
          => piece((piece(N'', Len') bit:: N) bit:: N', Len +Int Len')
          [structural, anywhere]
     rule piece(0, 0) bit:: N::Bits => N
          [structural, anywhere]
     rule N::Bits bit:: piece(0, 0) => N
          [structural, anywhere]
     rule piece(piece(N::Bits, Len1::Int), Len2::Int) => piece(N, Len1)
          requires Len1 ==Int Len2
          [structural, anywhere]

     rule bitRange(N:Bits bit:: piece(_, Len:Int), Pos:Int, Pos)
          => bitRange(N, absInt(Pos -Int Len), absInt(Pos -Int Len))
          requires (Pos >Int 0) andBool (Pos -Int Len >=Int 0)
          [structural, anywhere]

     rule bitRange(_ bit:: piece(N:Bits, 1), 0, 0) => piece(N, 1)
          [structural, anywhere]
     rule bitRange(piece(N:Bits, 1), 0, 0) => piece(N, 1)
          [structural, anywhere]

     rule bitRange(piece(bitRange(N:Bits, Start:Int, End:Int), Len:Int), 0, 0)
          => bitRange(piece(bitRange(N, Start, Start), 1), 0, 0)
          requires Start +Int Len ==Int End +Int 1
               andBool (Len =/=Int 1 orBool Start =/=Int End)
          [structural, anywhere]

     rule bitRange(N:Int, Pos:Int, Pos:Int) => 1 &Int (N >>Int Pos)
          requires N >=Int 0
          [structural, anywhere]
     rule bitRange(piece(N:Int, 1), Pos:Int, Pos:Int) => 1 &Int (N >>Int Pos)
          requires N >=Int 0
          [structural, anywhere]

     rule bitRange(N:Bits, 0, To:Int) => N
          requires To +Int 1 ==Int cfg:bitsPerByte
          [structural, anywhere]

     rule bitRange(_ bit:: piece(N:Bits, Len:Int), Start:Int, End:Int)
          => bitRange(piece(N, Len), Start, End)
          requires End +Int 1 <=Int Len
          [structural, anywhere]

     rule bitRange(piece(N:Bits, SuccEnd:Int), 0, End:Int)
          => piece(N, End +Int 1)
          requires SuccEnd ==Int End +Int 1
          [structural, anywhere]
     rule bitRange(_ bit:: piece(N:Bits, SuccEnd:Int), 0, End:Int)
          => piece(N, End +Int 1)
          requires SuccEnd ==Int End +Int 1
          [structural, anywhere]

     rule bitRange(piece(N:Int, _), Pos:Int, Pos:Int)
          => (N >>Int Pos) &Int 1
          requires N >=Int 0
          [structural, anywhere]

     rule piece(N:Int, Len:Int) bit:: piece(N':Int, Len':Int)
          => piece((N <<Int Len') |Int N', Len +Int Len')
          [structural, anywhere]


endmodule
