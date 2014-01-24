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
          <k> 
               checkValidLoc-aux(
                    loc(N:Int @ Dur:Duration, Offset:Int, 0)) 
               => . 
          ...</k>
          <mem>... N @ Dur |-> memblock(Len:Int, _, _) ...</mem>
          <threadId> ThreadId:Int </threadId>
          when (Dur ==K thread(ThreadId)
               orBool isStaticDuration(loc(N @ Dur, Offset, 0))
               orBool isAllocatedDuration(loc(N @ Dur, Offset, 0))
               ) // my thread, global memory, or allocated (malloced) memory
               andBool (Offset <=Int Len) // we're allowed to address one past
          [structural]

endmodule
