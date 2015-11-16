module C-MEMORY-ALLOC-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX

     /* object(type, size, byte map, effective type map) */
     syntax KItem ::= object(Type, Int, Map, Map)

     syntax KItem ::= alloc(SymBase, Type, Int)

     syntax KItem ::= zeroObject(SymBase)

     syntax KItem ::= sizeofObject(SymBase)

     syntax KItem ::= allocObject(SymBase, Type)
endmodule

module C-MEMORY-ALLOC
     imports C-MEMORY-ALLOC-SYNTAX

     imports C-ALIGNMENT-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-ERROR-SYNTAX

     imports C-CONFIGURATION

     rule allocObject(Base:SymBase, T:Type) => #allocObject(Base, T, sizeof(T))
          requires notBool isVoidType(T)
          [structural]
     rule allocObject(_, _:VoidType) => .K
          [structural]

     syntax KItem ::= #allocObject(SymBase, Type, K)
     context #allocObject(_, _, (HOLE:KItem => reval(HOLE))) [result(RValue)]
     rule #allocObject(Base:SymBase, T:Type, tv(I:Int, _))
          => alloc(Base, T, I)
          [structural]

     rule <k> alloc(Base:SymBase, T:Type, Len:Int) => .K ...</k>
          <mem>...
               .Map => Base |-> object(stripStorageSpecifiers(T), Len, .Map, .Map)
          ...</mem>
          requires notBool isLinkerLoc(Base)
          [structural]

     // Used by calloc.
     syntax Map ::= createMap(List, Bits) [function]
     rule createMap(.List, _:Bits) => .Map
     rule createMap(ListItem(I:K) L:List, B:Bits) => (I |-> B) createMap(L, B)


     rule <k> zeroObject(Base:SymBase) => .K ...</k>
          <mem>...
               Base |-> object(_, Len:Int,
                    _ => createMap((0 to Len), piece(0, cfg:bitsPerByte)),
                    .Map)
          ...</mem>
          [structural]

     rule <k> sizeofObject(Base:SymBase)
               => tv(Len, t(.Set, cfg:sizeut))
          ...</k>
          <mem>... Base |-> object(_, Len:Int, _, _) ...</mem>
          [structural]

endmodule
