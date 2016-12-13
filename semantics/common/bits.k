module BITS-SORTS
     imports INT-SYNTAX
     syntax Bits ::= Int | Trap | Unknown
     syntax Unknown
     syntax Trap
     syntax SubObject
     syntax DataList
endmodule

module BITS-SYNTAX
     imports BITS-SORTS
     imports COMMON-SORTS
     imports INT-SYNTAX
     imports LIST

     syntax Trap ::= "trap" [klabel(trap)]
     syntax Unknown ::= unknown(EffectiveValue)
     syntax Bits ::= Trap
     syntax Bits ::= Unknown

     syntax Bits ::= piece(Bits, Int)
     syntax Bits ::= Bits "bit::" Bits

     // original number, from, to inclusive
     syntax Bits ::= bitRange(Bits, Int, Int)

     // object, start piece, end piece
     syntax Bits ::= encodedValue(EffectiveValue, Int, Int)
     syntax SubObject ::= encodedValue(SymLoc, Int, Int)
     syntax Bits ::= SubObject
     syntax IntPtr ::= SubObject

     syntax DataList ::= dataList(List)
     syntax KResult ::= DataList

     syntax SymLoc ::= locOf(SubObject) [function]

endmodule

module BITS
     imports BITS-SYNTAX
     imports INT
     imports SETTINGS-SYNTAX
     imports SYMLOC-SYNTAX

     rule base(encodedValue(S:SymLoc, _, _)) => base(S)
     rule sameBase((encodedValue(S:SymLoc, _, _) => S), _)
     rule sameBase(_, (encodedValue(S:SymLoc, _, _) => S))
     rule locOf(encodedValue(S:SymLoc, _, _)) => S

     // coallesce bitranges that are adjacent
     rule piece(bitRange(N::Bits, From::Int, To::Int), Len::Int)
               bit:: piece(bitRange(N, From'::Int, To'::Int), Len':Int)
          => piece(bitRange(N, From, To'), Len +Int Len')
          requires (Len +Int Len' <=Int cfg:bitsPerByte)
               andBool (From' ==Int To +Int 1)
          [structural, anywhere]

     rule piece(N::Bits bit:: N'::Bits, Len::Int) bit:: piece(N''::Bits, Len'::Int)
          => piece(N bit:: (N' bit:: piece(N'', Len')), Len +Int Len')
          [structural, anywhere]
     rule piece(N''::Bits, Len'::Int) bit:: piece(N::Bits bit:: N'::Bits, Len::Int)
          => piece(piece(N'', Len') bit:: (N bit:: N'), Len +Int Len')
          [structural, anywhere]
     rule piece(0, 0) bit:: N::Bits => N
          [structural, anywhere]
     rule N::Bits bit:: piece(0, 0) => N
          [structural, anywhere]
     rule piece(piece(N::Bits, Len1::Int), Len2::Int) => piece(N, Len1)
          requires Len1 ==Int Len2
          [structural, anywhere]

     rule bitRange(piece(_, Len::Int) bit:: N::Bits, Pos::Int, Pos)
          => bitRange(N, absInt(Pos -Int Len), absInt(Pos -Int Len))
          requires (Pos >Int 0) andBool (Pos >=Int Len)
          [structural, anywhere]

     rule bitRange(piece(N::Bits, 1) bit:: _, 0, 0) => piece(N, 1)
          [structural, anywhere]
     rule bitRange(piece(N::Bits, 1), 0, 0) => piece(N, 1)
          [structural, anywhere]

     rule bitRange(piece(bitRange(N::Bits, From::Int, To::Int), Len::Int), 0, 0)
          => bitRange(piece(bitRange(N, From, From), 1), 0, 0)
          requires From +Int Len ==Int To +Int 1
               andBool (Len =/=Int 1 orBool From =/=Int To)
          [structural, anywhere]

     rule bitRange(N::Bits, 0, To::Int) => N
          requires To +Int 1 ==Int cfg:bitsPerByte
          [structural, anywhere]

     rule bitRange(piece(N::Bits, Len::Int) bit:: _, From::Int, To::Int)
          => bitRange(piece(N, Len), From, To)
          requires To <Int Len
          [structural, anywhere]

     rule bitRange(piece(N::Bits, SuccTo::Int), 0, To::Int)
          => piece(N, To +Int 1)
          requires SuccTo ==Int To +Int 1
          [structural, anywhere]
     rule bitRange(piece(N::Bits, Len::Int) bit:: _, 0, To::Int)
          => piece(N, To +Int 1)
          requires Len ==Int To +Int 1
          [structural, anywhere]

     rule bitRange(piece(N:Int, _), Pos::Int, Pos) => 1 &Int (N >>Int Pos)
          requires N >=Int 0
          [structural, anywhere]
     rule bitRange(N:Int, Pos::Int, Pos) => 1 &Int (N >>Int Pos)
          requires N >=Int 0
          [structural, anywhere]

     rule piece(N:Int, Len::Int) bit:: piece(N':Int, Len'::Int)
          => piece((N' <<Int Len) |Int N, Len +Int Len')
          [structural, anywhere]

     rule (B::Bits bit:: piece(N:Int, Len::Int)) bit:: piece(N':Int, Len'::Int)
          => B bit:: piece((N' <<Int Len) |Int N, Len +Int Len')
          [structural, anywhere]

endmodule
