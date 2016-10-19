module MEMORY-SORTS
     syntax EffectiveType
endmodule

module MEMORY-SYNTAX
     imports MEMORY-SORTS
     imports ARRAY
     imports BASIC-K
     imports INT-SYNTAX
     imports LIST
     imports BITS-SORTS
     imports COMMON-SORTS
     imports SYMLOC-SORTS

     /* object(effective type, size, byte map) */
     syntax KItem ::= object(EffectiveType, Int, Array)

     syntax DataList ::= splitBytes(EffectiveValue, Int) [function]

     syntax IntPtr ::= joinPointerBytes(List, Bits) [function]
     syntax Int ::= joinIntegerBytes(List, Bits) [function]
     syntax Float ::= joinFloatBytes(List, Bits) [function]

endmodule

module MEMORY
     imports MEMORY-SYNTAX
     imports INT
     imports FLOAT
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

     rule joinFloatBytes(ListItem(piece(encodedValue(F:Float, SNatEnd::Int, SNatEnd::Int), Len::Int)) L::List,
               encodedValue(F, I::Int, End::Int))
          => joinFloatBytes(L, encodedValue(F, I, End +Int 1))
          requires Len ==Int cfg:bitsPerByte
               andBool SNatEnd ==Int End +Int 1
     rule joinFloatBytes(.List, encodedValue(F:Float, 0, N::Int))
          => F
          requires isFullFloat(F, N)
     rule joinFloatBytes(.List, encodedValue(F:Float, Begin::Int, End::Int))
          => encodedValue(F, Begin, End)
          requires notBool isFullFloat(F, End) orBool Begin >Int 0

     syntax Bool ::= isFullFloat(Float, Int) [function]
     rule isFullFloat(F:Float, N::Int) => true
          requires precisionFloat(F) ==K cfg:precisionofFloat
               andBool exponentBitsFloat(F) ==K cfg:exponentofFloat
               andBool N +Int 1 ==Int cfg:sizeofFloat
     rule isFullFloat(F:Float, N::Int) => true
          requires precisionFloat(F) ==K cfg:precisionofDouble
               andBool exponentBitsFloat(F) ==K cfg:exponentofDouble
               andBool N +Int 1 ==Int cfg:sizeofDouble
     rule isFullFloat(F:Float, N::Int) => true
          requires precisionFloat(F) ==K cfg:precisionofLongDouble
               andBool exponentBitsFloat(F) ==K cfg:exponentofLongDouble
               andBool N +Int 1 ==Int cfg:sizeofLongDouble
     rule isFullFloat(_, _) => false [owise]

     rule joinIntegerBytes(ListItem(piece(N:Int, Len::Int)) L::List, piece(N':Int, Len'::Int))
          => joinIntegerBytes(L, piece(piece(N, Len) bit:: piece(N', Len'), Len +Int Len'))
     rule joinIntegerBytes(.List, piece(N:Int, _)) => N

endmodule
