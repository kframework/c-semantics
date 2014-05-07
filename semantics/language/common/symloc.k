module C-SYMLOC-SYNTAX
     syntax K ::= firstLoc(Duration) [function]
     syntax SymBase ::= base(SymLoc) [function]
     syntax Int ::= offset(SymLoc) [function]

     // We got basically 4 different memory sorts:
     // allocated -- allocated duration. The heap.
     // thread -- thread local and also auto storage class. Automatic storage
     // duration (the stack) plus thread-local.
     // static -- per-TU memory allocated during the translation phase.
     // Corresponds to the static storage class, data segment, bss, etc.
     // argv -- where the arguments to main() go.
     // 
     // Also, we have special "linker" locations for unresolved (before
     // linking) external references.
     // 
     // TODO(chathhorn): maybe add an actual "auto" storage duration?
     syntax Duration ::= "allocated" [avoid]
     syntax Duration ::= "argv"
     syntax Duration ::= link(String)
     syntax Duration ::= static(String)
     syntax Duration ::= thread(Int)

     syntax Bool ::= isAllocatedDuration(SymLoc) [function]
     syntax Bool ::= isArgvDuration(SymLoc) [function]
     // I.e., static or link.
     syntax Bool ::= isStaticDuration(SymLoc) [function]
     syntax Bool ::= isThreadDuration(SymLoc) [function]
     syntax Bool ::= isLinkerLoc(SymLoc) [function]

     // I.e., static, argv, allocated, or thread (the same as "not
     // isLinkerLoc," except it's a "positive" check). This is mostly intended
     // to test for the symbolic locs added in translation (a bit of a hack).
     syntax Bool ::= isPhysicalLoc(SymLoc) [function]

     syntax SymBase ::= Int "@" Duration

     // Base, byte offset, bit offset.
     syntax SymLoc ::= loc(SymBase, Int, Int) [klabel('loc)]
     syntax SymLoc ::= "NullPointer"

     syntax SymLoc ::= argvLoc(Int) [function]

     syntax KResult ::= SymLoc

     syntax SymLoc ::= linc(SymLoc) [function]

     syntax SymLoc ::= SymLoc "+bits" Int [function]
     syntax SymLoc ::= SymLoc "+bytes" Int [function]

     syntax Bool ::= SymLoc ">bytes" SymLoc [function]
                   | SymLoc ">=bytes" SymLoc [function]
                   | SymLoc "<bytes" SymLoc [function]
                   | SymLoc "<=bytes" SymLoc [function]
                   | SymLoc "==bytes" SymLoc [function]

     // Loc with possible bit offset returning base byte.
     syntax SymLoc ::= floorLoc(SymLoc) [function] 
     // Loc with possible bit offset returning upperbounded byte.
     syntax SymLoc ::= ceilingLoc(SymLoc) [function]

     syntax Bool ::= sameBase(SymLoc, SymLoc) [function]

     syntax String ::= getTU(SymLoc) [function]
     syntax Int ::= getThreadId(SymLoc) [function]

     // fixme would be better to keep canonical
     syntax Int ::= getBitOffset(SymLoc) [function]
     syntax Int ::= getByteOffset(SymLoc) [function]

     syntax Bool ::= isByteLoc(SymLoc) [function]

endmodule

module C-SYMLOC
     imports C-SYMLOC-SYNTAX

     imports C-SETTINGS-SYNTAX

     syntax Bool ::= "#isAllocatedDuration" "(" SymLoc ")" [function]
     syntax Bool ::= "#isArgvDuration" "(" SymLoc ")" [function]
     syntax Bool ::= "#isStaticDuration" "(" SymLoc ")" [function]
     syntax Bool ::= "#isThreadDuration" "(" SymLoc ")" [function]

     syntax Bool ::= "#isLinkerLoc" "(" SymLoc ")" [function]

     rule isPhysicalLoc(Loc:SymLoc) 
          => (isAllocatedDuration(Loc) 
               orBool isArgvDuration(Loc)
               orBool isStaticDuration(Loc)
               orBool isThreadDuration(Loc))

     rule isAllocatedDuration(Loc:SymLoc) 
          => #isAllocatedDuration(Loc) ==K true
     rule isArgvDuration(Loc:SymLoc) 
          => #isArgvDuration(Loc) ==K true
     rule isStaticDuration(Loc:SymLoc)
          => #isStaticDuration(Loc) ==K true
     rule isThreadDuration(Loc:SymLoc)
          => #isThreadDuration(Loc) ==K true
     rule isLinkerLoc(Loc:SymLoc)
          => #isLinkerLoc(Loc) ==K true

     rule #isAllocatedDuration(loc(_ @ allocated, _, _)) => true

     rule #isArgvDuration(loc(_ @ argv, _, _)) => true

     rule #isStaticDuration(loc(_ @ static(_), _, _)) => true
     rule #isStaticDuration(loc(_ @ link(_), _, _)) => true

     rule #isThreadDuration(loc(_ @ thread(_), _, _)) => true

     rule #isLinkerLoc(loc(_ @ link(_), _, _)) => true

     rule firstLoc(D:Duration) => loc(0 @ D, 0, 0)
     
     rule base(loc(Base:SymBase, _, _)) => Base

     rule offset(loc(_, Offset:Int, _)) => Offset

     rule argvLoc(N:Int) => loc(N @ argv, 0, 0)
     
     rule linc(loc(X:Int @ D:Duration, ByOff:Int, BiOff:Int))
          => loc(X +Int 1 @ D, ByOff, BiOff)

     rule loc(Base:SymBase, Offset:Int, BitOffset:Int) +bits N:Int
          => loc(Base, Offset +Int (BitOffset +Int N) /Int cfg:bitsPerByte,
               (BitOffset +Int N) %Int cfg:bitsPerByte)

     rule loc(Base:SymBase, Offset:Int, BitOffset:Int) +bytes N:Int
          => loc(Base, Offset +Int N, BitOffset)

     rule loc(_, A:Int, _) >bytes loc(_, B:Int, _) => A >Int B
     rule loc(_, A:Int, _) >=bytes loc(_, B:Int, _) => A >=Int B
     rule loc(_, A:Int, _) <bytes loc(_, B:Int, _) => A <Int B
     rule loc(_, A:Int, _) <=bytes loc(_, B:Int, _) => A <=Int B
     rule loc(_, A:Int, _) ==bytes loc(_, B:Int, _) => A ==Int B

     rule floorLoc(loc(Base:SymBase, Offset:Int, BitOffset:Int))
          => loc(Base, Offset:Int, 0)
          when BitOffset <Int cfg:bitsPerByte
     
     rule [ceilingLoc-null]: 
          ceilingLoc(NullPointer) => NullPointer

     rule [ceilingLoc]:
          ceilingLoc(loc(N:SymBase, R:Int, M:Int))
          => loc(N, (M /Int cfg:bitsPerByte) +Int R, 0)

     rule sameBase(loc(A:SymBase, _, _), loc(B:SymBase, _, _))
          => A ==K B

     rule getTU(loc(_ @ static(Tu:String), _, _)) => Tu
     rule getTU(loc(_ @ link(Tu:String), _, _)) => Tu

     rule getThreadId(loc (_ @ thread(Th:Int), _, _)) => Th

     rule getBitOffset(loc(_, _, M:Int)) => M %Int cfg:bitsPerByte
     rule getByteOffset(loc(_, M:Int, N:Int)) => M +Int N /Int cfg:bitsPerByte
     
     rule isByteLoc(Loc:SymLoc) => getBitOffset(Loc) ==Int 0
endmodule

