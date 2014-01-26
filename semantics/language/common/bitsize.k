module C-BITSIZE-SYNTAX
     // needs to be heated to top of K for struct and union types
     syntax K ::= bitSizeofType(K) [strict]
     syntax K ::= byteSizeofType(Type)

     // generates a tv(size, cfg:sizeut)
     syntax K ::= sizeofType(K) [strict]
endmodule

module C-BITSIZE
     imports C-BITSIZE-SYNTAX

     imports C-BITS-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SETTINGS-SYNTAX

     syntax K ::= bitSizeofList(KList)
     syntax K ::= "bitSizeofList-aux" "(" K "," Int "," KList ")" [strict(1)]
     
     rule sizeofType(T:Type)
          => cast(cfg:sizeut, byteSizeofType(T)) 
          [structural]

     syntax K ::= "byteSizeofType-aux" "(" K ")" [strict]
     rule byteSizeofType(T:Type)
          => byteSizeofType-aux(bitSizeofType(T)) 
          [structural, anywhere]
     rule byteSizeofType-aux(V:TypedValue)
          => bitsToBytes(value(V))
          [structural]

     // TODO(chathhorn): BUG? Note doesn't heat when .K.
     rule bitSizeofList-aux(K:K, X:Int, L:KList)
          => K ~> bitSizeofList-aux(HOLE, X, L) 
          when notBool (K ==K .K) [heat]
     rule K:KResult ~> bitSizeofList-aux(HOLE, X:Int, L:KList)
          => bitSizeofList-aux(K, X, L) [cool]
     
      // TODO(chathhorn)
     rule bitSizeofList(L:KList) => bitSizeofList-aux(., 0, L:KList)
          [structural]
     rule bitSizeofList-aux((. => bitSizeofType(T:K)),
               _:Int, ((T:K => .KList),, _:KList))
          [structural]
     rule bitSizeofList-aux((tv(Len':Int, _) => .),
               (Len:Int => Len:Int +Int Len':Int), _)
          [structural]
     rule bitSizeofList-aux(., Len:Int, .KList) 
          => tv(Len:Int, cfg:largestUnsigned)
          [structural]
          
     syntax K ::= "maxBitSizeofList" "(" KList ")"
     syntax K ::= "maxBitSizeofList-aux" "(" KList "," Int ")"
     rule maxBitSizeofList(L:KList) => maxBitSizeofList-aux(L, 0)
          [structural, anywhere]
     rule maxBitSizeofList-aux((T:KResult,, L:KList), N:Int)
          => bitSizeofType(T) ~> maxBitSizeofList-aux(L, N) 
          [structural] 
     rule (tv(N':Int, _) => .) 
          ~> maxBitSizeofList-aux(_:KList, (N:Int => maxInt(N, N'))) 
          [structural] 
     rule maxBitSizeofList-aux(.KList, N:Int) => tv(N, cfg:largestUnsigned)
          [structural] 
     
     rule bitSizeofType(t(_, arrayType(T:KResult, N:Int))) 
          => bitSizeofType(T:KResult) * tv(N:Int, cfg:largestUnsigned) 
          [structural, anywhere]
     rule bitSizeofType(t(_, flexibleArrayType(_:KResult))) 
          => tv(0, cfg:largestUnsigned) 
          [structural, anywhere]
     rule bitSizeofType(t(_, functionType(_, _))) 
          => tv(cfg:bitsPerByte, cfg:largestUnsigned) 
          [structural, anywhere]
     rule bitSizeofType(t(_, pointerType(_))) 
          => tv(cfg:ptrsize *Int cfg:bitsPerByte, cfg:largestUnsigned) 
          [structural, anywhere]
     rule bitSizeofType(t(_, bitfieldType(_, N:Int))) 
          => tv(N:Int, cfg:largestUnsigned) 
          [structural, anywhere]
     rule bitSizeofType(t(_, qualifiedType(T:KResult, _))) 
          => bitSizeofType(T:KResult) 
          [structural, anywhere]
     rule bitSizeofType(T:Type) 
          => tv(numBits(T), cfg:largestUnsigned) 
          when isBasicType(T)
          [structural, anywhere]
     rule bitSizeofType(typedDeclaration(T:Type, _:Id)) 
          => bitSizeofType(T) 
          [structural, anywhere]

     rule <k> 
               bitSizeofType(t(_, structType(S:Id))) => bitSizeofList(L:KList) 
          ...</k>
          <structs>... S:Id |-> aggregateInfo(L:KList, _, _) ...</structs>
          [structural] 
     rule <k> 
               bitSizeofType(t(_, unionType(S:Id))) => maxBitSizeofList(L) 
          ...</k>
          <structs>... S |-> aggregateInfo(L:KList, _, _) ...</structs>
          [structural]
          
endmodule
