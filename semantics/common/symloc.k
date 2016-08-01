module SYMLOC-SORTS
     syntax IntPtr ::= SymLoc
     syntax SymBase
     syntax SymLoc
     syntax CValue ::= IntPtr
endmodule

module SYMLOC-SYNTAX
     imports SYMLOC-SORTS
     imports LIST
     imports COMPAT-SYNTAX

     syntax SymBase ::= base(IntPtr) [function]
     syntax Int ::= offset(SymLoc) [function]

     // Allocated duration.
     syntax Duration ::= "alloc"
     // Static duration.
     syntax Duration ::= static(String)
     syntax Duration ::= link(String)
     syntax SymBase ::= string(String)
     syntax SymBase ::= wstring(List)
     // Thread local duration.
     syntax Duration ::= threadLocal(Int)
     // Auto storage duration.
     syntax Duration ::= auto(Int)
     syntax Duration ::= "argv"
     // We strip storage class specifiers when processing declarations, so this
     // is how we keep track of register-ness.
     syntax Duration ::= register(Int)

     syntax Duration ::= nativeAddress()
     syntax Duration ::= nativeSymbol(String)

     syntax Bool ::= isAllocatedDuration(SymLoc) [function]
     syntax Bool ::= isAllocatedDuration(SymBase) [function, klabel(isAllocatedDuration2)]
     // I.e., static or link.
     syntax Bool ::= isStaticDuration(SymLoc) [function]
     syntax Bool ::= isThreadDuration(SymLoc) [function]
     syntax Bool ::= isAutoDuration(SymLoc) [function]

     syntax Bool ::= isStringLoc(SymLoc) [function]
     syntax Bool ::= isLinkerLoc(SymLoc) [function]
     syntax Bool ::= isLinkerLoc(SymBase) [function, klabel(isLinkerLoc2)]
     syntax Bool ::= isArgvLoc(SymLoc) [function]
     syntax Bool ::= isRegisterLoc(SymLoc) [function]
     syntax Bool ::= isNativeLoc(SymLoc) [function]
     syntax Bool ::= isNativeLoc(SymBase) [function, klabel(isNativeLoc2)]

     syntax SymBase ::= autoToRegister(SymBase) [function]

     syntax SymBase ::= Int "@" Duration [klabel(_@_)]


     // Base, byte offset, bit offset.
     syntax SymLoc ::= loc(SymBase, Int)
     syntax SymLoc ::= CanonicalSymLoc
     syntax CanonicalSymLoc ::= loc(SymBase, Int, Set) [klabel(loc3)]
     syntax CanonicalSymLoc ::= "NullPointer" [klabel(NullPointer)]

     syntax KResult ::= SymLoc

     syntax SymBase ::= linc(SymBase) [function]

     syntax SymLoc ::= SymLoc "+bytes" Int [function]

     syntax Bool ::= SymLoc ">bytes" SymLoc [function]
                   | SymLoc ">=bytes" SymLoc [function]
                   | SymLoc "<bytes" SymLoc [function]
                   | SymLoc "<=bytes" SymLoc [function]
                   | SymLoc "==bytes" SymLoc [function]

     syntax Bool ::= sameBase(IntPtr, IntPtr) [function]

     syntax String ::= getTU(SymLoc) [function]
     syntax ThreadId ::= getThreadId(SymLoc) [function]
     syntax ThreadId ::= Int | "no-thread"
     syntax Int ::= getBitOffset(SymLoc) [function]

     syntax Set ::= prov(SymLoc) [function]
     syntax SymLoc ::= addProv(Provenance, SymLoc) [function]
     syntax SymLoc ::= addProv(Set, SymLoc) [function]

     // Pointers from an array need to be checked that they don't go out of
     // bounds of that array, even if that array happens to be part of a larger
     // object (i.e., surrounded by valid addresses).
     syntax Provenance ::= fromArray(Int, Int)
     // used to tag bit fields so that we know how many bits into the current byte they begin
     syntax Provenance ::= bitOffset(Int)

     syntax Bool ::= isFromArray(SymLoc) [function]

     syntax SymLoc ::= stripFromArray(SymLoc) [function]
     syntax SymLoc ::= stripProv(SymLoc) [function]
endmodule

module SYMLOC
     imports SYMLOC-SYNTAX
     imports C-CONFIGURATION
     imports K-REFLECTION

     rule isAllocatedDuration(_ @ alloc) => true
     rule isAllocatedDuration(_:SymBase) => false [owise]

     rule isAllocatedDuration(NullPointer) => false
     rule isAllocatedDuration(Loc:SymLoc) => isAllocatedDuration(base(Loc)) [owise]

     rule isStaticDuration(loc(_ @ static(_), _)) => true
     rule isStaticDuration(loc(_ @ static(_), _, _)) => true
     rule isStaticDuration(loc(_ @ link(_), _)) => true
     rule isStaticDuration(loc(_ @ link(_), _, _)) => true
     rule isStaticDuration(loc(string(_), _)) => true
     rule isStaticDuration(loc(string(_), _, _)) => true
     rule isStaticDuration(loc(wstring(_), _)) => true
     rule isStaticDuration(loc(wstring(_), _, _)) => true
     rule isStaticDuration(_) => false [owise]

     rule isThreadDuration(loc(_ @ threadLocal(_), _)) => true
     rule isThreadDuration(loc(_ @ threadLocal(_), _, _)) => true
     rule isThreadDuration(_) => false [owise]

     rule isAutoDuration(loc(_ @ auto(_), _)) => true
     rule isAutoDuration(loc(_ @ auto(_), _, _)) => true
     rule isAutoDuration(loc(_ @ argv, _)) => true
     rule isAutoDuration(loc(_ @ argv, _, _)) => true
     rule isAutoDuration(loc(_ @ register(_), _)) => true
     rule isAutoDuration(loc(_ @ register(_), _, _)) => true
     rule isAutoDuration(_) => false [owise]

     rule isStringLoc(loc(string(_), _)) => true
     rule isStringLoc(loc(string(_), _, _)) => true
     rule isStringLoc(loc(wstring(_), _)) => true
     rule isStringLoc(loc(wstring(_), _, _)) => true
     rule isStringLoc(_) => false [owise]

     rule isLinkerLoc(_ @ link(_)) => true
     rule isLinkerLoc(_:SymBase) => false [owise]

     rule isLinkerLoc(NullPointer) => false
     rule isLinkerLoc(Loc:SymLoc) => isLinkerLoc(base(Loc)) [owise]

     rule isArgvLoc(loc(_ @ argv, _)) => true
     rule isArgvLoc(loc(_ @ argv, _, _)) => true
     rule isArgvLoc(_) => false [owise]

     rule isRegisterLoc(loc(_ @ register(_), _)) => true
     rule isRegisterLoc(loc(_ @ register(_), _, _)) => true
     rule isRegisterLoc(_) => false [owise]

     rule isNativeLoc(_ @ nativeAddress()) => true
     rule isNativeLoc(_ @ nativeSymbol(_)) => true
     rule isNativeLoc(_:SymBase) => false [owise]

     rule isNativeLoc(NullPointer) => false
     rule isNativeLoc(Loc:SymLoc) => isNativeLoc(base(Loc)) [owise]

     rule autoToRegister(N:Int @ auto(Th:Int)) => N @ register(Th)

     rule base(loc(Base:SymBase, _)) => Base
     rule base(loc(Base:SymBase, _, _)) => Base

     rule offset(loc(_, Offset:Int)) => Offset
     rule offset(loc(_, Offset:Int, _)) => Offset

     rule linc(X:Int @ D:Duration) => (X +Int 1 @ D)

     rule loc(Base:SymBase, Offset:Int) +bytes N:Int
          => loc(Base, Offset +Int N)
     rule loc(Base:SymBase, Offset:Int, Prov:Set) +bytes N:Int
          => loc(Base, Offset +Int N, Prov)
     rule NullPointer +bytes _ => NullPointer

     rule loc(_, A:Int) >bytes loc(_, B:Int) => A >Int B
     rule loc(_, A:Int) >=bytes loc(_, B:Int) => A >=Int B
     rule loc(_, A:Int) <bytes loc(_, B:Int) => A <Int B
     rule loc(_, A:Int) <=bytes loc(_, B:Int) => A <=Int B
     rule loc(_, A:Int) ==bytes loc(_, B:Int) => A ==Int B

     rule loc(_, A:Int, _) >bytes loc(_, B:Int, _) => A >Int B
     rule loc(_, A:Int, _) >=bytes loc(_, B:Int, _) => A >=Int B
     rule loc(_, A:Int, _) <bytes loc(_, B:Int, _) => A <Int B
     rule loc(_, A:Int, _) <=bytes loc(_, B:Int, _) => A <=Int B
     rule loc(_, A:Int, _) ==bytes loc(_, B:Int, _) => A ==Int B

     rule sameBase(loc(A:SymBase, _), loc(B:SymBase, _)) => A ==K B
     rule sameBase(loc(A:SymBase, _, _), loc(B:SymBase, _, _)) => A ==K B
     rule sameBase(loc(A:SymBase, _), loc(B:SymBase, _, _)) => A ==K B
     rule sameBase(loc(A:SymBase, _, _), loc(B:SymBase, _)) => A ==K B
     rule sameBase(_, _) => false [owise]

     rule getTU(loc(_ @ static(Tu:String), _)) => Tu
     rule getTU(loc(_ @ static(Tu:String), _, _)) => Tu
     rule getTU(loc(_ @ link(Tu:String), _)) => Tu
     rule getTU(loc(_ @ link(Tu:String), _, _)) => Tu
     rule getTU(loc(_ @ nativeAddress(), _)) => "native"
     rule getTU(loc(_ @ nativeAddress(), _, _)) => "native"

     rule getThreadId(loc(_ @ threadLocal(Th:Int), _)) => Th
     rule getThreadId(loc(_ @ threadLocal(Th:Int), _, _)) => Th
     rule getThreadId(loc(_ @ auto(Th:Int), _)) => Th
     rule getThreadId(loc(_ @ auto(Th:Int), _, _)) => Th
     rule getThreadId(loc(_ @ register(Th:Int), _)) => Th
     rule getThreadId(loc(_ @ register(Th:Int), _, _)) => Th
     rule getThreadId(loc(_ @ argv, _)) => 0
     rule getThreadId(loc(_ @ argv, _, _)) => 0
     rule getThreadId(_) => no-thread [owise]

     rule addProv(P:Provenance, loc(Base:SymBase, Offset:Int, Prov:Set))
          => loc(Base, Offset, Prov SetItem(P))
     rule addProv(P:Provenance, loc(Base:SymBase, Offset:Int))
          => loc(Base, Offset, SetItem(P))
     rule addProv(_:Provenance, NullPointer) => NullPointer

     rule addProv(Prov':Set, loc(Base:SymBase, Offset:Int, Prov:Set))
          => loc(Base, Offset, Prov Prov')
     rule addProv(Prov':Set, loc(Base:SymBase, Offset:Int))
          => loc(Base, Offset, Prov')
     rule addProv(_:Set, NullPointer) => NullPointer

     rule prov(loc(_, _, Prov:Set)) => Prov
     rule prov(loc(_, _)) => .Set
     rule prov(NullPointer) => .Set

     rule isFromArray(Loc:SymLoc) => #isFromArray(Loc)

     syntax Bool ::= #isFromArray(SymLoc) [function]
     rule #isFromArray(loc(Base:SymBase, Offset:Int, SetItem(K:K) S:Set))
          => getKLabel(K) ==K #klabel(`fromArray`) orBool #isFromArray(loc(Base, Offset, S))
     rule #isFromArray(_) => false [owise]

     rule stripFromArray(loc(Base:SymBase, Offset:Int)) => loc(Base, Offset)
     rule stripFromArray(loc(Base:SymBase, Offset:Int, Prov:Set))
          => loc(Base, Offset, filterSet(Prov, #klabel(`notFromArray`)))
     rule stripFromArray(Loc:SymLoc) => Loc [owise]

     syntax Bool ::= notFromArray(Provenance) [function]
     rule notFromArray(fromArray(_, _)) => false
     rule notFromArray(_) => true [owise]

     rule stripProv(loc(Base:SymBase, Offset:Int, _)) => loc(Base, Offset)
     rule stripProv(loc(Base:SymBase, Offset:Int)) => loc(Base, Offset)
     rule stripProv(Loc:SymLoc) => Loc [owise]

     rule getBitOffset(loc(_, _, _:Set SetItem(bitOffset(I::Int)))) => I
     rule getBitOffset(_) => 0 [owise]

endmodule

