module C-IO-DIRECT
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
     imports C-TYPING-SYNTAX

     syntax KItem ::= writeBytes(SymLoc, DataList)
     syntax KItem ::= writeByte(SymLoc, Bits)

     rule writeBytes(Loc::SymLoc, D:DataList, _) => writeBytes(Loc, D)
          [structural]

     rule writeBytes(Loc::SymLoc, dataList(ListItem(V:Bits) L::List))
          => writeByte(Loc, V) ~> writeBytes(Loc +bytes 1, dataList(L))
          [structural]

     rule writeBytes(_, dataList(.List)) => .K
          [structural]

     rule <k> writeByte(loc(Base::SymBase, Offset::Int), V::Bits) => .K ...</k>
          <mem>...
               Base |-> object(_, Len:Int, (M::Array => M[Offset <- V]))
          ...</mem>
          requires Offset <Int Len
          [structural]

     rule readBytes(Loc:SymLoc, Size:Int, _)
          => readBytes'(Loc, Size, .List)
          [structural]
     rule readBytesForWriting(Loc:SymLoc, Size:Int, .List, _)
          => readBytes'(Loc, Size, .List)
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
          requires notBool (Offset in_keys(M))
               andBool Size >Int 0
          [structural]
     rule readBytes'(_, 0, Aux:List) => dataList(Aux)
          [structural]

endmodule
