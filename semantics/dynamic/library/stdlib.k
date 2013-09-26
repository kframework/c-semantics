module LIBC-STDLIB
     imports LIBC-BOOTSTRAP-SYNTAX
     imports LIBC-IO-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-MEMORY-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C11-SETTINGS-SYNTAX
     imports COMPAT-SYNTAX

     syntax K ::= "printString" "(" K ")"

     rule printString(S:String)
          => writeToFD(1, ordChar(firstChar(S:String)))
               ~> printString(butFirstChar(S:String))
          when lengthString(S:String) >Int 0
          [structural]
     rule printString("") => writeToFD(1, 10)
          [structural]
     
     rule [debug]:
          prepareBuiltin(Identifier("__debug"), _) => skipval
          [interpRule]
     
     rule [exit]:
          <k> 
               prepareBuiltin((Identifier("exit")), tv(I:Int, t(_, int))) ~> _
               => tv(I:Int, t(.Set, int)) 
          </k>
          [structural]

     rule [abort]:
          <k> 
               prepareBuiltin((Identifier("abort")), .KList) ~> _ 
               => printString("Aborted") ~> tv(134, t(.Set, int)) 
          </k>
     
     /*@ \fromStandard{\source[n1570]{\para{7.22.3.4}{2--3}}}{
     The \cinline{malloc} function allocates space for an object whose size is
     specified by \cinline{size} and whose value is indeterminate.

     The malloc function returns either a null pointer or a pointer to the
     allocated space.
     }*/
     syntax K ::= "newAlloc" "(" Int ")" [function]
     rule newAlloc(Fresh:Int) => loc(Fresh @ allocatedDuration, 0, 0)
     
     rule [malloc]:
          <k> 
               prepareBuiltin((Identifier("malloc")), tv(Len:Int, _:KResult))
               => alloc(newAlloc(Fresh:Int), Len:Int)
                    ~> tv(newAlloc(Fresh:Int), 
                         t(.Set, pointerType(t(.Set, void))))
          ...</k>
          <malloced>... .Map => newAlloc(Fresh:Int) |-> Len:Int ...</malloced>
          <freshNat> Fresh:Int => Fresh:Int +Int 1 </freshNat>
          [structural]
          
     /*@ \fromStandard{\source[n1570]{\para{7.22.3.5}{2--4}}}{
     The \cinline{realloc} function deallocates the old object pointed to by
     \cinline{ptr} and returns a pointer to a new object that has the size
     specified by \cinline{size}. The contents of the new object shall be the
     same as that of the old object prior to deallocation, up to the lesser of
     the new and old sizes. Any bytes in the new object beyond the size of the
     old object have indeterminate values.

     If \cinline{ptr} is a null pointer, the \cinline{realloc} function behaves
     like the \cinline{malloc} function for the specified size. Otherwise, if
     \cinline{ptr} does not match a pointer earlier returned by a memory
     management function, or if the space has been deallocated by a call to the
     \cinline{free} or \cinline{realloc} function, the behavior is undefined.
     If memory for the new object cannot be allocated, the old object is not
     deallocated and its value is unchanged.

     The \cinline{realloc} function returns a pointer to the new object (which
     may have the same value as a pointer to the old object), or a null pointer
     if the new object could not be allocated.
     }*/
     rule [realloc]:
          <k> 
               prepareBuiltin((Identifier("realloc")), (tv(OldLoc:SymLoc, _),, 
                    tv(NewLen:Int, _:KResult)))
               => realloc(OldLoc, newAlloc(Fresh:Int), OldLen:Int, NewLen:Int)
                    ~> tv(newAlloc(Fresh:Int), t(.Set, pointerType(t(.Set, void))))
          ...</k>
          <malloced>... 
               (OldLoc => newAlloc(Fresh:Int)) |-> (OldLen:Int => NewLen:Int) 
          ...</malloced>
          <freshNat> Fresh:Int => Fresh:Int +Int 1 </freshNat>
          when OldLoc =/=K NullPointer
          [structural]
     
     rule [realloc-null]:
          prepareBuiltin((Identifier("realloc")), 
               (tv(NullPointer, _),, Len:KResult)) 
          => prepareBuiltin((Identifier("malloc")), Len:KResult)
          [structural]

     syntax K ::= "calloc-aux"
     rule [calloc]:
          prepareBuiltin((Identifier("calloc")), 
               (tv(N:Int, _),, tv(Size:Int, _)))
          => prepareBuiltin((Identifier("malloc")),
               tv(N:Int *Int Size:Int, cfg:sizeut))
          ~> calloc-aux
          [structural]
     rule [calloc-aux]:
          (. => zeroBlock(Loc:SymLoc) ) 
          ~> tv(Loc, t(_, pointerType(t(_, void))))
          ~> (calloc-aux => .K)
          [structural]

     rule [free]:
          <k> 
               prepareBuiltin((Identifier("free")),
                    tv(Loc:SymLoc, t(_, pointerType(_))))
               => deleteSizedBlock(Loc, Len:Int) 
                    ~> skipval
          ...</k>
          <malloced>... Loc |-> Len:Int => .Map ...</malloced>
          [structural]
          
     // Returns a pseudo-random integral number in the range 0 to RAND_MAX
     // fixme should use RAND_MAX
     rule [rand]:
          <k> 
               prepareBuiltin((Identifier("rand")), .KList)
               => tv(absInt(randomRandom(Fresh:Int)) 
                    %Int max(t(.Set, int)), t(.Set, int))
          ...</k>
          <randNat> Fresh:Int => Fresh:Int +Int 1 </randNat>
          [structural]
          
     rule [srand]:
          <k> 
               prepareBuiltin((Identifier("srand")),
                    tv(N:Int, t(.Set, unsigned-int)))
               => skipval
          ...</k>
          <randNat> _ => N:Int </randNat>
          [structural]

endmodule
