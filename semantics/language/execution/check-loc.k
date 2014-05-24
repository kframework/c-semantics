module C-CHECK-LOC
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-ERROR-SYNTAX

     // fixme could additionally use the type to check whether that type is
     // valid for that pointer
     rule <k> isValidLoc(loc(Base:SymBase, Offset:Int)) => true ...</k>
          <mem>... Base |-> memblock(_, _, _) ...</mem>
          <thread-id> ThreadId:Int </thread-id>
          when notBool (isThreadDuration(loc(Base, Offset))
                    orBool isAutoDuration(loc(Base, Offset)))
               orBool (ThreadId ==K getThreadId(loc(Base, Offset)))
               // my thread, global memory, or allocated (malloced) memory
          [structural]
     rule <k> isValidLoc(loc(Base:SymBase, Offset:Int)) => false ...</k>
          <mem> Mem:Map </mem>
          <thread-id> ThreadId:Int </thread-id>
          when notBool (Base in keys(Mem))
               orBool ((isThreadDuration(loc(Base, Offset))
                         orBool isAutoDuration(loc(Base, Offset)))
                    andBool (ThreadId =/=K getThreadId(loc(Base, Offset))))
          [structural]
     rule <k> isValidLoc(loc((LinkBase:SymBase => Base), _)) ...</k>
          <linkings>... loc(LinkBase, 0) |-> loc(Base:SymBase, _) ...</linkings>
          [structural]

     rule <k> isInBounds(loc(Base:SymBase, Offset:Int)) => true ...</k>
          <mem>... Base |-> memblock(Len:Int, _, _) ...</mem>
          when (Offset <=Int Len) andBool (Offset >=Int 0)
          [structural]
     rule <k> isInBounds(loc(Base:SymBase, Offset:Int)) => false ...</k>
          <mem>... Base |-> memblock(Len:Int, _, _) ...</mem>
          when (Offset >Int Len) orBool (Offset <Int 0)
          [structural]
     rule <k> isInBounds(loc(Base:SymBase, _)) => false ...</k>
          <mem> Mem:Map </mem>
          when notBool (Base in keys(Mem))
          [structural]
     rule <k> isInBounds(loc((LinkBase:SymBase => Base), _)) ...</k>
          <linkings>... loc(LinkBase, 0) |-> loc(Base:SymBase, _) ...</linkings>
          [structural]

     rule errorLocInvalid
          => UNDEF("ECL1", "referring to an object outside of its lifetime.", "6.2.4")
          [structural]
          
     rule errorLocBounds
          => UNDEF("ECL2", "found pointer that refers outside the bounds of an object + 1.", "6.2.4")
          [structural]
endmodule
