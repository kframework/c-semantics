module C-CHECK-LOC-SYNTAX
     syntax K ::= "checkValidLoc-aux" "(" SymLoc ")"
endmodule

module C-CHECK-LOC
     imports C-CHECK-LOC-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SYMLOC-SYNTAX

     rule checkValidLoc(Loc:SymLoc) => checkValidLoc-aux(ceilingLoc(Loc)) 
          [structural]

     rule [check-valid-loc-null]:
          checkValidLoc-aux(NullPointer) => . 
          [structural]
     // fixme could additionally use the type to check whether that type is
     // valid for that pointer
     rule [check-valid-loc]:
          <k> checkValidLoc-aux(loc(Base:SymBase, Offset:Int, 0)) => . ...</k>
          <mem>... Base |-> memblock(Len:Int, _, _) ...</mem>
          <thread-id> ThreadId:Int </thread-id>
          when (notBool isThreadDuration(loc(Base, Offset, 0))
                    orBool (ThreadId ==K getThreadId(loc(Base, Offset, 0)))
               ) // my thread, global memory, or allocated (malloced) memory
               andBool (Offset <=Int Len) // we're allowed to address one past
          [structural]

     rule [check-valid-loc-linker]:
          <k> checkValidLoc-aux(loc((LinkBase:SymBase => Base), _, _)) ...</k>
          <linkings>... loc(LinkBase, 0, 0) |-> loc(Base:SymBase, _, _) ...</linkings>
          [structural]

endmodule
