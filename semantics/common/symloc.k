module SYMLOC-SORTS
     syntax IntPtr ::= PtrValue
     syntax PtrValue ::= SymLoc
     syntax SymBase
     syntax SymLoc
endmodule

module SYMLOC-SYNTAX
     imports SYMLOC-SORTS
     imports LIST
     imports COMPAT-SYNTAX

     syntax SymBase ::= base(IntPtr) [function]
     syntax Int ::= offset(SymLoc) [function]
     syntax Int ::= bitOffset(SymLoc) [function]
     syntax Int ::= bitOffsetIntoLastByte(SymLoc) [function]
     syntax SymLoc ::= setBitOffset(Int, SymLoc) [function]

     // libc duration
     syntax Duration ::= "libc"
     syntax Duration ::= "libcFixed"

     // Allocated duration.
     syntax Duration ::= "alloc"
     // Dynamic duration. (C++)
     syntax Duration ::= "dynamic"
     // Static duration.
     syntax Duration ::= static(String)
     syntax Duration ::= string(String)
     syntax Duration ::= wstring(List)
     syntax Duration ::= builtinSymbol(String)
     syntax Duration ::= builtinCppSymbol(String)
     syntax Duration ::= nativeSymbol(String)
     // Thread local duration.
     syntax Duration ::= threadLocal(Int)
     // Auto storage duration.
     syntax Duration ::= auto(Int)
                       | constexpr(String)
     syntax Duration ::= "argv"
     // We strip storage class specifiers when processing declarations, so this
     // is how we keep track of register-ness.
     syntax Duration ::= register(Int)

     syntax Duration ::= nativeAddress()

     syntax LinkDuration ::= link(String)

     syntax Bool ::= isAllocatedDuration(SymLoc) [function]
     syntax Bool ::= isAllocatedDuration(SymBase) [function, klabel(isAllocatedDuration2)]
     // I.e., static or link.
     syntax Bool ::= isStaticDuration(SymLoc) [function]
     syntax Bool ::= isStaticDuration(SymBase) [function, klabel(isStaticDuration2)]
     syntax Bool ::= isThreadDuration(SymLoc) [function]
     syntax Bool ::= isAutoDuration(SymLoc) [function]
     syntax Bool ::= isAutoDuration(SymBase) [function, klabel(isAutoDuration2)]

     syntax Bool ::= isStringLoc(SymLoc) [function]
     syntax Bool ::= isLinkerLoc(SymLoc) [function]
     syntax Bool ::= isBuiltinLoc(SymLoc) [function]
     syntax Bool ::= isBuiltinLoc(SymBase) [function, klabel(isBuiltinLoc2)]
     syntax Bool ::= isRegisterLoc(SymLoc) [function]
     syntax Bool ::= isNativeLoc(SymLoc) [function]
     syntax Bool ::= isNativeLoc(SymBase) [function, klabel(isNativeLoc2)]

     syntax SymBase ::= autoToRegister(SymBase) [function]

     syntax DirectBase ::= obj(id: Int, align: Int, d: Duration)
     syntax LinkBase ::= obj(id: Int, align: Int, d: LinkDuration)

     syntax SymBase ::= DirectBase | LinkBase

     syntax SymLoc ::= resolveLinking(SymLoc, Map) [function]

     // Base, byte offset, bit offset.
     syntax SymLoc ::= loc(SymBase, Int)
     syntax SymLoc ::= CanonicalSymLoc
     syntax CanonicalSymLoc ::= loc(SymBase, Int, Set) [klabel(loc3)]
     syntax CanonicalSymLoc ::= "NullPointer" [klabel(NullPointer)]

     syntax KResult ::= SymLoc

     syntax SymLoc ::= SymLoc "+bytes" Int [function]
     syntax SymLoc ::= SymLoc "+bits" Int [function]

     syntax Bool ::= SymLoc ">bytes" SymLoc [function]
                   | SymLoc ">=bytes" SymLoc [function]
                   | SymLoc "<bytes" SymLoc [function]
                   | SymLoc "<=bytes" SymLoc [function]
                   | SymLoc "==bytes" SymLoc [function]

     syntax Bool ::= sameBase(IntPtr, IntPtr) [function]
     syntax Bool ::= sameAddress(SymLoc, SymLoc) [function]

     syntax String ::= getTU(SymLoc) [function]
     syntax String ::= getTU(SymBase) [function, klabel(getTU2)]
     syntax ThreadId ::= getThreadId(SymLoc) [function]
     syntax ThreadId ::= Int | "no-thread"

     syntax Set ::= prov(SymLoc) [function]
     syntax SymLoc ::= addProv(Provenance, SymLoc) [function]
     syntax SymLoc ::= addProv(Set, SymLoc) [function]

     // Pointers from an array need to be checked that they don't go out of
     // bounds of that array, even if that array happens to be part of a larger
     // object (i.e., surrounded by valid addresses).
     syntax Provenance ::= fromArray(Int, Int)

     syntax Bool ::= isFromArray(SymLoc) [function]

     syntax SymLoc ::= stripFromArray(SymLoc) [function]
     syntax K ::= getFromArray(SymLoc) [function]
     syntax SymLoc ::= stripProv(SymLoc) [function]

     // Given a loc (with a bit offset) and a size in bits, calculate the
     // number of bytes from the loc's byte offset required to cover all bits.
     syntax Int ::= byteRange(SymLoc, Int) [function]

     syntax Set ::= getBases(SymLoc) [function, klabel(getBases)]
     syntax Set ::= getBases(Set) [function]

     // Used for detecting violations of aliasing restictions on
     // restrict-qualified pointers.
     syntax Provenance ::= basedOn(SymBase, Scope)

     // Using "fixed" to mean objects returned by library functions that
     // cause UB if the user tries to modify them.
     syntax Bool ::= isLibcFixedDuration(SymBase) [function]

     syntax String ::= showSymLoc(SymLoc) [function]
     syntax String ::= showSymBase(SymBase) [function]
     syntax String ::= showDuration(Duration) [function]

endmodule

module SYMLOC
     imports SYMLOC-SYNTAX
     imports COMPAT
     imports K-REFLECTION
     imports MAP
     imports SETTINGS-SYNTAX

     rule isAllocatedDuration(NullPointer) => false
     rule isAllocatedDuration(Loc:SymLoc) => isAllocatedDuration(base(Loc)) [owise]

     rule isAllocatedDuration(obj(... d: alloc)) => true
     rule isAllocatedDuration(_::SymBase) => false [owise]

     rule isStaticDuration(NullPointer) => false
     rule isStaticDuration(Loc:SymLoc) => isStaticDuration(base(Loc)) [owise]

     rule isStaticDuration(obj(... d: static(_))) => true
     rule isStaticDuration(obj(... d: link(_))) => true
     rule isStaticDuration(obj(... d: string(_))) => true
     rule isStaticDuration(obj(... d: wstring(_))) => true
     rule isStaticDuration(obj(... d: builtinSymbol(_))) => true
     rule isStaticDuration(obj(... d: builtinCppSymbol(_))) => true
     rule isStaticDuration(_::SymBase) => false [owise]

     rule isThreadDuration(loc(obj(... d: threadLocal(_)), _)) => true
     rule isThreadDuration(loc(obj(... d: threadLocal(_)), _, _)) => true
     rule isThreadDuration(_) => false [owise]

     rule isAutoDuration(NullPointer) => false
     rule isAutoDuration(Loc:SymLoc) => isAutoDuration(base(Loc)) [owise]

     rule isAutoDuration(obj(... d: auto(_))) => true
     rule isAutoDuration(obj(... d: argv)) => true
     rule isAutoDuration(obj(... d: register(_))) => true
     rule isAutoDuration(obj(... d: constexpr(_))) => true
     rule isAutoDuration(_::SymBase) => false [owise]

     rule isStringLoc(loc(obj(... d: string(_)), _)) => true
     rule isStringLoc(loc(obj(... d: string(_)), _, _)) => true
     rule isStringLoc(loc(obj(... d: wstring(_)), _)) => true
     rule isStringLoc(loc(obj(... d: wstring(_)), _, _)) => true
     rule isStringLoc(_) => false [owise]

     rule isLinkerLoc(NullPointer) => false
     rule isLinkerLoc(Loc:SymLoc) => isLinkBase(base(Loc)) [owise]

     rule isBuiltinLoc(NullPointer) => false
     rule isBuiltinLoc(Loc:SymLoc) => isBuiltinLoc(base(Loc)) [owise]

     rule isBuiltinLoc(obj(... d: builtinSymbol(_))) => true
     rule isBuiltinLoc(obj(... d: builtinCppSymbol(_))) => true
     rule isBuiltinLoc(_::SymBase) => false [owise]

     rule isRegisterLoc(loc(obj(... d: register(_)), _)) => true
     rule isRegisterLoc(loc(obj(... d: register(_)), _, _)) => true
     rule isRegisterLoc(_) => false [owise]

     rule isNativeLoc(obj(... d: nativeAddress())) => true
     rule isNativeLoc(obj(... d: nativeSymbol(_))) => true
     rule isNativeLoc(_::SymBase) => false [owise]

     rule isNativeLoc(NullPointer) => false
     rule isNativeLoc(Loc::SymLoc) => isNativeLoc(base(Loc)) [owise]

     rule autoToRegister(obj(Id::Int, Align::Int, auto(Th:Int))) => obj(Id, Align, register(Th))

     rule base(loc(Base:SymBase, _)) => Base
     rule base(loc(Base:SymBase, _, _)) => Base

     rule offset(loc(_, Offset:Int)) => Offset
     rule offset(loc(_, Offset:Int, _)) => Offset

     rule loc(Base:SymBase, Offset:Int) +bytes N:Int
          => loc(Base, Offset +Int N)
     rule loc(Base:SymBase, Offset:Int, Prov:Set) +bytes N:Int
          => loc(Base, Offset +Int N, Prov)
     rule NullPointer +bytes _ => NullPointer

     rule Loc::SymLoc +bits N:Int
          => setBitOffset(N %Int cfg:bitsPerByte, Loc +bytes (N /Int cfg:bitsPerByte))
     rule NullPointer +bits _ => NullPointer

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


     rule sameAddress(loc(A::SymBase, B::Int), loc(A::SymBase, B::Int)) => true
     rule sameAddress(loc(A::SymBase, B::Int, _), loc(A::SymBase, B::Int, _)) => true
     rule sameAddress(loc(A::SymBase, B::Int), loc(A::SymBase, B::Int, _)) => true
     rule sameAddress(loc(A::SymBase, B::Int, _), loc(A::SymBase, B::Int)) => true
     rule sameAddress(NullPointer, NullPointer) => true
     rule sameAddress(_, _) => false [owise]

     rule getTU(NullPointer) => ""
     rule getTU(Loc:SymLoc) => getTU(base(Loc)) [owise]

     rule getTU(obj(... d: static(Tu:String))) => Tu
     rule getTU(obj(... d: link(Tu:String))) => Tu
     rule getTU(obj(... d: nativeAddress())) => "native"
     rule getTU(obj(... d: nativeSymbol(_))) => "native"
     rule getTU(obj(... d: builtinSymbol(_))) => "builtin"
     rule getTU(obj(... d: builtinCppSymbol(_))) => "cpp-builtin"

     rule getThreadId(loc(obj(... d: threadLocal(Th:Int)), _)) => Th
     rule getThreadId(loc(obj(... d: threadLocal(Th:Int)), _, _)) => Th
     rule getThreadId(loc(obj(... d: auto(Th:Int)), _)) => Th
     rule getThreadId(loc(obj(... d: auto(Th:Int)), _, _)) => Th
     rule getThreadId(loc(obj(... d: register(Th:Int)), _)) => Th
     rule getThreadId(loc(obj(... d: register(Th:Int)), _, _)) => Th
     rule getThreadId(loc(obj(... d: argv), _)) => 0
     rule getThreadId(loc(obj(... d: argv), _, _)) => 0
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
     rule #isFromArray(loc(Base:SymBase, Offset:Int, SetItem(K:KItem) S:Set))
          => fromArray(...) :=K K orBool #isFromArray(loc(Base, Offset, S))
     rule #isFromArray(_) => false [owise]

     rule stripFromArray(loc(_, _, (SetItem(K:KItem) => .Set) _))
          requires fromArray(...) :=K K
     rule stripFromArray(Loc:SymLoc) => Loc [owise]

     rule getFromArray(loc(_, _, SetItem(fromArray(...) #as F::Provenance) _)) => F
     rule getFromArray(_::SymLoc) => .K [owise]

     rule stripProv(loc(Base:SymBase, Offset:Int, _)) => loc(Base, Offset)
     rule stripProv(loc(Base:SymBase, Offset:Int)) => loc(Base, Offset)
     rule stripProv(Loc:SymLoc) => Loc [owise]

     rule bitOffset(Loc::SymLoc) => (offset(Loc) *Int cfg:bitsPerByte) +Int getBitOffset(Loc)

     rule bitOffsetIntoLastByte(Loc::SymLoc) => getBitOffset(Loc)

     // used to tag bit fields so that we know how many bits into the current byte they begin
     syntax Provenance ::= bits(Int)
     syntax Int ::= getBitOffset(SymLoc) [function]
     rule getBitOffset(loc(_, _, _:Set SetItem(bits(I::Int)))) => I
     rule getBitOffset(_) => 0 [owise]

     rule setBitOffset(0, Loc::SymLoc) => Loc
     rule setBitOffset(Offset::Int, Loc::SymLoc) => addProv(bits(Offset), Loc) [owise]

     rule resolveLinking(loc(Base::SymBase, Offset::Int, Prov::Set), _ Base |-> Base'::SymBase) => loc(Base', Offset, Prov)
     rule resolveLinking(loc(Base::SymBase, Offset::Int), _ Base |-> Base'::SymBase) => loc(Base', Offset)
     rule resolveLinking(Loc::SymLoc, _) => Loc [owise]

     rule byteRange(Loc::SymLoc, Bits::Int)
          => (bitOffsetIntoLastByte(Loc) +Int Bits +Int cfg:bitsPerByte -Int 1) /Int cfg:bitsPerByte

     rule getBases(Loc:SymLoc) => getBases(prov(Loc))

     rule getBases((SetItem(K:KItem) => .Set) _)
          requires basedOn(...) :/=K K
     rule getBases(Prov:Set) => Prov [owise]

     rule isLibcFixedDuration(obj(... d: libcFixed)) => true
     rule isLibcFixedDuration(_) => false [owise]

     rule showSymLoc(loc(Base::SymBase, Offset::Int)) => wrapSymbolic(showSymBase(Base) +String " + " +String showInt(Offset))
     rule showSymLoc(loc(Base::SymBase, Offset::Int, Prov::Set)) => wrapSymbolic(showSymBase(Base) +String " + " +String showInt(Offset) +String showProvSet(Prov))
     rule showSymLoc(NullPointer) => wrapSymbolic("null")
     rule showSymLoc(V::SymLoc) => showK(V) [owise]

     rule showSymBase(obj(B::Int, Align::Int, D:Duration)) => showInt(B) +String " @ " +String showDuration(D) +String "/" +String showInt(Align)
     rule showSymBase(obj(B::Int, Align::Int, D:LinkDuration)) => showInt(B) +String " @ " +String showLinkDuration(D) +String "/" +String showInt(Align)
     rule showSymBase(B::SymBase) => showK(B) [owise]

     rule showDuration(libc) => "libc"
     rule showDuration(libcFixed) => "libcFixed"
     rule showDuration(alloc) => "alloc"
     rule showDuration(dynamic) => "dynamic"
     rule showDuration(static(S::String)) => "static" +String wrapParens(S)
     rule showDuration(string(S::String)) => "string" +String wrapParens(S)
     rule showDuration(wstring(_)) => "wstring"
     rule showDuration(builtinSymbol(S::String)) => "builtinSymbol" +String wrapParens(S)
     rule showDuration(builtinCppSymbol(S::String)) => "builtinCppSymbol" +String wrapParens(S)
     rule showDuration(nativeSymbol(S::String)) => "nativeSymbol" +String wrapParens(S)
     rule showDuration(threadLocal(N::Int)) => "threadLocal" +String wrapParens(showInt(N))
     rule showDuration(auto(N::Int)) => "auto" +String wrapParens(showInt(N))
     rule showDuration(constexpr(TU::String)) => "constexpr" +String wrapParens(TU)
     rule showDuration(argv) => "argv"
     rule showDuration(register(N::Int)) => "register" +String wrapParens(showInt(N))
     rule showDuration(nativeAddress()) => "native"
     rule showDuration(D::Duration) => showK(D) [owise]

     syntax String ::= showLinkDuration(LinkDuration) [function]
     rule showLinkDuration(link(S::String)) => "link" +String wrapParens(S)
     rule showLinkDuration(D::LinkDuration) => showK(D) [owise]

     syntax String ::= showProvSet(Set) [function]
     rule showProvSet(SetItem(P:Provenance) Prov::Set) => ", " +String showProvenance(P) +String showProvSet(Prov)
     rule showProvSet(.Set) => ""
     rule showProvSet(SetItem(P:KItem) Prov::Set) => ", " +String showK(P) +String showProvSet(Prov) [owise]

     syntax String ::= showProvenance(Provenance) [function]
     rule showProvenance(fromArray(A::Int, B::Int)) => "array" +String wrapParens(showInt(A) +String ", " +String showInt(B))
     rule showProvenance(basedOn(B::SymBase, _)) => "based" +String wrapParens(showSymBase(B))
     rule showProvenance(objectType(T::EffectiveType)) => showEffectiveType(T)
     rule showProvenance(P::Provenance) => showK(P) [owise]

     syntax String ::= wrapSymbolic(String) [function]
     rule wrapSymbolic(S::String) => "[" +String S +String "]"

     syntax String ::= wrapParens(String) [function]
     rule wrapParens(S::String) => "(" +String S +String ")"

endmodule

