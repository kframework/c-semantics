module MEMORY-SYNTAX
     imports BITS-SYNTAX
     imports SYMLOC-SYNTAX
     imports ARRAY
     imports INT
     imports LIST

     syntax EffectiveType

     /* object(effective type, size, byte map) */
     syntax KItem ::= object(EffectiveType, Int, Array)

     syntax DataList ::= splitBytes(EffectiveValue, Int) [function]

     syntax IntPtr ::= joinPointerBytes(List, Bits) [function]
     syntax Int ::= joinIntegerBytes(List, Bits) [function]

endmodule

module MEMORY
     imports MEMORY-SYNTAX
     imports BITS-SYNTAX
     imports C-SETTINGS-SYNTAX

     syntax DataList ::= #splitValueBytes(EffectiveValue, Int, K, List) [function]
                       | #splitIntegerBytes(Int, Int, List) [function]

     rule splitBytes(Loc::EffectiveValue, Len:Int)
          => #splitValueBytes(Loc, Len, 0, .List)
          requires notBool isInt(Loc)
     rule splitBytes(I:Int, Len:Int)
          => #splitIntegerBytes(I, Len, .List)

     rule #splitValueBytes(Loc::EffectiveValue, Len:Int, N:Int, L:List)
          => #splitValueBytes(Loc, Len -Int 1, N +Int 1,
               L ListItem(piece(encodedValue(Loc, N, N), cfg:bitsPerByte)))
          requires Len >Int 0
     rule #splitValueBytes(_, 0, _, L:List) => dataList(L:List)

     rule #splitIntegerBytes(I:Int, Len:Int, L:List)
          => #splitIntegerBytes(I >>Int cfg:bitsPerByte, Len -Int 1,
               L ListItem(piece(I &Int byteMaskSet, cfg:bitsPerByte)))
          requires Len >Int 0
     rule #splitIntegerBytes(_, 0, L:List) => dataList(L)

     syntax Int ::= "byteMaskSet" [function]
     rule byteMaskSet => (1 <<Int cfg:bitsPerByte) -Int 1

     rule joinPointerBytes(ListItem(piece(encodedValue(Loc:SymLoc, SNatEnd::Int, SNatEnd::Int), Len::Int)) L::List,
               encodedValue(Loc, I::Int, End::Int))
          => joinPointerBytes(L, encodedValue(Loc, I, End +Int 1))
          requires Len ==Int cfg:bitsPerByte
               andBool SNatEnd ==Int End +Int 1
     rule joinPointerBytes(.List, encodedValue(Loc:SymLoc, 0, N::Int))
          => Loc
          requires N ==Int cfg:ptrsize -Int 1
     rule joinPointerBytes(.List, encodedValue(Loc:SymLoc, Begin::Int, End:Int))
          => encodedValue(Loc, Begin, End)
          requires End <Int cfg:ptrsize -Int 1 orBool Begin >Int 0

     rule joinIntegerBytes(ListItem(piece(N:Int, Len::Int)) L::List, piece(N':Int, Len'::Int))
          => joinIntegerBytes(L, piece(piece(N, Len) bit:: piece(N', Len'), Len +Int Len'))
     rule joinIntegerBytes(.List, piece(N:Int, _)) => N

endmodule
