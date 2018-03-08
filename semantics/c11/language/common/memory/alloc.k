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

     rule allocObject(Base::SymBase, T::Type) => #allocObject(Base, T, sizeof(T))
          [structural]

     syntax KItem ::= #allocObject(SymBase, Type, K)
     context #allocObject(_, _, (HOLE:KItem => reval(HOLE))) [result(RValue)]
     rule #allocObject(Base:SymBase, T:Type, tv(I:Int, _))
          => alloc(Base, T, I)
          [structural]

     rule <k> alloc(Base:DirectBase, T::Type, Len::Int) => .K ...</k>
          <mem>...
               .Map => Base |-> object(stripStorageSpecifiers(T), Len, makeEmptyArray(Len))
          ...</mem>
          requires notBool isNoType(T)
          [structural]
     rule <k> alloc(Base:DirectBase, T:NoType, Len::Int) => .K ...</k>
          <mem>...
               .Map => Base |-> object(dynamicType(T), Len, makeEmptyArray(Len))
          ...</mem>
          [structural]

     // Used by calloc.
     syntax Array ::= createArray(Int, Bits) [function]
     rule createArray(I::Int, B::Bits) => fillArray(makeEmptyArray(I), 0, I, B)

     rule <k> zeroObject(Base:SymBase) => .K ...</k>
          <mem>...
               Base |-> object(_, Len:Int,
                    _ => createArray(Len, piece(0, cfg:bitsPerByte)))
          ...</mem>
          [structural]

     rule <k> sizeofObject(Base:SymBase) => tv(Len, utype(cfg:sizeut)) ...</k>
          <mem>... Base |-> object(_, Len:Int, _) ...</mem>
          [structural]

     rule allocString(Base::SymBase, S::String)
          => allocObject(Base, type(arrayType(type(char), lengthString(S) +Int 1)))
          ~> initString(lnew(Base), S)

     rule allocWString(Base::SymBase, S::List)
          => allocObject(Base, type(arrayType(type(cfg:wcharut), size(S) +Int 1)))
          ~> initWString(lnew(Base), S)

endmodule
