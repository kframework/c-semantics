module C-MEMORY-ALLOC-SYNTAX
     imports MEMORY-SYNTAX
     imports C-TYPING-SORTS

     syntax KItem ::= alloc(SymBase, Type, Int)

     syntax KItem ::= zeroObject(SymBase)

     syntax KItem ::= sizeofObject(SymBase)

     syntax KItem ::= allocObject(SymBase, Type)

     syntax KItem ::= allocString(SymBase, String)
     syntax KItem ::= allocWString(SymBase, List)

endmodule

module C-MEMORY-ALLOC
     imports BITS-SYNTAX
     imports BOOL
     imports C-BITSIZE-SYNTAX
     imports C-CONFIGURATION
     imports C-DYNAMIC-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports INT
     imports STRING
     imports SYMLOC-SYNTAX

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

     rule <k> alloc(Base::SymBase, T::Type, Len::Int) => .K ...</k>
          <mem>...
               .Map => Base |-> object(stripStorageSpecifiers(T), Len, makeEmptyArray(Len))
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
                    _ => makeArray(Len, piece(0, cfg:bitsPerByte)))
          ...</mem>
          [structural]

     rule <k> sizeofObject(Base:SymBase) => tv(Len, utype(cfg:sizeut)) ...</k>
          <mem>... Base |-> object(_, Len:Int, _) ...</mem>
          [structural]

     rule allocString(Base::SymBase, S::String)
          => allocObject(Base, type(arrayType(type(char), lengthString(S) +Int 1)))
          ~> allowInit(writeString(lnew(Base), S))

     rule allocWString(Base::SymBase, S::List)
          => allocObject(Base, type(arrayType(type(cfg:wcharut), size(S) +Int 1)))
          ~> allowInit(writeWString(lnew(Base), S))

endmodule
