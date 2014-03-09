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

     syntax K ::= bitSizeofList(List)
     syntax K ::= "bitSizeofList-aux" "(" K "," Int "," List ")" [strict(1)]
     
     rule sizeofType(T:Type)
          => cast(cfg:sizeut, byteSizeofType(T)) 
          [structural]

     syntax K ::= "byteSizeofType-aux" "(" K ")" [strict]
     rule byteSizeofType(T:Type)
          => byteSizeofType-aux(bitSizeofType(T)) 
          [structural, anywhere]
     rule byteSizeofType-aux(tv(N:CSize, _))
          => bitsToBytes(N)
          [structural]

     context bitSizeofList-aux(HOLE, _, _)
          when HOLE =/=K .K
     
      // TODO(chathhorn)
     rule bitSizeofList(L:List) => bitSizeofList-aux(.K, 0, L:List)
          [structural]
     rule bitSizeofList-aux((.K => bitSizeofType(T:K)),
               _:Int, (ListItem(T:K) => .List) _:List)
          [structural]
     rule bitSizeofList-aux((tv(Len':Int, _) => .K),
               (Len:Int => Len:Int +Int Len':Int), _)
          [structural]
     rule bitSizeofList-aux(.K, Len:Int, .List) 
          => tv(Len:Int, cfg:largestUnsigned)
          [structural]
          
     syntax K ::= maxBitSizeofList(List)
     syntax K ::= "maxBitSizeofList-aux" "(" List "," Int ")"
     rule maxBitSizeofList(L:List) => maxBitSizeofList-aux(L, 0)
          [structural, anywhere]
     rule maxBitSizeofList-aux(ListItem(T:KResult) L:List, N:Int)
          => bitSizeofType(T) ~> maxBitSizeofList-aux(L, N) 
          [structural] 
     rule (tv(N':Int, _) => .) 
          ~> maxBitSizeofList-aux(_:List, (N:Int => maxInt(N, N'))) 
          [structural] 
     rule maxBitSizeofList-aux(.List, N:Int) => tv(N, cfg:largestUnsigned)
          [structural] 
     
     rule bitSizeofType(t(_, arrayType(T:KResult, N:CSize))) 
          => bitSizeofType(T) * tv(N, cfg:largestUnsigned) 
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
     rule bitSizeofType(t(_, bitfieldType(_, N:CSize))) 
          => tv(N, cfg:largestUnsigned) 
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

     rule <k> bitSizeofType(t(_, structType(S:Id))) => bitSizeofList(L) 
          ...</k>
          <structs>... S:Id |-> aggregateInfo(L:List, _, _) ...</structs>
          [structural] 
     rule <k> bitSizeofType(t(_, unionType(S:Id))) => maxBitSizeofList(L) 
          ...</k>
          <structs>... S |-> aggregateInfo(L:List, _, _) ...</structs>
          [structural]
          
endmodule
