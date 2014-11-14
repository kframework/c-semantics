module C-SYMLOC-SYNTAX
     syntax SymBase ::= base(SymLoc) [function]
     syntax Int ::= offset(SymLoc) [function]

     // Allocated duration.
     syntax Duration ::= "alloc"
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
     syntax Bool ::= isLinkerLoc(SymLoc) [function]
     syntax Bool ::= isLinkerLoc(SymBase) [function, klabel('isLinkerLoc2)]
     syntax Bool ::= isArgvLoc(SymLoc) [function]
     syntax Bool ::= isRegisterLoc(SymLoc) [function]

     syntax SymBase ::= autoToRegister(SymBase) [function]

     // I.e., static, argv, allocated, or thread (the same as "not
     // isLinkerLoc," except it's a "positive" check). This is mostly intended
     // to test for the symbolic locs added in translation (a bit of a hack).
     syntax Bool ::= isPhysicalLoc(SymLoc) [function]

     syntax SymBase ::= Int "@" Duration


     // Base, byte offset, bit offset.
     syntax SymLoc ::= loc(SymBase, Int, Set)
     syntax SymLoc ::= loc(SymBase, Int)
     syntax SymLoc ::= "NullPointer"

     syntax KResult ::= SymLoc

     syntax SymBase ::= linc(SymBase) [function]
     syntax SymLoc ::= lnew(SymBase) [function]
     syntax SymLoc ::= restrictedNew(SymBase, RestrictTag) [function]

     syntax SymLoc ::= SymLoc "+bytes" Int [function]

     syntax Bool ::= SymLoc ">bytes" SymLoc [function]
                   | SymLoc ">=bytes" SymLoc [function]
                   | SymLoc "<bytes" SymLoc [function]
                   | SymLoc "<=bytes" SymLoc [function]
                   | SymLoc "==bytes" SymLoc [function]

     syntax Bool ::= sameBase(SymLoc, SymLoc) [function]

     syntax String ::= getTU(SymLoc) [function]
     syntax ThreadId ::= getThreadId(SymLoc) [function]
     syntax ThreadId ::= Int | "no-thread"
     syntax Int ::= getAlign(SymLoc) [function]

     syntax Set ::= prov(SymLoc) [function]
     //TODO: why it is nessary here
     syntax Set ::= getBases(SymLoc) [function, klabel(getBases)]
     syntax Set ::= getBases(Set) [function]
     syntax SymLoc ::= addProv(Provenance, SymLoc) [function]
     syntax SymLoc ::= addProv(Set, SymLoc) [function]
     // From, to.
     syntax KItem ::= transferProv(SymLoc, K) [strict(2)]
     syntax KItem ::= transferProv(Set, K) [strict(2)]

     // Pointers from an array need to be checked that they don't go out of
     // bounds of that array, even if that array happens to be part of a larger
     // object (i.e., surrounded by valid addresses).
     syntax Provenance ::= fromArray(Int, Int)
     // Used for detecting violations of aliasing restictions on
     // restrict-qualified pointers.
     syntax Provenance ::= basedOn(SymBase, RestrictTag)
     // Used to tag union members so the rest of the bytes in the union can be
     // marked as undefined upon write.
     syntax Provenance ::= fromUnion(SymLoc, CId, FieldInfo)
     syntax Provenance ::= align(Int)

     syntax Bool ::= hasUnionMarker(SymLoc) [function]

     syntax Bool ::= isFromArray(SymLoc) [function]

     syntax Bool ::= ifFromArrayInBounds(SymLoc, Type, Int) [function]
     syntax SymLoc ::= stripAllButFromUnion(SymLoc) [function]

     syntax SymLoc ::= stripProv(SymLoc) [function]
endmodule

module C-SYMLOC
     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX

     imports COMPAT-SYNTAX

     syntax Bool ::= #isAllocatedDuration(SymLoc) [function]
     syntax Bool ::= #isStaticDuration(SymLoc) [function]
     syntax Bool ::= #isThreadDuration(SymLoc) [function]
     syntax Bool ::= #isAutoDuration(SymLoc) [function]

     syntax Bool ::= #isStringLoc(SymLoc) [function]
     syntax Bool ::= #isLinkerLoc(SymBase) [function]
     syntax Bool ::= #isArgvLoc(SymLoc) [function]
     syntax Bool ::= #isRegisterLoc(SymLoc) [function]

     rule isPhysicalLoc(Loc:SymLoc)
          => (isAllocatedDuration(Loc)
               orBool isStaticDuration(Loc)
               orBool isThreadDuration(Loc)
               orBool isAutoDuration(Loc))

     rule isAllocatedDuration(Loc:SymLoc) => true
          requires #isAllocatedDuration(Loc) 
     rule isAllocatedDuration(Loc:SymLoc) => false [owise]
     rule isStaticDuration(Loc:SymLoc) => true
          requires #isStaticDuration(Loc)
     rule isStaticDuration(Loc:SymLoc) => false [owise]
     rule isThreadDuration(Loc:SymLoc) => true
          requires #isThreadDuration(Loc)
     rule isThreadDuration(Loc:SymLoc) => false [owise]
     rule isAutoDuration(Loc:SymLoc) => true
          requires #isAutoDuration(Loc)
     rule isAutoDuration(Loc:SymLoc) => false [owise]

     rule isStringLoc(Loc:SymLoc) => true
          requires #isStringLoc(Loc)
     rule isStringLoc(Loc:SymLoc) => false [owise]
     rule isLinkerLoc(Base:SymBase) => true
          requires #isLinkerLoc(Base)
     rule isLinkerLoc(Base:SymBase) => false [owise]
     rule isLinkerLoc(Loc:SymLoc) => true
          requires #isLinkerLoc(base(Loc))
     rule isLinkerLoc(Loc:SymLoc) => false [owise]
     rule isArgvLoc(Loc:SymLoc) => true
          requires #isArgvLoc(Loc)
     rule isArgvLoc(Loc:SymLoc) => false [owise]
     rule isRegisterLoc(Loc:SymLoc) => true
          requires #isRegisterLoc(Loc)
      rule isRegisterLoc(Loc:SymLoc) => false [owise]

     rule autoToRegister(N:Int @ auto(Th:Int)) => N @ register(Th)

     rule #isAllocatedDuration(loc(_ @ alloc, _)) => true
     rule #isAllocatedDuration(loc(_ @ alloc, _, _)) => true
     rule #isAllocatedDuration(_) => false [owise]

     rule #isStaticDuration(loc(_ @ static(_), _)) => true
     rule #isStaticDuration(loc(_ @ static(_), _, _)) => true
     rule #isStaticDuration(loc(_ @ link(_), _)) => true
     rule #isStaticDuration(loc(_ @ link(_), _, _)) => true
     rule #isStaticDuration(loc(string(_), _)) => true
     rule #isStaticDuration(loc(string(_), _, _)) => true
     rule #isStaticDuration(loc(wstring(_), _)) => true
     rule #isStaticDuration(loc(wstring(_), _, _)) => true
     rule #isStaticDuration(_) => false [owise]

     rule #isThreadDuration(loc(_ @ thread(_), _)) => true
     rule #isThreadDuration(loc(_ @ thread(_), _, _)) => true
     rule #isThreadDuration(_) => false [owise]

     rule #isAutoDuration(loc(_ @ auto(_), _)) => true
     rule #isAutoDuration(loc(_ @ auto(_), _, _)) => true
     rule #isAutoDuration(loc(_ @ argv, _)) => true
     rule #isAutoDuration(loc(_ @ argv, _, _)) => true
     rule #isAutoDuration(loc(_ @ register(_), _)) => true
     rule #isAutoDuration(loc(_ @ register(_), _, _)) => true
     rule #isAutoDuration(_) => false [owise]

     rule #isStringLoc(loc(string(_), _)) => true
     rule #isStringLoc(loc(string(_), _, _)) => true
     rule #isStringLoc(loc(wstring(_), _)) => true
     rule #isStringLoc(loc(wstring(_), _, _)) => true
     rule #isStringLoc(_) => false [owise]

     rule #isLinkerLoc(_ @ link(_)) => true
     rule #isLinkerLoc(_) => false [owise]

     rule #isArgvLoc(loc(_ @ argv, _)) => true
     rule #isArgvLoc(loc(_ @ argv, _, _)) => true
     rule #isArgvLoc(_) => false [owise]

     rule #isRegisterLoc(loc(_ @ register(_), _)) => true
     rule #isRegisterLoc(loc(_ @ register(_), _, _)) => true
     rule #isRegisterLoc(_) => false [owise]

     rule base(loc(Base:SymBase, _)) => Base
     rule base(loc(Base:SymBase, _, _)) => Base

     rule offset(loc(_, Offset:Int)) => Offset
     rule offset(loc(_, Offset:Int, _)) => Offset

     rule linc(X:Int @ D:Duration) => (X +Int 1 @ D)

     rule lnew(Base:SymBase) => loc(Base, 0)
     rule restrictedNew(Base:SymBase, Tag:RestrictTag)
          => loc(Base, 0, SetItem(basedOn(Base, Tag)))

     rule loc(Base:SymBase, Offset:Int) +bytes N:Int
          => loc(Base, Offset +Int N)
     rule loc(Base:SymBase, Offset:Int, Prov:Set) +bytes N:Int
          => loc(Base, Offset +Int N, Prov)

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

     rule getTU(loc(_ @ static(Tu:String), _)) => Tu
     rule getTU(loc(_ @ static(Tu:String), _, _)) => Tu
     rule getTU(loc(_ @ link(Tu:String), _)) => Tu
     rule getTU(loc(_ @ link(Tu:String), _, _)) => Tu

     rule getThreadId(loc(_ @ thread(Th:Int), _)) => Th
     rule getThreadId(loc(_ @ thread(Th:Int), _, _)) => Th
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

     rule getBases(Loc:SymLoc) => getBases(prov(Loc))

     rule getBases(Prov:Set) => filterSet(Prov, '#isBases)

     rule transferProv(From:SymLoc, tv(To:SymLoc, T:Type))
          => tv(addProv(prov(From), To), T)
          [structural]
     rule transferProv(_:SymLoc, tv(V:CValue, T:Type)) => tv(V, T)
          requires isSymLoc(V:CValue) =/=K true
          [structural]
     rule transferProv(Prov:Set, tv(Loc:SymLoc, T:Type))
          => tv(addProv(Prov, Loc), T)
          [structural]
     rule transferProv(_:Set, tv(V:CValue, T:Type)) => tv(V, T)
          requires isSymLoc(V:CValue) =/=K true
          [structural]

     rule transferProv(From:SymLoc, lv(To:SymLoc, T:Type))
          => lv(addProv(prov(From), To), T)
          [structural]
     rule transferProv(Prov:Set, lv(Loc:SymLoc, T:Type))
          => lv(addProv(Prov, Loc), T)
          [structural]

     rule transferProv(From:SymLoc, lval(To:SymLoc, T:Type))
          => lval(addProv(prov(From), To), T)
          [structural]
     rule transferProv(Prov:Set, lval(Loc:SymLoc, T:Type))
          => lval(addProv(Prov, Loc), T)
          [structural]

     syntax Bool ::= #isBases(Provenance) [function]
     rule #isBases(basedOn(_, _)) => true
     rule #isBases(_) => false [owise]

     rule hasUnionMarker(Loc:SymLoc) => true
          requires #hasUnionMarker(.K, Loc)
     rule hasUnionMarker(Loc:SymLoc) => false [owise]

     syntax Bool ::= #hasUnionMarker(K, SymLoc) [function]
     rule #hasUnionMarker(fromUnion(_, _, _), _:SymLoc) => true
     rule #hasUnionMarker(K:K, loc(Base:SymBase, Offset:Int, SetItem(K':K) S:Set))
          => #hasUnionMarker(K', loc(Base, Offset, S))
          requires (K ==K .K) orBool (getKLabel(K) =/=KLabel 'fromUnion)
     rule #hasUnionMarker(_, _) => false [owise] 

     rule isFromArray(Loc:SymLoc) => #isFromArray(Loc)

     syntax Bool ::= #isFromArray(SymLoc) [function]
     rule #isFromArray(loc(Base:SymBase, Offset:Int, SetItem(K:K) S:Set))
          => getKLabel(K) ==KLabel 'fromArray orBool #isFromArray(loc(Base, Offset, S))
     rule #isFromArray(_) => false [owise]

     rule stripAllButFromUnion(loc(Base:SymBase, Offset:Int))
          => loc(Base, Offset)
     rule stripAllButFromUnion(NullPointer) => NullPointer
     rule stripAllButFromUnion(loc(Base:SymBase, Offset:Int, SetItem(K:K) S:Set))
          => #stripAllButFromUnion(Base, Offset, K, S, .Set)

     syntax SymLoc ::= #stripAllButFromUnion(SymBase, Int, K, Set, Set) [function]
     rule #stripAllButFromUnion(Base:SymBase, Offset:Int, K:K, .Set, S:Set)
          => loc(Base, Offset, SetItem(K) S)
          requires getKLabel(K) ==KLabel 'fromUnion
     rule #stripAllButFromUnion(Base:SymBase, Offset:Int, K:K, .Set, S:Set)
          => loc(Base, Offset, S)
          requires getKLabel(K) =/=KLabel 'fromUnion
     rule #stripAllButFromUnion(Base:SymBase, Offset:Int, K:K, SetItem(K':K) S':Set, S:Set)
          => #stripAllButFromUnion(Base, Offset, K', S', SetItem(K) S)
          requires getKLabel(K) ==KLabel 'fromUnion
     rule #stripAllButFromUnion(Base:SymBase, Offset:Int, K:K, SetItem(K':K) S':Set, S:Set)
          => #stripAllButFromUnion(Base, Offset, K', S', S)
          requires getKLabel(K) =/=KLabel 'fromUnion
     rule stripAllButFromUnion(Loc:SymLoc) => stripProv(Loc)
          when notBool hasUnionMarker(Loc)

     rule stripProv(loc(Base:SymBase, Offset:Int, _)) => loc(Base, Offset)
     rule stripProv(loc(Base:SymBase, Offset:Int)) => loc(Base, Offset)
     rule stripProv(NullPointer) => NullPointer

     rule getAlign(loc(_, _, Provs:Set)) => getAlign'(.K, Provs)
     rule getAlign(loc(_, _)) => 1

     // TODO(chathhorn): "unsupported map pattern" -- so ugly.
     syntax Int ::= "getAlign'" "(" K "," Set ")" [function]
     rule getAlign'(.K,.Set) => 1
     rule getAlign'(.K, SetItem(K:K) S:Set) => getAlign'(K, S)
     rule getAlign'(align(I:Int), _) => I
     rule getAlign'(K:K, S:Set) => getAlign'(.K, S)
          requires getKLabel(K) =/=KLabel 'align
               andBool (K =/=K .K)

     rule ifFromArrayInBounds(
               loc(_, _, SetItem(K:K) S:Set),
               T:Type, I:Int)
          => #ifFromArrayInBounds(K, S, T, I)
     rule ifFromArrayInBounds(Loc:SymLoc, _, _) => true
          when notBool isFromArray(Loc)

     syntax Bool ::= #ifFromArrayInBounds(K, Set, Type, Int) [function]
     rule #ifFromArrayInBounds(fromArray(Offset:Int, Len:Int), _, T:Type, I:Int)
          => true
          requires Offset +Int (I *Int byteSizeofType(innerType(T))) <=Int Len
     rule #ifFromArrayInBounds(fromArray(Offset:Int, Len:Int), _, T:Type, I:Int)
          => false
          requires Offset +Int (I *Int byteSizeofType(innerType(T))) >Int Len
     rule #ifFromArrayInBounds(K:K, .Set, _, _) => true
          requires getKLabel(K) =/=KLabel 'fromArray
     rule #ifFromArrayInBounds(K:K, SetItem(K':K) S:Set, T:Type, I:Int)
          => #ifFromArrayInBounds(K', S, T, I)
          requires getKLabel(K) =/=KLabel 'fromArray

endmodule

