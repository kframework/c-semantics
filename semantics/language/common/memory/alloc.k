module C-MEMORY-ALLOC-SYNTAX
     syntax K ::= memblock(Int, Bag, Map)

     syntax K ::= writeString(SymLoc, String)
     syntax K ::= writeWString(SymLoc, KList)

     // fixme would be better to keep canonical
     syntax Int ::= getBitOffset(SymLoc) [function]
     syntax Int ::= getByteOffset(SymLoc) [function]

     syntax K ::= checkValidLoc(SymLoc)
     syntax K ::= checkDerefLoc(SymLoc)

     syntax K ::= allocString(SymLoc, String)
     syntax K ::= allocWString(SymLoc, KList)

     syntax K ::= alloc(SymLoc, K) [strict(2)]

     syntax K ::= zeroBlock(SymLoc)

     syntax K ::= sizeofLocation(SymLoc)

     syntax K ::= "mconst"

     syntax K ::= makeUnwritable(SymLoc)
     syntax K ::= makeUnwritableSubObject(K)
     syntax K ::= makeUnwritableVar(K)

     syntax K ::= allocateType(SymLoc, Type)
     syntax K ::= allocateTypeIfAbsent(SymLoc, Type)
endmodule

module C-MEMORY-ALLOC
     imports C-MEMORY-ALLOC-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-BITS-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports COMPAT-SYNTAX
     
     rule [write-string]:
          writeString(Loc:SymLoc, S:String)
          => Computation((* tv(Loc, t(.Set, pointerType(t(.Set, char))))) 
               := tv(ordChar(firstChar(S:String)), t(.Set, char)))
               ~> writeString(Loc +bytes 1, butFirstChar(S:String))
          when S:String =/=String ""
          [structural]
     // fixme this bare 4 needs to be updated to handle different size wchar_ts
     rule [write-wstring]:
          writeWString(Loc:SymLoc, (N:Int,, S:KList))
          => Computation((* tv(Loc, t(.Set, pointerType(cfg:wcharut)))) 
               := tv(N, cfg:wcharut))
               ~> writeWString(Loc +bytes 4, S)
          [structural] 
     rule [write-empty-string]:
          writeString(Loc:SymLoc, "")
          => Computation((* tv(Loc, t(.Set, pointerType(t(.Set, char))))) 
               := tv(0, t(.Set, char)))
          [structural]
     rule [write-wstring]:
          writeWString(Loc:SymLoc, .KList)
          => Computation((* tv(Loc, t(.Set, pointerType(cfg:wcharut)))) 
               := tv(0, cfg:wcharut))
          [structural] 

     rule allocateType(Loc:SymLoc, T:Type) 
          => alloc(Loc, byteSizeofType(T))
          [structural]
     rule [allocateTypeIfAbsent-absent]:
          <k> allocateTypeIfAbsent(Loc:SymLoc, T:Type) 
               => alloc(Loc, byteSizeofType(T))
          ...</k>
          <mem> M:Map </mem>
          when notBool (SetItem(base(Loc)) in (keys M))
          [structural] 
     rule [allocateTypeIfAbsent-present]:
          <k> allocateTypeIfAbsent(loc(Base:SymBase, 0, 0), _:Type) => . 
          ...</k>
          <mem>... Base |-> memblock(_, _, _) ...</mem>
          [structural]

     rule [alloc-lazy]:
          <k> alloc(loc(Base:SymBase, 0, 0), Len:TypedValue) => . ...</k>
          <mem>... .Map => Base |-> memblock(value(Len), .Bag, .Map) ...</mem>
          when notBool isLinkerLoc(loc(Base, 0, 0))
          [structural]
     
     rule getBitOffset(loc(_, _, M:Int)) => M %Int cfg:bitsPerByte
     rule getByteOffset(loc(_, M:Int, N:Int)) => M +Int N /Int cfg:bitsPerByte
     
     // used by calloc
     rule <k> zeroBlock(loc(Base:SymBase, 0, 0)) => . ...</k>
          <mem>...
               Base |-> memblock(Len:Int, _, 
                    _ => Map((0 to Len) |-> piece(0, cfg:bitsPerByte)))
          ...</mem>
          [structural]
          
     rule <k> 
               sizeofLocation(loc(Base:SymBase, _:Int, _:Int)) 
               => tv(Len:Int, cfg:sizeut)
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
          
     rule [alloc-string]:
          allocString(Loc:SymLoc, S:String)
          => allocateType(Loc, 
               t(.Set, arrayType(t(.Set, char), lengthString(S) +Int 1)))
               ~> writeString(Loc, S) ~> makeUnwritable(Loc)
          [structural]
     rule [alloc-wstring]:
          allocWString(Loc:SymLoc, S:KList)
          => allocateType(Loc, 
               t(.Set, arrayType(cfg:wcharut, 4 *Int (lengthKList(S) +Int 1))))
               ~> writeWString(Loc, S) ~> makeUnwritable(Loc)
          [structural] 
     
     rule [makeUnwritable-var]:
          <k> makeUnwritableVar(X:Id) => makeUnwritable(Loc)  ...</k>
          <env>... X:Id |-> Loc:SymLoc ...</env>
          [structural]
     // FIXME shouldn't need both of these
     // FIXME could do better with bitfields
     context makeUnwritableSubObject((HOLE => peval(HOLE)))
     rule [makeUnwritable-subobject]:
          <k> makeUnwritableSubObject(
                    lval(loc(Base:SymBase, Offset:Int, _), _)) 
               => . 
          ...</k>
          <not-writable>...
               (. => SetItem(loc(Base, Offset:Int, 0)))
          ...</not-writable>
          [structural]
     rule [makeUnwritable-subobject]:
          makeUnwritableSubObject(lval(Loc:SymLoc, _)) => . 
          when notBool isPhysicalLoc(Loc)
          [structural]
     rule [makeUnwritable]:
          <k> makeUnwritable(loc(Base:SymBase, 0, 0)) => . ...</k>
          <mem>... 
               Base |-> memblock(_, _ (.Bag => BagItem(mconst)), _) 
          ...</mem>
          [structural]
     rule [makeUnwritable-symbolic]:
          makeUnwritable(Loc:SymLoc) => .
          when notBool isPhysicalLoc(Loc)
          [structural]

     rule checkDerefLoc(Loc:SymLoc) => checkValidLoc(Loc) 
          when Loc =/=K NullPointer
          [structural]

endmodule
