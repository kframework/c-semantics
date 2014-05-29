module C-SYMLOC-SYNTAX
     syntax SymBase ::= base(SymLoc) [function]
     syntax Int ::= offset(SymLoc) [function]

     // Allocated duration.
     syntax Duration ::= "allocated" [avoid]
     // Static duration.
     syntax Duration ::= static(String)
     syntax Duration ::= link(String)
     syntax SymBase ::= string(String)
     syntax SymBase ::= wstring(List)
     // Thread local duration.
     syntax Duration ::= thread(Int)
     // Auto storage duration.
     syntax Duration ::= auto(Int)
     syntax Duration ::= "argv"
     // We strip storage class specifiers when processing declarations, so this
     // is how we keep track of register-ness.
     syntax Duration ::= register(Int)

     syntax Bool ::= isAllocatedDuration(SymLoc) [function]
     // I.e., static or link.
     syntax Bool ::= isStaticDuration(SymLoc) [function]
     syntax Bool ::= isThreadDuration(SymLoc) [function]
     syntax Bool ::= isAutoDuration(SymLoc) [function]

     syntax Bool ::= isStringLoc(SymLoc) [function]
     syntax Bool ::= isLinkerLoc(SymBase) [function]
     syntax Bool ::= isArgvLoc(SymLoc) [function]
     syntax Bool ::= isRegisterLoc(SymLoc) [function]

     syntax SymBase ::= autoToRegister(SymBase) [function]

     // I.e., static, argv, allocated, or thread (the same as "not
     // isLinkerLoc," except it's a "positive" check). This is mostly intended
     // to test for the symbolic locs added in translation (a bit of a hack).
     syntax Bool ::= isPhysicalLoc(SymLoc) [function]

     syntax SymBase ::= Int "@" Duration


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
     syntax Bool ::= "#isStaticDuration" "(" SymLoc ")" [function]
     syntax Bool ::= "#isThreadDuration" "(" SymLoc ")" [function]
     syntax Bool ::= "#isAutoDuration" "(" SymLoc ")" [function]

     syntax Bool ::= "#isStringLoc" "(" SymLoc ")" [function]
     syntax Bool ::= "#isLinkerLoc" "(" SymBase ")" [function]
     syntax Bool ::= "#isArgvLoc" "(" SymLoc ")" [function]
     syntax Bool ::= "#isRegisterLoc" "(" SymLoc ")" [function]

     rule isPhysicalLoc(Loc:SymLoc) 
          => (isAllocatedDuration(Loc) 
               orBool isStaticDuration(Loc)
               orBool isThreadDuration(Loc)
               orBool isAutoDuration(Loc))

     rule isAllocatedDuration(Loc:SymLoc) 
          => #isAllocatedDuration(Loc) ==K true
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
     rule isArgvLoc(Loc:SymLoc) 
          => #isArgvLoc(Loc) ==K true
     rule isRegisterLoc(Loc:SymLoc) 
          => #isRegisterLoc(Loc) ==K true

     rule autoToRegister(N:Int @ auto(Th:Int)) => N @ register(Th)

     rule #isAllocatedDuration(loc(_ @ allocated, _)) => true

     rule #isStaticDuration(loc(_ @ static(_), _)) => true
     rule #isStaticDuration(loc(_ @ link(_), _)) => true
     rule #isStaticDuration(loc(string(_), _)) => true
     rule #isStaticDuration(loc(wstring(_), _)) => true

     rule #isThreadDuration(loc(_ @ thread(_), _)) => true

     rule #isAutoDuration(loc(_ @ auto(_), _)) => true
     rule #isAutoDuration(loc(_ @ argv, _)) => true
     rule #isAutoDuration(loc(_ @ register(_), _)) => true

     rule #isStringLoc(loc(string(_), _)) => true
     rule #isStringLoc(loc(wstring(_), _)) => true

     rule #isLinkerLoc(_ @ link(_)) => true

     rule #isArgvLoc(loc(_ @ argv, _)) => true

     rule #isRegisterLoc(loc(_ @ register(_), _)) => true

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
     rule getThreadId(loc(_ @ register(Th:Int), _)) => Th

     rule getOffset(loc(_, Off:Int)) => Off
     
endmodule

