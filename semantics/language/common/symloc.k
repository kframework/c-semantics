module C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX

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

     syntax Duration ::= "nativeAddress"
     syntax Duration ::= nativeSymbol(String)

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
     syntax Bool ::= isNativeLoc(SymLoc) [function]

     syntax SymBase ::= autoToRegister(SymBase) [function]

     syntax SymBase ::= Int "@" Duration


     // Base, byte offset, bit offset.
     syntax SymLoc ::= loc(SymBase, Int)
     syntax SymLoc ::= CanonicalSymLoc
     syntax CanonicalSymLoc ::= loc(SymBase, Int, Set)
     syntax CanonicalSymLoc ::= "NullPointer"

     syntax KResult ::= SymLoc

     syntax SymBase ::= linc(SymBase) [function]

     // Base, type
     syntax SymLoc ::= lnew(SymBase, Type) [function]
     syntax SymLoc ::= restrictedNew(SymBase, Type, Scope) [function]

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
     syntax Int ::= getBitOffset(SymLoc) [function]
     syntax Int ::= getNativeAlign(Int) [function]

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
     syntax Provenance ::= basedOn(SymBase, Scope)
     // Used to tag union members so the rest of the bytes in the union can be
     // marked as undefined upon write.
     syntax Provenance ::= fromUnion(SymLoc, CId, FieldInfo)
     // Used to tag lvalues with their type so that their alignment can be computed if needed
     syntax Provenance ::= fromType(Type)
     // used to tag bit fields so that we know how many bits into the current byte they begin
     syntax Provenance ::= bitOffset(Int)

     syntax Bool ::= hasUnionMarker(SymLoc) [function]

     syntax Bool ::= isFromArray(SymLoc) [function]

     syntax Bool ::= ifFromArrayInBounds(SymLoc, Type, Int) [function]

     syntax SymLoc ::= stripBases(SymLoc) [function]
     syntax SymLoc ::= stripFromArray(SymLoc) [function]
     syntax SymLoc ::= stripProv(SymLoc) [function]
endmodule

module C-SYMLOC
     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX

     imports COMPAT-SYNTAX

     rule isAllocatedDuration(loc(_ @ alloc, _)) => true
     rule isAllocatedDuration(loc(_ @ alloc, _, _)) => true
     rule isAllocatedDuration(_) => false [owise]

     rule isStaticDuration(loc(_ @ static(_), _)) => true
     rule isStaticDuration(loc(_ @ static(_), _, _)) => true
     rule isStaticDuration(loc(_ @ link(_), _)) => true
     rule isStaticDuration(loc(_ @ link(_), _, _)) => true
     rule isStaticDuration(loc(string(_), _)) => true
     rule isStaticDuration(loc(string(_), _, _)) => true
     rule isStaticDuration(loc(wstring(_), _)) => true
     rule isStaticDuration(loc(wstring(_), _, _)) => true
     rule isStaticDuration(_) => false [owise]

     rule isThreadDuration(loc(_ @ thread(_), _)) => true
     rule isThreadDuration(loc(_ @ thread(_), _, _)) => true
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

     rule isLinkerLoc(Loc:SymLoc) => true
          requires isLinkerLoc(base(Loc))
     rule isLinkerLoc(_:SymLoc) => false [owise]

     rule isArgvLoc(loc(_ @ argv, _)) => true
     rule isArgvLoc(loc(_ @ argv, _, _)) => true
     rule isArgvLoc(_) => false [owise]

     rule isRegisterLoc(loc(_ @ register(_), _)) => true
     rule isRegisterLoc(loc(_ @ register(_), _, _)) => true
     rule isRegisterLoc(_) => false [owise]

     rule isNativeLoc(loc(_ @ nativeAddress, _)) => true
     rule isNativeLoc(loc(_ @ nativeAddress, _, _)) => true
     rule isNativeLoc(loc(_ @ nativeSymbol(_), _)) => true
     rule isNativeLoc(loc(_ @ nativeSymbol(_), _, _)) => true
     rule isNativeLoc(_) => false [owise]

     rule autoToRegister(N:Int @ auto(Th:Int)) => N @ register(Th)

     rule base(loc(Base:SymBase, _)) => Base
     rule base(loc(Base:SymBase, _, _)) => Base

     rule offset(loc(_, Offset:Int)) => Offset
     rule offset(loc(_, Offset:Int, _)) => Offset

     rule linc(X:Int @ D:Duration) => (X +Int 1 @ D)

     rule lnew(Base:SymBase, T:Type)
          => loc(Base, 0, SetItem(fromType(T)))

     rule restrictedNew(Base:SymBase, T:Type, Tag:Scope)
          => addProv(basedOn(Base, Tag), lnew(Base, T))

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

     rule getBases(Prov:Set) => filterSet(Prov, #klabel(`isBase`))

     syntax Bool ::= isBase(Provenance) [function]
     rule isBase(basedOn(_, _)) => true
     rule isBase(_) => false [owise]

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

     rule transferProv(From:SymLoc, nclv(To:SymLoc, T:Type))
          => lv(addProv(prov(From), To), T)
          [structural]
     rule transferProv(Prov:Set, nclv(Loc:SymLoc, T:Type))
          => lv(addProv(Prov, Loc), T)
          [structural]

     rule hasUnionMarker(loc(Base:SymBase, Offset:Int, SetItem(K:K) S:Set))
          => getKLabel(K) ==K #klabel(`fromUnion`)
          orBool hasUnionMarker(loc(Base, Offset, S))
     rule hasUnionMarker(_) => false [owise]

     rule isFromArray(Loc:SymLoc) => #isFromArray(Loc)

     syntax Bool ::= #isFromArray(SymLoc) [function]
     rule #isFromArray(loc(Base:SymBase, Offset:Int, SetItem(K:K) S:Set))
          => getKLabel(K) ==K #klabel(`fromArray`) orBool #isFromArray(loc(Base, Offset, S))
     rule #isFromArray(_) => false [owise]

     rule stripBases(loc(Base:SymBase, Offset:Int)) => loc(Base, Offset)
     rule stripBases(loc(Base:SymBase, Offset:Int, Prov:Set))
          => loc(Base, Offset, filterSet(Prov, #klabel(`notBase`)))
     rule stripBases(Loc:SymLoc) => Loc [owise]

     syntax Bool ::= notBase(Provenance) [function]
     rule notBase(basedOn(_, _)) => false
     rule notBase(_) => true [owise]

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

     rule getAlign(loc(Base:SymBase, Offset:Int, Provs:Set)) => getAlign'(.K, Provs)
          requires notBool isNativeLoc(loc(Base, Offset, Provs))
     rule getAlign(NullPointer) => cfg:alignofMalloc
     rule getAlign(loc(0 @ nativeAddress, Offset:Int, _)) => getNativeAlign(Offset)
     rule getAlign(loc(0 @ nativeAddress, Offset:Int)) => getNativeAlign(Offset)
     rule getAlign(_) => 1 [owise]

     syntax Int ::= "getAlign'" "(" K "," Set ")" [function]
     rule getAlign'(.K, .Set) => 1
     rule getAlign'(.K, SetItem(K:K) S:Set) => getAlign'(K, S)
     rule getAlign'(fromType(T:Type), _) => getAlignas(T)
     rule getAlign'(K:KItem, S:Set) => getAlign'(.K, S)
          requires getKLabel(K) =/=K #klabel(`fromType`)

     syntax Int ::= #getBitOffset(K, Set) [function]
     rule getBitOffset(loc(_, _, Provs:Set)) => #getBitOffset(.K, Provs)
     rule #getBitOffset(.K, SetItem(K:K) S:Set) => #getBitOffset(K, S)
     rule #getBitOffset(bitOffset(I:Int), _) => I
     rule #getBitOffset(K:KItem, S:Set) => #getBitOffset(.K, S)
          requires getKLabel(K) =/=K #klabel(`bitOffset`)

     rule ifFromArrayInBounds(
               loc(_, _, SetItem(K:K) S:Set),
               T:Type, I:Int)
          => #ifFromArrayInBounds(K, S, T, I)
     rule ifFromArrayInBounds(Loc:SymLoc, _, _) => true
          requires notBool isFromArray(Loc)

     syntax Bool ::= #ifFromArrayInBounds(K, Set, Type, Int) [function]
     rule #ifFromArrayInBounds(fromArray(Offset:Int, Len:Int), _, T:Type, I:Int)
          => true
          requires (Offset +Int (I *Int byteSizeofType(innerType(T))) >=Int 0)
               andBool (Offset +Int (I *Int byteSizeofType(innerType(T))) <=Int Len)
     rule #ifFromArrayInBounds(fromArray(Offset:Int, Len:Int), _, T:Type, I:Int)
          => false
          requires (Offset +Int (I *Int byteSizeofType(innerType(T))) <Int 0)
               orBool (Offset +Int (I *Int byteSizeofType(innerType(T))) >Int Len)
     rule #ifFromArrayInBounds(K:K, .Set, _, _) => true
          requires getKLabel(K) =/=K #klabel(`fromArray`)
     rule #ifFromArrayInBounds(K:K, SetItem(K':K) S:Set, T:Type, I:Int)
          => #ifFromArrayInBounds(K', S, T, I)
          requires getKLabel(K) =/=K #klabel(`fromArray`)

     syntax Int ::= #getNativeAlign(Int, Int, Int) [function]
     rule getNativeAlign(Address:Int) => #getNativeAlign(Address, 1, 0)
     rule #getNativeAlign(Address:Int, Accum:Int, I:Int) => #getNativeAlign(Address /Int 2, Accum *Int 2, I +Int 1)
          requires Address %Int 2 ==Int 0 andBool I <Int cfg:ptrsize *Int cfg:bitsPerByte
     rule #getNativeAlign(_, Accum:Int, _) => Accum [owise]
endmodule

