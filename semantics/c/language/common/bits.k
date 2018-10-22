module C-BITS-SYNTAX
     imports BITS-SYNTAX
     imports FLOAT-SYNTAX
     imports C-TYPING-SORTS

     syntax KItem ::= fillToBytes(K) [strict]
     syntax KItem ::= "fillToBytes-aux" "(" K "," List ")" [function]

     syntax KItem ::= makeUnknown(K) [strict]
     syntax CValue ::= stripUnknown(CValue) [function]

     syntax Int ::= maxIntPtrValue(IntPtr) [function]
endmodule

module C-BITS
     imports C-BITS-SYNTAX
     imports BOOL
     imports INT
     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX

     // this maintains byte order
     rule fillToBytes(dataList(L::List))
          => fillToBytes-aux(dataList(L), .List)
          [structural]
     rule fillToBytes-aux(dataList(
               ListItem(piece(N::BitValue, Len::Int)) L::List),
               L'::List)
          => fillToBytes-aux(dataList(L), L' ListItem(piece(N, Len)))
          requires Len ==Int cfg:bitsPerByte
          [structural]

     rule fillToBytes-aux(dataList(ListItem(piece(N::BitValue, Len::Int))), L'::List)
          => fillToBytes-aux(dataList(
               ListItem(piece(N, Len)) ListItem(piece(0, 1))),
               L')
          requires Len <Int cfg:bitsPerByte
          [structural]

     rule fillToBytes-aux(dataList(
               ListItem(piece(N::BitValue, Len::Int))
               ListItem(piece(N'::BitValue, Len'::Int)) L::List), L'::List)
          => fillToBytes-aux(dataList(ListItem(piece(N, Len) bit:: piece(N', Len')) L), L')
          requires Len +Int Len' <=Int cfg:bitsPerByte
          [structural]

     rule fillToBytes-aux(dataList(.List), L::List) => dataList(L)
          [structural]

     rule makeUnknown(tv(I:Int, T::UType)) => tv(unknown(I), T)
     rule makeUnknown(tv(V::CValue, T::UType)) => tv(V, T)
          requires notBool isInt(V)

     rule stripUnknown(unknown(V::CValue)) => V
     rule stripUnknown(V::CValue) => V [owise]

     rule maxIntPtrValue(_:SymLoc) => (1 <<Int (cfg:bitsPerByte *Int cfg:ptrsize -Int 1)) -Int 1
     rule maxIntPtrValue(encodedPtr(_, N:Int, M:Int)) => (1 <<Int (cfg:bitsPerByte *Int (M -Int N +Int 1) -Int 1)) -Int 1
endmodule
