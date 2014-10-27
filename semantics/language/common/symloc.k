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
     syntax Bool ::= isLinkerLoc(SymLoc) [function]
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
     syntax Int ::= getThreadId(SymLoc) [function]
     syntax Int ::= getAlign(SymLoc) [function]

     syntax Set ::= prov(SymLoc) [function]
     syntax Set ::= getBases(SymLoc) [function]
     syntax Set ::= getBases(Set) [function]
     syntax SymLoc ::= addProv(Provenance, SymLoc) [function]
     syntax SymLoc ::= addProv(Set, SymLoc) [function]
     // From, to.
     syntax K ::= transferProv(SymLoc, K) [strict(2)]
     syntax K ::= transferProv(Set, K) [strict(2)]

     // Pointers from an array need to be checked that they don't go out of
     // bounds of that array, even if that array happens to be part of a larger
     // object (i.e., surrounded by valid addresses).
     syntax Provenance ::= fromArray(Int, Int)
     // Used for detecting violations of aliasing restictions on
     // restrict-qualified pointers.
     syntax Provenance ::= basedOn(SymBase, RestrictTag)
     // Used to tag union members so the rest of the bytes in the union can be
     // marked as undefined upon write.
     syntax Provenance ::= fromUnion(SymLoc, CId, FieldInfo) [klabel('fromUnion)]
     syntax Provenance ::= align(Int) [klabel('align)]

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
     rule isLinkerLoc(Loc:SymLoc)
          => #isLinkerLoc(base(Loc)) ==K true
     rule isArgvLoc(Loc:SymLoc) 
          => #isArgvLoc(Loc) ==K true
     rule isRegisterLoc(Loc:SymLoc) 
          => #isRegisterLoc(Loc) ==K true

     rule autoToRegister(N:Int @ auto(Th:Int)) => N @ register(Th)

     rule #isAllocatedDuration(loc(_ @ allocated, _)) => true
     rule #isAllocatedDuration(loc(_ @ allocated, _, _)) => true

     rule #isStaticDuration(loc(_ @ static(_), _)) => true
     rule #isStaticDuration(loc(_ @ static(_), _, _)) => true
     rule #isStaticDuration(loc(_ @ link(_), _)) => true
     rule #isStaticDuration(loc(_ @ link(_), _, _)) => true
     rule #isStaticDuration(loc(string(_), _)) => true
     rule #isStaticDuration(loc(string(_), _, _)) => true
     rule #isStaticDuration(loc(wstring(_), _)) => true
     rule #isStaticDuration(loc(wstring(_), _, _)) => true

     rule #isThreadDuration(loc(_ @ thread(_), _)) => true
     rule #isThreadDuration(loc(_ @ thread(_), _, _)) => true

     rule #isAutoDuration(loc(_ @ auto(_), _)) => true
     rule #isAutoDuration(loc(_ @ auto(_), _, _)) => true
     rule #isAutoDuration(loc(_ @ argv, _)) => true
     rule #isAutoDuration(loc(_ @ argv, _, _)) => true
     rule #isAutoDuration(loc(_ @ register(_), _)) => true
     rule #isAutoDuration(loc(_ @ register(_), _, _)) => true

     rule #isStringLoc(loc(string(_), _)) => true
     rule #isStringLoc(loc(string(_), _, _)) => true
     rule #isStringLoc(loc(wstring(_), _)) => true
     rule #isStringLoc(loc(wstring(_), _, _)) => true

     rule #isLinkerLoc(_ @ link(_)) => true

     rule #isArgvLoc(loc(_ @ argv, _)) => true
     rule #isArgvLoc(loc(_ @ argv, _, _)) => true

     rule #isRegisterLoc(loc(_ @ register(_), _)) => true
     rule #isRegisterLoc(loc(_ @ register(_), _, _)) => true

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
          when isSymLoc(V) =/=K true
          [structural]
     rule transferProv(Prov:Set, tv(Loc:SymLoc, T:Type))
          => tv(addProv(Prov, Loc), T)
          [structural]
     rule transferProv(_:Set, tv(V:CValue, T:Type)) => tv(V, T)
          when isSymLoc(V) =/=K true
          [structural]

     rule transferProv(From:SymLoc, nclv(To:SymLoc, T:Type))
          => lv(addProv(prov(From), To), T)
          [structural]
     rule transferProv(Prov:Set, nclv(Loc:SymLoc, T:Type))
          => lv(addProv(Prov, Loc), T)
          [structural]

     syntax Bool ::= "#isBases" "(" Provenance ")" [function, klabel('#isBases)]
     rule #isBases(basedOn(_, _)) => true

     rule hasUnionMarker(Loc:SymLoc) => #hasUnionMarker(Loc) ==K true

     syntax Bool ::= #hasUnionMarker(SymLoc) [function]
     rule #hasUnionMarker(loc(_, _, SetItem(fromUnion(_, _, _)) _)) => true

     rule isFromArray(Loc:SymLoc) => #isFromArray(Loc) ==K true

     syntax Bool ::= "#isFromArray" "(" SymLoc ")" [function]
     rule #isFromArray(loc(_, _, SetItem(fromArray(_, _)) _)) => true

     rule stripAllButFromUnion(
          loc(Base:SymBase, Offset:Int,
               SetItem(fromUnion(Loc:SymLoc, X:CId, F:FieldInfo)) _))
          => loc(Base, Offset, SetItem(fromUnion(Loc, X, F)))
     rule stripAllButFromUnion(Loc:SymLoc) => stripProv(Loc)
          when notBool hasUnionMarker(Loc)

     rule stripProv(loc(Base:SymBase, Offset:Int, _)) => loc(Base, Offset)
     rule stripProv(loc(Base:SymBase, Offset:Int)) => loc(Base, Offset)
     rule stripProv(NullPointer) => NullPointer

     rule getAlign(loc(_, _, SetItem(align(A:Int)) _)) => A
     rule getAlign(loc(_, _, Prov:Set)) => 1
          when #hasAlign(Prov) =/=K true
     rule getAlign(loc(_, _)) => 1

     syntax Bool ::= "#hasAlign" "(" Set ")" [function]
     rule #hasAlign(SetItem(align(_)) _) => true

     rule ifFromArrayInBounds(
               loc(_, _, SetItem(fromArray(Offset:Int, Len:Int)) _),
               T:Type, I:Int)
          => true
          when Offset +Int (I *Int byteSizeofType(innerType(T))) <=Int Len
     rule ifFromArrayInBounds(
               loc(_, _, SetItem(fromArray(Offset:Int, Len:Int)) _),
               T:Type, I:Int)
          => false
          when Offset +Int (I *Int byteSizeofType(innerType(T))) >Int Len
     rule ifFromArrayInBounds(Loc:SymLoc, _, _) => true
          when notBool isFromArray(Loc)

endmodule

