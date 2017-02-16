module BITS-SORTS
     imports INT-SYNTAX
     syntax BitValue ::= Int | Trap | Unknown | Pieces
     syntax Unknown
     syntax Trap
     syntax Pieces
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

     syntax Bits ::= piece(BitValue, Int)
     syntax Bits ::= Bits "bit::" Bits [function]

     syntax Pieces ::= pieces(List)

     // object, bit range (from, to, inclusive, 0th is least significant)
     syntax Bits ::= encode(EffectiveValue, Int, Int) [function]
     syntax BitValue ::= encodedValue(EffectiveValue, Int, Int)
     syntax SubObject ::= encodedValue(SymLoc, Int, Int)

     syntax BitValue ::= SubObject
     syntax IntPtr ::= SubObject

     syntax DataList ::= dataList(List)
     syntax KResult ::= DataList

     syntax SymLoc ::= locOf(SubObject) [function]

     // Value of a bitrange within an int.
     syntax Int ::= bitsValue(Int, Int, Int) [function]

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

     rule piece(N:Int, Len::Int) bit:: piece(N':Int, Len'::Int)
          => piece((N' <<Int Len) |Int N, Len +Int Len')
     rule piece(encodedValue(N::EffectiveValue, From::Int, To::Int), Len::Int)
          bit:: piece(encodedValue(N, To, To'::Int), Len'::Int)
          => piece(encodedValue(N, From, To'), Len +Int Len')
     rule piece(pieces(Ps::List), Len::Int) bit:: piece(pieces(Ps'::List), Len'::Int)
          => piece(pieces(Ps Ps'), Len +Int Len')
     rule piece(pieces(Ps::List), Len::Int) bit:: piece(V'::BitValue, Len'::Int)
          => piece(pieces(Ps ListItem(piece(V', Len'))), Len +Int Len')
          requires notBool isPieces(V')
     rule piece(V::BitValue, Len::Int) bit:: piece(pieces(Ps'::List), Len'::Int)
          => piece(pieces(ListItem(piece(V, Len)) Ps'), Len +Int Len')
          requires notBool isPieces(V)
     rule piece(V::BitValue, Len::Int) bit:: piece(V'::BitValue, Len'::Int)
          => piece(pieces(ListItem(piece(V, Len)) ListItem(piece(V', Len'))), Len +Int Len')
          [owise]

     rule encode(N:Int, From::Int, To::Int)
          => piece(bitsValue(N, From, To), To -Int From)
          requires To >=Int From
     rule encode(N::EffectiveValue, From::Int, To::Int)
          => piece(encodedValue(N, From, To), To -Int From)
          requires To >=Int From [owise]

     syntax Int ::= bitmask(Int) [function]
     rule bitmask(N::Int) => (1 <<Int N) -Int 1

     rule bitsValue(N::Int, From::Int, To::Int)
          => (N >>Int From) &Int bitmask(To -Int From)
endmodule
