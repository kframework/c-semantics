module C-BITS-SYNTAX
     imports C-SYMLOC-SYNTAX

     syntax Trap ::= "trap" [klabel(trap)]
     syntax Unknown ::= unknown(Int)
     syntax Bits ::= Trap
     syntax Bits ::= Unknown

     syntax Bits ::= piece(Bits, Int)
     syntax Bits ::= Bits "bit::" Bits

     // original number, from, to inclusive
     syntax Bits ::= bitRange(Bits, Int, Int)

     // value, (length - byte-offset), type
     syntax Bits ::= encodedFloat(Float, Int, Int, UType)
     // object, start piece, end piece
     syntax SubObject ::= subObject(SymLoc, Int, Int)
     syntax Bits ::= SubObject
     syntax IntPtr ::= SubObject

     syntax KItem ::= fillToBytes(K) [strict]
     syntax KItem ::= "fillToBytes-aux" "(" K "," List ")" [function]

     syntax DataList ::= dataList(List)
     syntax KResult ::= DataList

     syntax KItem ::= makeUnknown(K) [function, klabel(makeUnknown1)]
     syntax KItem ::= makeUnknown2(K) [strict]
     syntax KItem ::= stripUnknown(K) [function]

     syntax Int ::= maxIntPtrValue(IntPtr) [function]
     syntax SymLoc ::= locOf(SubObject) [function]

endmodule

module C-BITS
     imports C-BITS-SYNTAX
     imports COMPAT-SYNTAX
     imports C-SETTINGS-SYNTAX

     rule base(subObject(S:SymLoc, _, _)) => base(S)
     rule sameBase((subObject(S:SymLoc, _, _) => S), _)
     rule sameBase(_, (subObject(S:SymLoc, _, _) => S))
     rule locOf(subObject(S:SymLoc, _, _)) => S

     // this maintains byte order
     rule fillToBytes(dataList(L:List))
          => fillToBytes-aux(dataList(L), .List)
          [structural]
     rule fillToBytes-aux(dataList(
               L:List ListItem(piece(N:Bits, Len:Int))),
               L':List)
          => fillToBytes-aux(dataList(L), ListItem(piece(N, Len)) L')
          requires Len ==Int cfg:bitsPerByte
          [structural]

     rule fillToBytes-aux(dataList(ListItem(piece(N:Bits, Len:Int))), L':List)
          => fillToBytes-aux(dataList(
               ListItem(piece(0, 1)) ListItem(piece(N, Len))),
               L')
          requires Len <Int cfg:bitsPerByte
          [structural]

     rule fillToBytes-aux(dataList(
               L:List ListItem(piece(N:Bits, Len:Int))
               ListItem(piece(N':Bits, Len':Int))), L':List)
          => fillToBytes-aux(dataList(L ListItem(piece(piece(N, Len)
               bit:: piece(N', Len'), Len +Int Len'))), L')
          requires Len +Int Len' <=Int cfg:bitsPerByte
          [structural]

     rule fillToBytes-aux(dataList(.List), L:List) => dataList(L)
          [structural]

     rule makeUnknown(tv(I:Int, T::UType)) => tv(unknown(I), T)
     rule makeUnknown(R::RValue) => R [owise]
     rule makeUnknown2(R:RValue) => makeUnknown(R)
     rule stripUnknown(tv(unknown(I:Int), T::UType)) => tv(I, T)
     rule stripUnknown(tv(V::CValue, T::UType)) => tv(V, T)
          requires notBool isUnknown(V)

     rule maxIntPtrValue(_:SymLoc) => (1 <<Int (cfg:bitsPerByte *Int cfg:ptrsize -Int 1)) -Int 1
     rule maxIntPtrValue(subObject(_, N:Int, M:Int)) => (1 <<Int (cfg:bitsPerByte *Int (M -Int N +Int 1) -Int 1)) -Int 1

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
