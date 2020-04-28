module LIBC-STDLIB-SYNTAX
     imports INT
     syntax KItem ::= alignedAlloc(Int, Int)
endmodule

module LIBC-STDLIB
     imports LIBC-STDLIB-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports INT
     imports STRING
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-IO-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-NATIVE-BRIDGE-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPE-BUILDER-SYNTAX
     imports C-TYPING-SYNTAX
     imports DELETE-OBJECT-SYNTAX
     imports LIBC-BUILTIN-SYNTAX
     imports LIBC-IO-SYNTAX

     rule [exit]:
          <k> builtin("exit", tv(I:Int, ut(_, int))) ~> _
               => reval(tv(I, utype(int))) ~> callAtExit
          </k>
          <status> mainCalled => mainExited </status>
          [structural]

     rule <k> (.K => UNDEF("STDLIB4", "Called the exit function more than once (from a call to atexit)."))
              ~> builtin("exit", tv(_, _))
          ...</k>
          <status> mainExited </status>

     //TODO(dwightguth): handle other differences between exit and quick_exit
     rule [quick-exit]:
          <k> builtin("quick_exit", tv(I:Int, ut(_, int))) ~> _
               => reval(tv(I:Int, utype(int))) ~> callAtQuickExit
          </k>
          <status> mainCalled => mainExited </status>
          [structural]

     rule <k> (.K => UNDEF("STDLIB5", "Called the quick_exit function more than once (from a call to at_quick_exit)."))
              ~> builtin("quick_exit", tv(_, _))
          ...</k>
          <status> mainExited </status>

     rule [abort]:
          <k> builtin("abort") ~> _
               => writeFD(#stdout, "Aborted\n")
               ~> flush(#stdout)
               ~> reval(tv(134, utype(int)))
          </k>

     /*@ \fromStandard{\source[n1570]{\para{7.22.3.4}{2--3}}}{
     The \cinline{malloc} function allocates space for an object whose size is
     specified by \cinline{size} and whose value is indeterminate.

     The malloc function returns either a null pointer or a pointer to the
     allocated space.
     }*/
     rule builtin("malloc", tv(Sz:Int, _)) => alignedAlloc(cfg:alignofMalloc, Sz)
          [structural]

     rule builtin("aligned_alloc", tv(Align:Int, _), tv(Sz:Int, _))
          => alignedAlloc(Align, Sz)
          requires Sz =/=Int 0
          [structural]
     rule (.K => IMPL("STDLIB8", "Called calloc, malloc, realloc, or aligned_alloc with a zero size parameter."))
              ~> builtin("aligned_alloc", _, tv(0, _))
          [structural]

     rule <k> alignedAlloc(Align::Int, Sz::Int)
               => alloc(obj(!I:Int, Align, alloc), type(no-type), Sz)
               ~> tv(addProv(fromArray(0, Sz, dynamicType(type(no-type))), lnew(obj(!I, Align, alloc))),
                    utype(pointerType(type(void))))
          ...</k>
          <malloced>... .Map => obj(!I, Align, alloc) |-> Sz ...</malloced>
          requires notBool hasLint andBool Sz <=Int cfg:maxHeapBound
          [structural]
     rule <k> alignedAlloc(Align::Int, Sz::Int)
               => tv(NullPointer, utype(pointerType(type(void))))
          ...</k>
          requires notBool hasLint andBool Sz >Int cfg:maxHeapBound
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
     rule builtin("realloc", tv((loc(Base:SymBase, Offset:Int, _) => loc(Base, Offset)), _), _)
     rule [realloc]:
          <k> builtin("realloc", tv(loc(OldBase:SymBase, 0), _), tv(NewLen:Int, _))
               => realloc(OldBase, bnew(!I:Int, type(no-type), alloc), OldLen, NewLen)
               ~> tv(loc(bnew(!I, type(no-type), alloc), 0, SetItem(fromArray(0, NewLen, T))),
                    utype(pointerType(type(void))))
          ...</k>
          <mem>... OldBase |-> object(T::EffectiveType, _, _) ...</mem>
          <malloced>...
               (OldBase => bnew(!I, type(no-type), alloc)) |-> (OldLen:Int => NewLen)
          ...</malloced>
          requires notBool hasLint
          [structural]

     rule <k> (.K => UNDEF("STDLIB1", "Called realloc on memory not allocated by malloc, or already freed."))
              ~> builtin("realloc", tv(loc(Base:SymBase, I:Int), _), _)
          ...</k>
          <malloced> Malloced:Map </malloced>
          requires notBool Base in_keys(Malloced) orBool I =/=Int 000

     rule [realloc-null]:
          builtin("realloc", tv(NullPointer, _), Len:RValue)
          => builtin("malloc", Len)
          [structural]

     syntax KItem ::= "calloc-aux"
     rule [calloc]:
          builtin("calloc", tv(N:Int, _), tv(Size:Int, _))
          => builtin("malloc", tv(N:Int *Int Size:Int, utype(cfg:sizeut)))
          ~> calloc-aux
          [structural]
     rule (.K => zeroObject(base(Loc)) )
          ~> tv(Loc:SymLoc, ut(_, pointerType(t(_, _, void))))
          ~> (calloc-aux => .K)
          [structural]

     rule builtin("free", tv((loc(Base:SymBase, Offset:Int, _) => loc(Base, Offset)), _))
     rule [free]:
          <k> builtin("free", tv(loc(Base:SymBase, 0), ut(_, pointerType(_))))
               => deleteObject(Base)
               ~> voidVal
          ...</k>
          <malloced>... Base |-> _ => .Map ...</malloced>
          requires notBool hasLint
          [structural]
     rule <k> (.K => UNDEF("STDLIB2", "Called free on memory not allocated by malloc, or already freed."))
              ~> builtin("free", tv(loc(Base:SymBase, I:Int), ut(_, pointerType(_))))
          ...</k>
          <malloced> Malloced:Map </malloced>
          requires notBool isNativeLoc(loc(Base, I)) 
              andBool (notBool Base in_keys(Malloced) orBool I =/=Int 0)

     rule builtin("free", tv(NullPointer, ut(_, pointerType(_))))
          => voidVal
          requires notBool hasLint
     // Returns a pseudo-random integral number in the range 0 to RAND_MAX
     // fixme should use RAND_MAX
     rule [rand]:
          builtin("rand") => tv(randInt(max(utype(int)) +Int 1), utype(int))
          [structural]

     rule [srand]:
          builtin("srand", tv(N:Int, ut(_, unsigned-int)))
          => srandInt(N) ~> voidVal
          [structural]

     rule [atexit]:
          <k> builtin("atexit", tv(Loc:SymLoc, ut(... st: pointerType(_)) #as T::UType))
              => success
          ...</k>
          <atexit> (.K => Computation(Call(tv(Loc, T), list(.List)))) ...</atexit>
          <status> mainCalled </status>

     rule <k> (.K => UNSPEC("STDLIB3", "Called the atexit function after normal program termination has begun."))
              ~> builtin("atexit", _)
          ...</k>
          <status> mainExited </status>

     rule [at-quick-exit]:
          <k> builtin("at_quick_exit", tv(Loc:SymLoc, ut(... st: pointerType(_)) #as T::UType))
              => success
          ...</k>
          <at-quick-exit> (.K => Computation(Call(tv(Loc, T), list(.List)))) ...</at-quick-exit>
          <status> mainCalled </status>

     rule <k> (.K => UNSPEC("STDLIB6", "Called the at_quick_exit function after normal program termination has begun."))
              ~> builtin("at_quick_exit", _)
          ...</k>
          <status> mainExited </status>

     rule builtin("strtof", NPtr::RValue, EndPtr::RValue)
          => nativeCall("strtof", ListItem(NPtr) ListItem(EndPtr), .List)
          [structural]
     rule builtin("strtod", NPtr::RValue, EndPtr::RValue)
          => nativeCall("strtod", ListItem(NPtr) ListItem(EndPtr), .List)
          [structural]
     rule builtin("strtold", NPtr::RValue, EndPtr::RValue)
          => nativeCall("strtold", ListItem(NPtr) ListItem(EndPtr), .List)
          [structural]

     rule builtin("secure_getenv" => "getenv", _)
          [structural]
     rule (.K => newFixedObject(nativeCall("getenv", ListItem(KeyPtr), .List)))
          ~> builtin("getenv", KeyPtr::RValue)
          [structural]
     rule <k> Ptr:RValue ~> builtin("getenv", _)
               => deleteObject(base(Loc)) ~> Ptr
          ...</k>
          <getenv> tv(Loc:SymLoc, _) #as OldPtr::RValue => Ptr </getenv>
          requires notBool isNull(OldPtr)
          [structural]
     rule <k> Ptr:RValue ~> builtin("getenv", _)
               => Ptr
          ...</k>
          <getenv> OldPtr:RValue => Ptr </getenv>
          requires isNull(OldPtr)
          [structural]

endmodule
