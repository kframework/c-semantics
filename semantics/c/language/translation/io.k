module C-IO
     imports C-CONFIGURATION
     imports ARRAY
     imports BOOL
     imports INT
     imports MAP
     imports BITS-SYNTAX
     imports MEMORY-SYNTAX
     imports SETTINGS-SYNTAX
     imports SYMLOC-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-TYPING-EFFECTIVE-SYNTAX
     imports C-TYPING-SYNTAX

     rule initBytes(Loc::SymLoc, ListItem(V:Bits) L::List)
          => initBytesFill(Loc, 1, V) ~> initBytes(Loc +bytes 1, L)
          [structural]
     rule initBytes(_, .List) => .K
          [structural]

     rule initBytesFill(loc(_, _, _) #as Loc::SymLoc => stripProv(Loc), _, _)

     rule <k> initBytesFill(loc(Base::SymBase, Offset::Int), N::Int, V::Bits) => .K ...</k>
          <mem> M::Map => fillBuffer(M, Base, M[Base], Offset, N, V) </mem>
          [structural]

     syntax Map ::= fillBuffer(Map, SymBase, K, Int, Int, Bits) [function]
     rule fillBuffer(M::Map, Base::SymBase, object(T::EffectiveType, Len::Int, Bytes::Array), Offset::Int, N::Int, V::Bits)
          => M[Base <- object(T, Len, fillArray(Bytes, Offset, N, V))]

     rule readBytes(Loc:SymLoc, Size:Int, _)
          => readBytes'(stripProv(Loc), Size, .List)
          [structural]
     rule readBytesForWriting(Loc:SymLoc, Size:Int)
          => readBytes'(stripProv(Loc), Size, .List)
          [structural]

     // loc, size in bytes, aux list
     syntax KItem ::= "readBytes'" "(" SymLoc "," Int "," List ")"
     rule <k> readBytes'(loc(Base::SymBase, Offset::Int), Size::Int, Aux::List)
               => readBytes'(loc(Base, Offset) +bytes 1, Size -Int 1,
                    Aux ListItem(M[Offset]))
          ...</k>
          <mem>...
               Base |-> object(_, _, M::Array)
          ...</mem>
          requires Offset in_keys(M)
               andBool M[Offset] =/=K uninit
               andBool Size >Int 0
          [structural]
     rule <k> readBytes'(loc(Base::SymBase, Offset::Int), Size::Int, Aux::List)
               => readBytes'(loc(Base, Offset) +bytes 1, Size -Int 1,
                    Aux ListItem(piece(0, cfg:bitsPerByte)))
          ...</k>
          <mem>...
               Base |-> object(_, _,
                    M::Array => M[Offset <- piece(0, cfg:bitsPerByte)])
          ...</mem>
          requires (notBool (Offset in_keys(M)) orBool M[Offset] ==K uninit)
               andBool Size >Int 0
          [structural]
     rule readBytes'(_, 0, Aux:List) => dataList(Aux)
          [structural]

     rule checkEffectiveType(...) => .K
     rule adjustPointerBounds(V::RValue) => V

endmodule
