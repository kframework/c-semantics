module C-COMMON-EXTENSIONS
  imports C-ERROR-SYNTAX
  imports C-SYMLOC-SYNTAX
  imports C-CONFIGURATION

  syntax Expression ::= DotBit(K, CId)
  syntax Expression ::= K "." Int [left, strict(1), klabeal(dotBit)]

  rule DotBit(K:K, Identifier(S:String)) => K . String2Int(S)

  rule <k> nclv(Loc:SymLoc, T:IntegerType) . Offset:Int 
           => lookupFieldBit(Offset, Loc, T) ...</k>

  syntax KItem ::= lookupFieldBit(Int, SymLoc, Type) [function]
  rule lookupFieldBit(Offset:Int, Loc:SymLoc, T:Type) => lv(setBitOffset(Offset, Loc, t(getModifiers(T), bitfieldType(T, 1))), t(getModifiers(T), bitfieldType(T, 1)))
  requires Offset >=Int 0 andBool Offset <Int bitSizeofType(T)
  rule lookupFieldBit(_, _, _) => EXT-CV("78K0R1", "Invalid bit access pattern", "R20UT2140E", "3.2.4, \"bit type variables\"") [owise]

  rule <k> tv(V:Int, T:IntegerType) . Offset:Int
           => concretize(t(getModifiers(T), bitfieldType(T, 1)), fillToBytes(dataList(bitRange(V, Offset, Offset)))) ...</k>
  requires Offset >=Int 0 andBool Offset <Int bitSizeofType(T)
  rule <k> (.K => EXT-CV("78K0R1", "Invalid bit access pattern", "R20UT2140E", "3.2.4, \"bit type variables\""))
           ~> tv(_, T:IntegerType) . Offset:Int ...</k>
  requires notBool (Offset >=Int 0 andBool Offset <Int bitSizeofType(T))

endmodule
