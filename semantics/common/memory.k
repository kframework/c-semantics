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

     syntax BitValue ::= joinBytes(List) [function]

     syntax Bool ::= isFullFloat(Float, Int) [function]

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
               L ListItem(piece(encodedValue(Loc, N *Int cfg:bitsPerByte, (N +Int 1) *Int cfg:bitsPerByte), cfg:bitsPerByte)))
          requires Len >Int 0
     rule #splitValueBytes(_, 0, _, L:List) => dataList(L:List)

     rule #splitIntegerBytes(I:Int, Len:Int, L:List)
          => #splitIntegerBytes(I >>Int cfg:bitsPerByte, Len -Int 1,
               L ListItem(piece(I &Int byteMaskSet, cfg:bitsPerByte)))
          requires Len >Int 0
     rule #splitIntegerBytes(_, 0, L:List) => dataList(L)

     syntax Int ::= "byteMaskSet" [function]
     rule byteMaskSet => (1 <<Int cfg:bitsPerByte) -Int 1

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
     rule isFullFloat(_, _) => false [owise]

endmodule
