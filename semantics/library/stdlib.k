module LIBC-STDLIB
     imports LIBC-BOOTSTRAP-SYNTAX
     imports LIBC-IO-SYNTAX

     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-IO-BUFFERED-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-CONFIGURATION

     syntax KItem ::= printString(K)

     rule printString(S:String)
          => writeToFD(1, ordChar(firstChar(S:String)))
               ~> printString(butFirstChar(S:String))
          requires lengthString(S:String) >Int 0
          [structural]
     rule printString("") => writeToFD(1, 10)
          [structural]

     rule [debug]:
          prepareBuiltin(Identifier("__debug"), _) => voidVal
          [interpRule]

     rule [exit]:
          <k> prepareBuiltin(Identifier("exit"),
                    hrItem(tv(I:Int, t(_, int))))
               ~> _
               => tv(I:Int, t(.Set, int))
          </k>
          [structural]

     rule [abort]:
          <k> prepareBuiltin(Identifier("abort"), .HeatList)
               ~> _
               => printString("Aborted") ~> tv(134, t(.Set, int))
          </k>

     /*@ \fromStandard{\source[n1570]{\para{7.22.3.4}{2--3}}}{
     The \cinline{malloc} function allocates space for an object whose size is
     specified by \cinline{size} and whose value is indeterminate.

     The malloc function returns either a null pointer or a pointer to the
     allocated space.
     }*/
     rule <k> prepareBuiltin(Identifier("malloc"),
                    hrItem(tv(Len:Int, _)))
               => alloc(Base, t(.Set, no-type), Len:Int)
               ~> tv(addProv(fromArray(0, Len), lnew(Base, t(.Set, no-type))),
                    t(.Set, pointerType(t(.Set, void))))
          ...</k>
          <malloced>... .Map => Base |-> Len:Int ...</malloced>
          <next-malloced> Base:SymBase => linc(Base) </next-malloced>
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
     rule prepareBuiltin(Identifier("realloc"),
          hrItem(tv((loc(Base:SymBase, Offset:Int, _) => loc(Base, Offset)), _)) hs:: _)
     rule [realloc]:
          <k> prepareBuiltin(Identifier("realloc"),
                    hrItem(tv(loc(OldBase:SymBase, 0), _)) hs::
                    hrItem(tv(NewLen:Int, _)))
               => realloc(OldBase, NewBase, OldLen, NewLen)
               ~> tv(loc(NewBase, 0, SetItem(fromArray(0, NewLen))),
                    t(.Set, pointerType(t(.Set, void))))
          ...</k>
          <malloced>...
               (OldBase => NewBase) |-> (OldLen:Int => NewLen)
          ...</malloced>
          <next-malloced> NewBase:SymBase => linc(NewBase) </next-malloced>
          [structural]

     rule <k> (.K => UNDEF("STDLIB1", "Called realloc on memory not allocated by malloc, or already freed.",
                           "7.22.3.5:3, J.2:1 item 179"))
              ~> prepareBuiltin(Identifier("realloc"),
                    hrItem(tv(loc(Base:SymBase, I:Int), _)) hs::
                    hrItem(tv(_, _)))
          ...</k>
          <malloced> Malloced:Map </malloced>
          requires notBool Base in_keys(Malloced) orBool I =/=Int 000

     rule [realloc-null]:
          prepareBuiltin(Identifier("realloc"),
               hrItem(tv(NullPointer, _)) hs::
               hrItem(Len:KResult))
          => prepareBuiltin(Identifier("malloc"), hrItem(Len:KResult))
          [structural]

     syntax KItem ::= "calloc-aux"
     rule [calloc]:
          prepareBuiltin(Identifier("calloc"),
               hrItem(tv(N:Int, _)) hs::
               hrItem(tv(Size:Int, _)))
          => prepareBuiltin(Identifier("malloc"),
               hrItem(tv(N:Int *Int Size:Int, t(.Set, cfg:sizeut))))
          ~> calloc-aux
          [structural]
     rule (.K => zeroObject(base(Loc)) )
          ~> tv(Loc:SymLoc, t(_, pointerType(t(_, void))))
          ~> (calloc-aux => .K)
          [structural]

     rule prepareBuiltin(Identifier("free"),
          hrItem(tv((loc(Base:SymBase, Offset:Int, _) => loc(Base, Offset)), _)))
     rule [free]:
          <k> prepareBuiltin(Identifier("free"),
                    hrItem(tv(loc(Base:SymBase, 0), t(_, pointerType(_)))))
               => deleteSizedObject(Base, Len:Int)
               ~> voidVal
          ...</k>
          <malloced>... Base |-> Len:Int => .Map ...</malloced>
          [structural]
     rule <k> (.K => UNDEF("STDLIB2", "Called free on memory not allocated by malloc, or already freed.",
                           "7.22.3.3:2, J.2:1 item 179"))
              ~> prepareBuiltin(Identifier("free"),
                    hrItem(tv(loc(Base:SymBase, I:Int), t(_, pointerType(_)))))
          ...</k>
          <malloced> Malloced:Map </malloced>
          requires notBool Base in_keys(Malloced) orBool I =/=Int 0

     rule prepareBuiltin(Identifier("free"),
               hrItem(tv(NullPointer, t(_, pointerType(_)))))
          => voidVal
          requires notBool hasLint
     // Returns a pseudo-random integral number in the range 0 to RAND_MAX
     // fixme should use RAND_MAX
     rule [rand]:
          <k> prepareBuiltin((Identifier("rand")), .HeatList)
               => tv(randInt(max(t(.Set, int)) +Int 1), t(.Set, int))
          ...</k>
          [structural]

     rule [srand]:
          <k> prepareBuiltin(Identifier("srand"),
                    hrItem(tv(N:Int, t(_, unsigned-int))))
               => srandInt(N) ~> voidVal
          ...</k>
          [structural]

endmodule
