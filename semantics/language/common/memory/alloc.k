module C-MEMORY-ALLOC-SYNTAX
     syntax K ::= object(Type, Int, Map)

     syntax K ::= writeString(SymLoc, String)
     syntax K ::= writeWString(SymLoc, List)

     syntax K ::= allocString(SymBase, String)
     syntax K ::= allocWString(SymBase, List)

     syntax K ::= alloc(SymBase, Type, Int)

     syntax K ::= zeroObject(SymBase)

     syntax K ::= sizeofObject(SymBase)

     syntax K ::= allocObject(SymBase, Type)
     syntax K ::= allocObjectIfAbsent(SymBase, Type)
endmodule

module C-MEMORY-ALLOC
     imports C-MEMORY-ALLOC-SYNTAX

     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-ERROR-SYNTAX

     imports COMPAT-SYNTAX
     
     rule writeString(Loc:SymLoc, S:String)
          => Computation(
               * tv(Loc, t(.Set, pointerType(t(.Set, char))))
               := tv(ordChar(firstChar(S:String)), t(.Set, char)))
               ~> writeString(Loc +bytes 1, butFirstChar(S:String))
          when S:String =/=String ""
          [structural]
     // TODO this bare 4 needs to be updated to handle different size wchar_ts
     rule writeWString(Loc:SymLoc, ListItem(N:Int) S:List)
          => Computation(
               * tv(Loc, t(.Set, pointerType(cfg:wcharut)))
               := tv(N, cfg:wcharut))
               ~> writeWString(Loc +bytes 4, S)
          [structural] 
     rule writeString(Loc:SymLoc, "")
          => Computation(
               * tv(Loc, t(.Set, pointerType(t(.Set, char))))
               := tv(0, t(.Set, char)))
          [structural]
     rule writeWString(Loc:SymLoc, .List)
          => Computation(
               * tv(Loc, t(.Set, pointerType(cfg:wcharut)))
               := tv(0, cfg:wcharut))
          [structural] 

     rule allocObject(Base:SymBase, T:Type)
          => alloc(Base, T, byteSizeofType(T))
          [structural]
     rule <k> allocObjectIfAbsent(Base:SymBase, T:Type) 
               => alloc(Base, T, byteSizeofType(T))
          ...</k>
          <mem> M:Map </mem>
          when notBool (SetItem(Base) in (keys M))
          [structural] 
     rule <k> allocObjectIfAbsent(Base:SymBase, _) => . 
          ...</k>
          <mem>... Base |-> object(_, _, _) ...</mem>
          [structural]

     rule <k> alloc(Base:SymBase, T:Type, Len:Int) => . ...</k>
          <mem>...
               .Map => Base |-> object(stripStorageSpecifiers(T), Len, .Map)
          ...</mem>
          when notBool isLinkerLoc(Base)
          [structural]
     
     // Used by calloc.
     rule <k> zeroObject(Base:SymBase) => . ...</k>
          <mem>...
               Base |-> object(_, Len:Int, 
                    _ => Map((0 to Len) |-> piece(0, cfg:bitsPerByte)))
          ...</mem>
          [structural]
          
     rule <k> sizeofObject(Base:SymBase)
               => tv(Len, cfg:sizeut)
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
               arrayType(cfg:wcharut, 4 *Int (lengthList(S) +Int 1))))
          ~> allowInit(writeWString(lnew(Base), S))
          [structural] 
     
endmodule
