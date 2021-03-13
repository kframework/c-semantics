module BITS-SORTS
     imports INT-SYNTAX
     imports FLOAT-SYNTAX
     syntax EncodableOrBitValue ::= Int | Trap | Unknown
     syntax Encodable ::= EncodableOrBitValue
                        | PtrValue | EncodableValue
     syntax BitValue ::= EncodableOrBitValue | Pieces
                       | EncodedPtr | EncodedValue
     syntax EncodableValue ::= Float | Unknown
     syntax IntPtr ::= EncodedPtr
     syntax Unknown
     syntax Trap
     syntax Pieces
     syntax DataList
     syntax PtrValue
     syntax EncodableValue
     syntax EncodedValue
     syntax EncodedPtr
     syntax EffectiveValue
endmodule

module BITS-SYNTAX
     imports BITS-SORTS
     imports COMMON-SORTS
     imports SYMLOC-SORTS
     imports INT-SYNTAX
     imports LIST

     syntax Trap ::= "trap" [klabel(trap)]
     syntax Unknown ::= unknown(EffectiveValue)

     syntax Bits ::= piece(BitValue, Int)
     syntax Bits ::= Bits "bit::" Bits [function]

     syntax Pieces ::= pieces(List)

     // object, bit range (from, to, inclusive, 0th is least significant)
     syntax Bits ::= encode(Encodable, Int, Int) [function]

     syntax EncodedPtr ::= encodedPtr(PtrValue, Int, Int)
     syntax EncodedValue ::= encodedValue(EncodableValue, Int, Int)

     syntax DataList ::= dataList(List)
     syntax KResult ::= DataList

     // Value of a bitrange within an int.
     syntax Int ::= bitsValue(Int, Int, Int) [function]

     syntax List ::= explodeToBits(List) [function]
     syntax List ::= splitToBytes(Bits) [function]
     syntax List ::= splitToPartialBytes(Bits) [function]

     syntax BitValue ::= joinBytes(List) [function]

     syntax Bool ::= isFullFloat(Float, Int) [function]

endmodule

module BITS
     imports BITS-SYNTAX
     imports INT
     imports FLOAT
     imports SETTINGS-SYNTAX
     imports SYMLOC-SYNTAX
     imports BITS-SYNTAX
     imports C-SETTINGS-SYNTAX

     rule base(encodedPtr(S:SymLoc, _, _)) => base(S)
     rule sameBase((encodedPtr(S:SymLoc, _, _) => S), _)
     rule sameBase(_, (encodedPtr(S:SymLoc, _, _) => S))

     rule X::Bits bit:: Y::Bits => joinPieces(X, Y)
          requires piecesJoinable(X, Y)
     rule piece(pieces(Ps::List), Len::Int) bit:: piece(pieces(Ps'::List), Len'::Int)
          => piece(pieces(joinAllPieces(Ps Ps')), Len +Int Len')
     rule piece(pieces(Ps::List), Len::Int) bit:: piece(V'::BitValue, Len'::Int)
          => piece(pieces(joinAllPieces(Ps ListItem(piece(V', Len')))), Len +Int Len')
          requires notBool isPieces(V')
     rule piece(V::BitValue, Len::Int) bit:: piece(pieces(Ps'::List), Len'::Int)
          => piece(pieces(joinAllPieces(ListItem(piece(V, Len)) Ps')), Len +Int Len')
          requires notBool isPieces(V)
     rule piece(V::BitValue, Len::Int) bit:: piece(V'::BitValue, Len'::Int)
          => piece(pieces(ListItem(piece(V, Len)) ListItem(piece(V', Len'))), Len +Int Len')
          [owise]

     syntax Bool ::= piecesJoinable(Bits, Bits) [function]
     rule piecesJoinable(piece(_N:Int, _), piece(_N':Int, _)) => true
     rule piecesJoinable(piece(unknown(_N:Int), _), piece(unknown(_N':Int), _)) => true
     rule piecesJoinable(piece(trap, _), piece(trap, _)) => true
     rule piecesJoinable(piece(encodedPtr(N::PtrValue, _From::Int, To::Int), _), piece(encodedPtr(N, To, _), _)) => true
     rule piecesJoinable(piece(encodedValue(N::EncodableValue, _From::Int, To::Int), _), piece(encodedValue(N, To, _), _)) => true
     rule piecesJoinable(_, _) => false [owise]

     syntax Bits ::= joinPieces(Bits, Bits) [function]
     rule joinPieces(piece(N:Int, Len::Int), piece(N':Int, Len'::Int))
          => piece((N' <<Int Len) |Int N, Len +Int Len')
     rule joinPieces(piece(unknown(N:Int), Len::Int), piece(unknown(N':Int), Len'::Int))
          => piece(unknown((N' <<Int Len) |Int N), Len +Int Len')
     rule joinPieces(piece(trap, Len::Int), piece(trap, Len'::Int))
          => piece(trap, Len +Int Len')
     rule joinPieces(piece(encodedPtr(N::PtrValue, From::Int, To::Int), Len::Int), piece(encodedPtr(N, To, To'::Int), Len'::Int))
          => piece(encodedPtr(N, From, To'), Len +Int Len')
     rule joinPieces(piece(encodedValue(N::EncodableValue, From::Int, To::Int), Len::Int), piece(encodedValue(N, To, To'::Int), Len'::Int))
          => piece(encodedValue(N, From, To'), Len +Int Len')

     syntax List ::= joinAllPieces(List) [function]
     rule joinAllPieces(ListItem(X::Bits) ListItem(Y::Bits) Bs::List)
          => joinAllPieces(ListItem(joinPieces(X, Y)) Bs)
          requires piecesJoinable(X, Y)
     rule joinAllPieces(Bs::List) => Bs [owise]

     rule encode(N:Int, From::Int, To::Int)
          => piece(bitsValue(N, From, To), To -Int From)
          requires To >=Int From
     rule encode(unknown(N:Int), From::Int, To::Int)
          => piece(unknown(bitsValue(N, From, To)), To -Int From)
          requires To >=Int From
     rule encode(V:Trap, From::Int, To::Int)
          => piece(V, To -Int From)
          requires To >=Int From
     rule encode(V:PtrValue, From::Int, To::Int)
          => piece(encodedPtr(V, From, To), To -Int From)
          requires To >=Int From
     rule encode(V:EncodableValue, From::Int, To::Int)
          => piece(encodedValue(V, From, To), To -Int From)
          requires To >=Int From [owise]

     syntax Int ::= bitmask(Int) [function]
     rule bitmask(N::Int) => (1 <<Int N) -Int 1

     rule bitsValue(N::Int, From::Int, To::Int)
          => (N >>Int From) &Int bitmask(To -Int From)

     rule explodeToBits(ListItem(K:Bits) L::List)
          => explodeToBits(ListItem(K)) explodeToBits(L)
          requires L =/=K .List
     rule explodeToBits(ListItem(piece(pieces(L::List), _)) L'::List)
          => explodeToBits(L) explodeToBits(L')
     rule explodeToBits(ListItem(piece(V::BitValue, Len::Int)))
          => splinter(V, 0, Len, 1)
          requires (Len >Int 0) andBool notBool isPieces(V)
     rule explodeToBits(ListItem(piece(_, 0))) => .List
     rule explodeToBits(.List) => .List

     rule splitToBytes(piece(V::BitValue, Len::Int)) => splinter(V, 0, Len, cfg:bitsPerByte)
     rule splitToPartialBytes(piece(V::BitValue, Len::Int)) => splinterPartial(V, 0, Len, cfg:bitsPerByte)

     syntax List ::= splinter(BitValue, Int, Int, Int) [function]
     rule splinter(encodedPtr(V::PtrValue, From::Int, To::Int), Pos::Int, Len::Int, ChunkSize::Int)
          => ListItem(piece(encodedPtr(V, From, From +Int ChunkSize), ChunkSize))
               splinter(encodedPtr(V, From +Int ChunkSize, To), Pos +Int ChunkSize, Len, ChunkSize)
          requires (From <Int To) andBool (Pos <Int Len)
     rule splinter(encodedValue(V::EncodableValue, From::Int, To::Int), Pos::Int, Len::Int, ChunkSize::Int)
          => ListItem(piece(encodedValue(V, From, From +Int ChunkSize), ChunkSize))
               splinter(encodedValue(V, From +Int ChunkSize, To), Pos +Int ChunkSize, Len, ChunkSize)
          requires (From <Int To) andBool (Pos <Int Len)
     rule splinter(V::BitValue, Pos::Int, Len::Int, ChunkSize::Int)
          => ListItem(encode({V}:>Encodable, Pos, Pos +Int ChunkSize))
               splinter(V, Pos +Int ChunkSize, Len, ChunkSize)
          requires (Pos <Int Len) andBool isEncodable(V)
     rule splinter(V::BitValue, _, _, _) => .List
          requires notBool isPieces(V)
          [owise]

     syntax List ::= splinterPartial(BitValue, Int, Int, Int) [function]
     rule splinterPartial(encodedPtr(V::PtrValue, From::Int, To::Int), Pos::Int, Len::Int, ChunkSize::Int)
          => ListItem(piece(encodedPtr(V, From, From +Int ChunkSize), ChunkSize))
               splinterPartial(encodedPtr(V, From +Int ChunkSize, To), Pos +Int ChunkSize, Len, ChunkSize)
          requires (From <Int To) andBool (Pos <Int Len) andBool (From +Int ChunkSize) <=Int To
     rule splinterPartial(encodedPtr(V::PtrValue, From::Int, To::Int), Pos::Int, Len::Int, ChunkSize::Int)
          => ListItem(piece(encodedPtr(V, From, To), To -Int From))
          requires (From <Int To) andBool (Pos <Int Len) andBool (From +Int ChunkSize) >Int To
     rule splinterPartial(encodedValue(V::EncodableValue, From::Int, To::Int), Pos::Int, Len::Int, ChunkSize::Int)
          => ListItem(piece(encodedValue(V, From, From +Int ChunkSize), ChunkSize))
               splinterPartial(encodedValue(V, From +Int ChunkSize, To), Pos +Int ChunkSize, Len, ChunkSize)
          requires (From <Int To) andBool (Pos <Int Len) andBool (From +Int ChunkSize) <=Int To
     rule splinterPartial(encodedValue(V::EncodableValue, From::Int, To::Int), Pos::Int, Len::Int, ChunkSize::Int)
          => ListItem(piece(encodedValue(V, From, To), To -Int From))
          requires (From <Int To) andBool (Pos <Int Len) andBool (From +Int ChunkSize) >Int To
     rule splinterPartial(V::BitValue, Pos::Int, Len::Int, ChunkSize::Int)
          => ListItem(encode({V}:>Encodable, Pos, Pos +Int ChunkSize))
               splinterPartial(V, Pos +Int ChunkSize, Len, ChunkSize)
          requires (Pos <Int Len) andBool isEncodable(V) andBool (Pos +Int ChunkSize) <=Int Len
     rule splinterPartial(V::BitValue, Pos::Int, Len::Int, ChunkSize::Int)
          => ListItem(encode({V}:>Encodable, Pos, Len))
          requires (Pos <Int Len) andBool isEncodable(V) andBool (Pos +Int ChunkSize) >Int Len
     rule splinterPartial(V::BitValue, _, _, _) => .List
          requires notBool isPieces(V)
          [owise]

     // Fold bit:: over the list.
     syntax BitValue ::= "joinBytes'" "(" List "," Bits ")" [function]
     rule joinBytes(ListItem(N:Bits) L::List)
          => joinBytes'(L, N)
     rule joinBytes'(ListItem(N':Bits) L::List, N::Bits)
          => joinBytes'(L, N bit:: N')
     rule joinBytes'(.List, piece(N::BitValue, _)) => N

     rule isFullFloat(F:Float, N::Int) => true
          requires precisionFloat(F) ==K cfg:precisionofFloat
               andBool exponentBitsFloat(F) ==K cfg:exponentofFloat
               andBool N ==Int (cfg:sizeofFloat *Int cfg:bitsPerByte)
     rule isFullFloat(F:Float, N::Int) => true
          requires precisionFloat(F) ==K cfg:precisionofDouble
               andBool exponentBitsFloat(F) ==K cfg:exponentofDouble
               andBool N ==Int (cfg:sizeofDouble *Int cfg:bitsPerByte)
     rule isFullFloat(F:Float, N::Int) => true
          requires precisionFloat(F) ==K cfg:precisionofLongDouble
               andBool exponentBitsFloat(F) ==K cfg:exponentofLongDouble
               andBool N ==Int (cfg:sizeofLongDouble *Int cfg:bitsPerByte)
     rule isFullFloat(F:Float, N::Int) => true
          requires precisionFloat(F) ==K cfg:precisionofOversizedFloat
               andBool exponentBitsFloat(F) ==K cfg:exponentofOversizedFloat
               andBool N ==Int (cfg:sizeofOversizedFloat *Int cfg:bitsPerByte)
     rule isFullFloat(_, _) => false [owise]
endmodule
