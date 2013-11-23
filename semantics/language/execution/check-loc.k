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
