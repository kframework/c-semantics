module C-MEMORY-ALLOC-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX

     syntax KItem ::= object(Type, Int, Map)

     syntax KItem ::= writeString(SymLoc, String)
     syntax KItem ::= writeWString(SymLoc, List)

     syntax KItem ::= allocString(SymBase, String)
     syntax KItem ::= allocWString(SymBase, List)

     syntax KItem ::= alloc(SymBase, Type, Int)

     syntax KItem ::= zeroObject(SymBase)

     syntax KItem ::= sizeofObject(SymBase)

     syntax KItem ::= allocObject(SymBase, Type)
     syntax KItem ::= allocObjectIfAbsent(SymBase, Type)
endmodule

module C-MEMORY-ALLOC
     imports C-MEMORY-ALLOC-SYNTAX

     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-ERROR-SYNTAX

     imports COMPAT-SYNTAX

     rule writeString(Loc:SymLoc, S:String)
          => Computation(
               * tv(Loc, t(.Set, pointerType(t(.Set, char))))
               := tv(ordChar(firstChar(S:String)), t(.Set, char)))
               ~> writeString(Loc +bytes 1, butFirstChar(S:String))
          requires S:String =/=String ""
          [structural]
     // TODO this bare 4 needs to be updated to handle different size wchar_ts
     rule writeWString(Loc:SymLoc, ListItem(N:Int) S:List)
          => Computation(
               * tv(Loc, t(.Set, pointerType(t(.Set, cfg:wcharut))))
               := tv(N, t(.Set, cfg:wcharut)))
               ~> writeWString(Loc +bytes 4, S)
          [structural]
     rule writeString(Loc:SymLoc, "")
          => Computation(
               * tv(Loc, t(.Set, pointerType(t(.Set, char))))
               := tv(0, t(.Set, char)))
          [structural]
     rule writeWString(Loc:SymLoc, .List)
          => Computation(
               * tv(Loc, t(.Set, pointerType(t(.Set, cfg:wcharut))))
               := tv(0, t(.Set, cfg:wcharut)))
          [structural]

     rule allocObject(Base:SymBase, T:Type)
          => alloc(Base, T, byteSizeofType(T))
          [structural]
     rule <k> allocObjectIfAbsent(Base:SymBase, T:Type)
               => alloc(Base, T, byteSizeofType(T))
          ...</k>
          <mem> M:Map </mem>
          requires notBool (Base in (keys(M)))
          [structural]
     rule <k> allocObjectIfAbsent(Base:SymBase, _) => .K
          ...</k>
          <mem>... Base |-> object(_, _, _) ...</mem>
          [structural]

     rule <k> alloc(Base:SymBase, T:Type, Len:Int) => .K ...</k>
          <mem>...
               .Map => Base |-> object(stripStorageSpecifiers(T), Len, .Map)
          ...</mem>
          requires notBool isLinkerLoc(Base)
          [structural]

     // Used by calloc.
     syntax Map ::= createMap(KList, Bits) [function]
     rule createMap(.KList, _:Bits) => .Map
     rule createMap((I:K,, KL:KList), B:Bits) => (I |-> B) createMap(KL, B)

     rule <k> zeroObject(Base:SymBase) => .K ...</k>
          <mem>...
               Base |-> object(_, Len:Int,
                    _ => createMap((0 to Len), piece(0, cfg:bitsPerByte)))
          ...</mem>
          [structural]

     rule <k> sizeofObject(Base:SymBase)
               => tv(Len, t(.Set, cfg:sizeut))
          ...</k>
          <mem>... Base |-> object(_, Len:Int, _) ...</mem>
          [structural]

     rule allocString(Base:SymBase, S:String)
          => allocObject(Base, t(.Set,
               arrayType(t(.Set, char), lengthString(S) +Int 1)))
          ~> allowInit(writeString(lnew(Base), S))
          [structural]
     rule allocWString(Base:SymBase, S:List)
          => allocObject(Base, t(.Set,
               arrayType(t(.Set, cfg:wcharut), 4 *Int (size(S) +Int 1))))
          ~> allowInit(writeWString(lnew(Base), S))
          [structural]

endmodule
