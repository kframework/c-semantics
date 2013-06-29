module C-MEMORY-ALLOC-SYNTAX
     // loc, size in bytes
     syntax Bits ::= "encodedFloat" "(" Float ")"
     // object, start piece, end piece
     syntax Bits ::= "subObject" "(" Ptr "," K "," K ")"

     // fixme would be better to keep canonical
     syntax Int ::= getBitOffset(SymLoc) [function]
     syntax Int ::= getByteOffset(SymLoc) [function]

     // TODO(chathhorn): error check
     syntax K ::= "checkValidLoc-aux" "(" SymLoc ")"
endmodule

module C-MEMORY-ALLOC
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-MEMORY-SYNTAX

     imports C-DYNAMIC-SYNTAX
     imports C-HELPERS-SYNTAX
     imports C-COMPAT-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX

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
          
     rule [delete-sized-block]:
          <k>
               deleteSizedBlock(loc(Base:SymBase, _:Int, _:Int), Len:Int) => . 
          ...</k>
          <mem>... Base |-> memblock(Len, _, _) => .Map ...</mem>
          // fixme could make this more relaxed by checking of block is in
          // buffer, not just empty
          <buffer> .List </buffer>
          [structural] 
     
     rule [delete-block]:
          <k> deleteBlock(loc(Base:SymBase, _:Int, _:Int)) => .K ...</k>
          <mem>... Base |-> memblock(_, _, _) => .Map ...</mem>
          <buffer> .List </buffer>
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
               t(.Set, arrayType(t(.Set, char), lengthString(S))))
               ~> writeString(Loc, S) ~> makeUnwritable(Loc)
          [structural]
     rule [alloc-wstring]:
          allocWString(Loc:SymLoc, S:KList)
          => allocateType(Loc, 
               t(.Set, arrayType(cfg:wcharut, 4 *Int lengthKList S:KList)))
               ~> writeWString(Loc, S:KList) ~> makeUnwritable(Loc)
          [structural] 
     
     rule [makeUnwritable-var]:
          <k> makeUnwritableVar(X:Id) => makeUnwritable(Loc)  ...</k>
          <env>... X:Id |-> Loc:SymLoc ...</env>
          [structural]
     // fixme shouldn't need both of these
     // fixme could do better with bitfields
     context makeUnwritableSubObject((HOLE => peval(HOLE)))
     rule [makeUnwritable-subobject]:
          <k> 
               makeUnwritableSubObject(
                    lval(loc(Base:SymBase, Offset:Int, _), _)) 
               => . 
          ...</k>
          <notWritable> 
               M:Map => M:Map[1 / loc(Base, Offset:Int, 0)] 
          </notWritable>
          [structural]
     rule [makeUnwritable]:
          <k> makeUnwritable(loc(Base:SymBase, 0, 0)) => . ...</k>
          <mem>... 
               Base |-> memblock(_, _ (.Bag => BagItem(mconst)), _) 
          ...</mem>
          [structural]

     
     rule checkValidLoc(Loc:SymLoc) => checkValidLoc-aux(ceilingLoc(Loc)) 
          [structural]
     rule checkDerefLoc(Loc:SymLoc) => checkValidLoc(Loc) 
          when Loc =/=K NullPointer
          [structural]
     
     rule [check-valid-loc-null]:
          checkValidLoc-aux(NullPointer) => . 
          [structural]
     // fixme could additionally use the type to check whether that type is
     // valid for that pointer
     rule [check-valid-loc]:
          <k> 
               checkValidLoc-aux(
                    loc(N:Int @ PtrThreadId:ThreadId, Offset:Int, 0)) 
               => . 
          ...</k>
          <mem>... N @ PtrThreadId |-> memblock(Len:Int, _, _) ...</mem>
          <threadId> MyThreadId:ThreadId </threadId>
          when (PtrThreadId ==K MyThreadId
               orBool (PtrThreadId ==K 0)
               orBool (PtrThreadId ==K allocatedDuration)
               ) // my thread, global memory, or allocated (malloced) memory
               andBool (Offset <=Int Len) // we're allowed to address one past
          [structural]
endmodule
