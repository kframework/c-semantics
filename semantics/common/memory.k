module MEMORY-SYNTAX
     imports SYMLOC-SYNTAX
     imports ARRAY
     imports INT
     imports LIST

     syntax EffectiveType

     /* object(effective type, size, byte map) */
     syntax KItem ::= object(EffectiveType, Int, Array)

     syntax DataList ::= splitPointerBytes(SymLoc, Int) [function]
     syntax DataList ::= splitPointerBytes(SymLoc, Int, K, List) [function, klabel(splitPointerBytes2)]

endmodule

module MEMORY
     imports MEMORY-SYNTAX
     imports BITS-SYNTAX
     imports BITS-SYNTAX
     imports BITS-SYNTAX
     imports BITS-SYNTAX
     imports SETTINGS-SYNTAX

     rule splitPointerBytes(Loc:SymLoc, Len:Int)
          => splitPointerBytes(Loc, Len, 0, .List)
     rule splitPointerBytes(Loc:SymLoc, Len:Int, N:Int, L:List)
          => splitPointerBytes(Loc, Len -Int 1, N +Int 1,
               L ListItem(piece(subObject(Loc, N, N), cfg:bitsPerByte)))
          requires Len >Int 0
     rule splitPointerBytes(_, 0, _, L:List) => dataList(L:List)

endmodule
