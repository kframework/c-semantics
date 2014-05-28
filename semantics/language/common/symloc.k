module C-SYMLOC-SYNTAX
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
     syntax Duration ::= auto(Int)

     syntax Bool ::= isAllocatedDuration(SymLoc) [function]
     syntax Bool ::= isArgvDuration(SymLoc) [function]
     // I.e., static or link.
     syntax Bool ::= isStaticDuration(SymLoc) [function]
     syntax Bool ::= isThreadDuration(SymLoc) [function]
     syntax Bool ::= isAutoDuration(SymLoc) [function]

     syntax Bool ::= isStringLoc(SymLoc) [function]
     syntax Bool ::= isLinkerLoc(SymBase) [function]

     // I.e., static, argv, allocated, or thread (the same as "not
     // isLinkerLoc," except it's a "positive" check). This is mostly intended
     // to test for the symbolic locs added in translation (a bit of a hack).
     syntax Bool ::= isPhysicalLoc(SymLoc) [function]

     syntax SymBase ::= Int "@" Duration

     syntax SymBase ::= string(String)
     syntax SymBase ::= wstring(List)

     // Base, byte offset, bit offset.
     syntax SymLoc ::= loc(SymBase, Int) [klabel('loc)]
     syntax SymLoc ::= "NullPointer"

     syntax KResult ::= SymLoc

     syntax SymBase ::= linc(SymBase) [function]
     syntax SymLoc ::= lnew(SymBase) [function]

     syntax SymLoc ::= SymLoc "+bytes" Int [function]

     syntax Bool ::= SymLoc ">bytes" SymLoc [function]
                   | SymLoc ">=bytes" SymLoc [function]
                   | SymLoc "<bytes" SymLoc [function]
                   | SymLoc "<=bytes" SymLoc [function]
                   | SymLoc "==bytes" SymLoc [function]

     syntax Bool ::= sameBase(SymLoc, SymLoc) [function]

     syntax String ::= getTU(SymLoc) [function]
     syntax Int ::= getThreadId(SymLoc) [function]

     syntax Int ::= getOffset(SymLoc) [function]

endmodule

module C-SYMLOC
     imports C-SYMLOC-SYNTAX

     imports C-SETTINGS-SYNTAX

     syntax Bool ::= "#isAllocatedDuration" "(" SymLoc ")" [function]
     syntax Bool ::= "#isArgvDuration" "(" SymLoc ")" [function]
     syntax Bool ::= "#isStaticDuration" "(" SymLoc ")" [function]
     syntax Bool ::= "#isThreadDuration" "(" SymLoc ")" [function]
     syntax Bool ::= "#isAutoDuration" "(" SymLoc ")" [function]

     syntax Bool ::= "#isStringLoc" "(" SymLoc ")" [function]
     syntax Bool ::= "#isLinkerLoc" "(" SymBase ")" [function]

     rule isPhysicalLoc(Loc:SymLoc) 
          => (isAllocatedDuration(Loc) 
               orBool isArgvDuration(Loc)
               orBool isStaticDuration(Loc)
               orBool isThreadDuration(Loc)
               orBool isAutoDuration(Loc))

     rule isAllocatedDuration(Loc:SymLoc) 
          => #isAllocatedDuration(Loc) ==K true
     rule isArgvDuration(Loc:SymLoc) 
          => #isArgvDuration(Loc) ==K true
     rule isStaticDuration(Loc:SymLoc)
          => #isStaticDuration(Loc) ==K true
     rule isThreadDuration(Loc:SymLoc)
          => #isThreadDuration(Loc) ==K true
     rule isAutoDuration(Loc:SymLoc)
          => #isAutoDuration(Loc) ==K true

     rule isStringLoc(Loc:SymLoc)
          => #isStringLoc(Loc) ==K true
     rule isLinkerLoc(Base:SymBase)
          => #isLinkerLoc(Base) ==K true

     rule #isAllocatedDuration(loc(_ @ allocated, _)) => true

     rule #isArgvDuration(loc(_ @ argv, _)) => true

     rule #isStaticDuration(loc(_ @ static(_), _)) => true
     rule #isStaticDuration(loc(_ @ link(_), _)) => true

     rule #isThreadDuration(loc(_ @ thread(_), _)) => true

     rule #isAutoDuration(loc(_ @ auto(_), _)) => true

     rule #isStringLoc(loc(string(_), _)) => true
     rule #isStringLoc(loc(wstring(_), _)) => true

     rule #isLinkerLoc(_ @ link(_)) => true

     rule base(loc(Base:SymBase, _)) => Base

     rule offset(loc(_, Offset:Int)) => Offset

     rule linc(X:Int @ D:Duration) => (X +Int 1 @ D)

     rule lnew(Base:SymBase) => loc(Base, 0)

     rule loc(Base:SymBase, Offset:Int) +bytes N:Int
          => loc(Base, Offset +Int N)

     rule loc(_, A:Int) >bytes loc(_, B:Int) => A >Int B
     rule loc(_, A:Int) >=bytes loc(_, B:Int) => A >=Int B
     rule loc(_, A:Int) <bytes loc(_, B:Int) => A <Int B
     rule loc(_, A:Int) <=bytes loc(_, B:Int) => A <=Int B
     rule loc(_, A:Int) ==bytes loc(_, B:Int) => A ==Int B

     rule sameBase(loc(A:SymBase, _), loc(B:SymBase, _)) => A ==K B

     rule getTU(loc(_ @ static(Tu:String), _)) => Tu
     rule getTU(loc(_ @ link(Tu:String), _)) => Tu

     rule getThreadId(loc(_ @ thread(Th:Int), _)) => Th
     rule getThreadId(loc(_ @ auto(Th:Int), _)) => Th

     rule getOffset(loc(_, Off:Int)) => Off
     
endmodule

