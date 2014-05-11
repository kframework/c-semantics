module C-MEMORY-ALLOC-SYNTAX
     syntax K ::= memblock(Int, Bag, Map)

     syntax K ::= writeString(SymLoc, String)
     syntax K ::= writeWString(SymLoc, List)

     syntax K ::= checkValidLoc(SymLoc)
     syntax K ::= checkDerefLoc(SymLoc)

     syntax K ::= allocString(SymLoc, String)
     syntax K ::= allocWString(SymLoc, List)

     syntax K ::= alloc(SymLoc, K, Bag) [strict(2)]

     syntax K ::= zeroBlock(SymLoc)

     syntax K ::= sizeofLocation(SymLoc)

     syntax K ::= "mconst" | "mvolatile"

     syntax K ::= makeUnwritableSubObject(K)

     syntax K ::= allocateType(SymLoc, Type)
     syntax K ::= allocateTypeIfAbsent(SymLoc, Type)
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

     imports COMPAT-SYNTAX
     
     rule writeString(Loc:SymLoc, S:String)
          => Computation(
               allowWrite(* tv(Loc, t(.Set, pointerType(t(.Set, char))))) 
               := tv(ordChar(firstChar(S:String)), t(.Set, char)))
               ~> writeString(Loc +bytes 1, butFirstChar(S:String))
          when S:String =/=String ""
          [structural]
     // fixme this bare 4 needs to be updated to handle different size wchar_ts
     rule writeWString(Loc:SymLoc, ListItem(N:Int) S:List)
          => Computation(
               allowWrite(* tv(Loc, t(.Set, pointerType(cfg:wcharut)))) 
               := tv(N, cfg:wcharut))
               ~> writeWString(Loc +bytes 4, S)
          [structural] 
     rule writeString(Loc:SymLoc, "")
          => Computation(
               allowWrite(* tv(Loc, t(.Set, pointerType(t(.Set, char))))) 
               := tv(0, t(.Set, char)))
          [structural]
     rule writeWString(Loc:SymLoc, .List)
          => Computation(
               allowWrite(* tv(Loc, t(.Set, pointerType(cfg:wcharut)))) 
               := tv(0, cfg:wcharut))
          [structural] 

     rule allocateType(Loc:SymLoc, T:Type) 
          => alloc(Loc, byteSizeofType(T), bagifyQuals(T))
          [structural]
     rule <k> allocateTypeIfAbsent(Loc:SymLoc, T:Type) 
               => alloc(Loc, byteSizeofType(T), bagifyQuals(T))
          ...</k>
          <mem> M:Map </mem>
          when notBool (SetItem(base(Loc)) in (keys M))
          [structural] 
     rule <k> allocateTypeIfAbsent(loc(Base:SymBase, 0, 0), _) => . 
          ...</k>
          <mem>... Base |-> memblock(_, _, _) ...</mem>
          [structural]

     // TODO(chathhorn): I don't really see why we can't just use the actual
     // type qualifiers. This is pretty silly.
     syntax Bag ::= bagifyQuals(Type) [function]
     rule bagifyQuals(T:Type) => BagItem(mconst) BagItem(mvolatile)
          when isConstType(T) andBool isVolatileType(T)
     rule bagifyQuals(T:Type) => BagItem(mconst)
          when isConstType(T) andBool notBool isVolatileType(T)
     rule bagifyQuals(T:Type) => BagItem(mvolatile)
          when notBool isConstType(T) andBool isVolatileType(T)
     rule bagifyQuals(T:Type) => .Bag
          when notBool isConstType(T) andBool notBool isVolatileType(T)

     rule <k> alloc(loc(Base:SymBase, 0, 0), Len:TypedValue, Quals:Bag)
               => .
          ...</k>
          <mem>...
               .Map => Base |-> memblock(value(Len), Quals, .Map)
          ...</mem>
          when notBool isLinkerLoc(loc(Base, 0, 0))
          [structural]
     
     // used by calloc
     rule <k> zeroBlock(loc(Base:SymBase, 0, 0)) => . ...</k>
          <mem>...
               Base |-> memblock(Len:Int, _, 
                    _ => Map((0 to Len) |-> piece(0, cfg:bitsPerByte)))
          ...</mem>
          [structural]
          
     rule <k> sizeofLocation(loc(Base:SymBase, _:Int, _:Int)) 
               => tv(Len, cfg:sizeut)
          ...</k>
          <mem>... Base |-> memblock(Len:Int, _, _) ...</mem>
          [structural]
          
     // c99 6.5:2 If a side effect on a scalar object is unsequenced relative
     // to either a different side effect on the same scalar object or a value
     // computation using the value of the same scalar object, the behavior is
     // undefined. If there are multiple allowable orderings of the
     // subexpressions of an expression, the behavior is undefined if such an
     // unsequenced side effect occurs in any of the orderings
     //
     // i take this to mean that if i write to a location twice or read from a
     // location after being written to, then it is a problem
          
     rule allocString(Loc:SymLoc, S:String)
          => allocateType(Loc, addQualifier(Const,
               t(.Set, arrayType(t(.Set, char), lengthString(S) +Int 1))))
               ~> writeString(Loc, S)
          [structural]
     rule allocWString(Loc:SymLoc, S:List)
          => allocateType(Loc, addQualifier(Const,
               t(.Set, arrayType(cfg:wcharut, 4 *Int (lengthList(S) +Int 1)))))
               ~> writeWString(Loc, S)
          [structural] 
     
     // FIXME could do better with bitfields
     syntax K ::= makeUnwritable(SymLoc)
     context makeUnwritableSubObject((HOLE => peval(HOLE)))
     rule <k> makeUnwritableSubObject(
                    lval(loc(Base:SymBase, Offset:Int, _), _)) 
               => . 
          ...</k>
          <not-writable>...
               (. => SetItem(loc(Base, Offset:Int, 0)))
          ...</not-writable>
          [structural]
     rule makeUnwritableSubObject(lval(Loc:SymLoc, _)) => . 
          when notBool isPhysicalLoc(Loc)
          [structural]
     rule <k> makeUnwritable(loc(Base:SymBase, 0, 0)) => . ...</k>
          <mem>... 
               Base |-> memblock(_, _ (.Bag => BagItem(mconst)), _) 
          ...</mem>
          [structural]
     rule makeUnwritable(Loc:SymLoc) => .
          when notBool isPhysicalLoc(Loc)
          [structural]

     rule checkDerefLoc(Loc:SymLoc) => checkValidLoc(Loc) 
          when Loc =/=K NullPointer
          [structural]

endmodule
