module LIBC-STDLIB
     imports LIBC-BOOTSTRAP-SYNTAX
     imports LIBC-IO-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-IO-BUFFERED-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports COMPAT-SYNTAX

     syntax K ::= printString(K)

     rule printString(S:String)
          => writeToFD(1, ordChar(firstChar(S:String)))
               ~> printString(butFirstChar(S:String))
          when lengthString(S:String) >Int 0
          [structural]
     rule printString("") => writeToFD(1, 10)
          [structural]

     rule [debug]:
          prepareBuiltin(Identifier("__debug"), _) => voidVal
          [interpRule]

     rule [exit]:
          <k> prepareBuiltin(Identifier("exit"), 
                    ListItem(tv(I:Int, t(_, int))))
               ~> _
               => tv(I:Int, t(.Set, int)) 
          </k>
          [structural]

     rule [abort]:
          <k> prepareBuiltin(Identifier("abort"), .List) 
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
                    ListItem(tv(Len:Int, _)))
               => alloc(Base, t(.Set, no-type), Len:Int)
               ~> tv(loc(Base, 0, SetItem(fromArray(0, Len))),
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
          ListItem(tv((loc(Base:SymBase, Offset:Int, _) => loc(Base, Offset)), _)) _)
     rule [realloc]:
          <k> prepareBuiltin(Identifier("realloc"),
                    ListItem(tv(loc(OldBase:SymBase, 0), _))
                    ListItem(tv(NewLen:Int, _)))
               => realloc(OldBase, NewBase, OldLen, NewLen)
               ~> tv(loc(NewBase, 0, SetItem(fromArray(0, NewLen))),
                    t(.Set, pointerType(t(.Set, void))))
          ...</k>
          <malloced>... 
               (OldBase => NewBase) |-> (OldLen:Int => NewLen) 
          ...</malloced>
          <next-malloced> NewBase:SymBase => linc(NewBase) </next-malloced>
          [structural]

     rule [realloc-null]:
          prepareBuiltin(Identifier("realloc"),
               ListItem(tv(NullPointer, _))
               ListItem(Len:KResult))
          => prepareBuiltin(Identifier("malloc"), ListItem(Len:KResult))
          [structural]

     syntax K ::= "calloc-aux"
     rule [calloc]:
          prepareBuiltin(Identifier("calloc"),
               ListItem(tv(N:Int, _))
               ListItem(tv(Size:Int, _)))
          => prepareBuiltin(Identifier("malloc"),
               ListItem(tv(N:Int *Int Size:Int, cfg:sizeut)))
          ~> calloc-aux
          [structural]
     rule (. => zeroObject(base(Loc)) ) 
          ~> tv(Loc:SymLoc, t(_, pointerType(t(_, void))))
          ~> (calloc-aux => .)
          [structural]

     rule prepareBuiltin(Identifier("free"),
          ListItem(tv((loc(Base:SymBase, Offset:Int, _) => loc(Base, Offset)), _)))
     rule [free]:
          <k> prepareBuiltin(Identifier("free"),
                    ListItem(tv(loc(Base:SymBase, 0), t(_, pointerType(_)))))
               => deleteSizedObject(Base, Len:Int) 
               ~> voidVal
          ...</k>
          <malloced>... Base |-> Len:Int => .Map ...</malloced>
          [structural]

     // Returns a pseudo-random integral number in the range 0 to RAND_MAX
     // fixme should use RAND_MAX
     rule [rand]:
          <k> prepareBuiltin((Identifier("rand")), .List)
               => tv(absInt(randomRandom(Seed:Int)) 
                    %Int max(t(.Set, int)), t(.Set, int))
          ...</k>
          <rand-nat> Seed:Int => Seed:Int +Int 1 </rand-nat>
          [structural]

     rule [srand]:
          <k> prepareBuiltin(Identifier("srand"),
                    ListItem(tv(N:Int, t(.Set, unsigned-int))))
               => voidVal
          ...</k>
          <rand-nat> _ => N:Int </rand-nat>
          [structural]

endmodule
