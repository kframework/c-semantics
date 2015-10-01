module C-TRANSLATION-EXTENSIONS
  imports C-COMMON-EXTENSIONS

  rule <k> ncle(K:K, T:IntegerType) . Offset:Int => le(K . Offset, t(getModifiers(T), bitfieldType(T, 1))) ...</k>
  rule <k> te(K:K, T:IntegerType) . Offset:Int  =>  te(K . Offset, t(getModifiers(T), bitfieldType(T, 1))) ...</k>

endmodule
