module C-SYMLOC-SYNTAX
     imports SYMLOC-SYNTAX
     imports C-DYNAMIC-SORTS
     imports C-TYPING-SORTS
     imports COMMON-SORTS

     // Base, type
     syntax SymLoc ::= lnew(SymBase, Type) [function]
     syntax SymLoc ::= restrictedNew(SymBase, Type, Scope) [function]

     syntax Set ::= getBases(SymLoc) [function, klabel(getBases)]
     syntax Set ::= getBases(Set) [function]

     // From, to.
     syntax KItem ::= transferProv(Set, K) [strict(2)]

     syntax SymLoc ::= stripLastAccessType(CValue) [function]

     // Used for detecting violations of aliasing restictions on
     // restrict-qualified pointers.
     syntax Provenance ::= basedOn(SymBase, Scope)
     // Used to tag union and struct members so the rest of the bytes in the union 
     // (or the padding bytes of the struct) can be marked as unspecified upon write.
     syntax Provenance ::= fromUnion(SymLoc, CId, FieldInfo, Bool)
     // Used to tag lvalues with their last-access type for checking and
     // updating the effective types of accesses.
     syntax Provenance ::= objectType(Type)

     syntax Bool ::= hasUnionMarker(SymLoc) [function]
     syntax Bool ::= ifFromArrayInBounds(SymLoc, UType, Int) [function]

     syntax SymLoc ::= stripBases(SymLoc) [function]
endmodule

module C-SYMLOC
     imports C-SYMLOC-SYNTAX
     imports BOOL
     imports K-REFLECTION
     imports SET
     imports COMPAT-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     rule lnew(Base:SymBase, T:Type)
          => loc(Base, 0, .Set)
     rule restrictedNew(Base:SymBase, T:Type, Tag:Scope)
          => addProv(basedOn(Base, Tag), lnew(Base, T))

     rule getBases(Loc:SymLoc) => getBases(prov(Loc))

     rule getBases(Prov:Set) => filterSet(Prov, #klabel(`isBase`))

     syntax Bool ::= isBase(Provenance) [function]
     rule isBase(basedOn(_, _)) => true
     rule isBase(_) => false [owise]

     rule transferProv(Prov:Set, tv(Loc:SymLoc, T::UType))
          => tv(addProv(Prov, Loc), T)
          [structural]
     rule transferProv(_:Set, tv(V:CValue, T::UType)) => tv(V, T)
          requires isSymLoc(V:CValue) =/=K true
          [structural]
     rule transferProv(Prov:Set, nclv(Loc:SymLoc, T:Type))
          => lv(addProv(Prov, Loc), T)
          [structural]

     rule hasUnionMarker(loc(Base:SymBase, Offset:Int, SetItem(K:K) S:Set))
          => getKLabel(K) ==K #klabel(`fromUnion`)
          orBool hasUnionMarker(loc(Base, Offset, S))
     rule hasUnionMarker(_) => false [owise]

     rule stripBases(loc(Base:SymBase, Offset:Int)) => loc(Base, Offset)
     rule stripBases(loc(Base:SymBase, Offset:Int, Prov:Set))
          => loc(Base, Offset, filterSet(Prov, #klabel(`notBase`)))
     rule stripBases(Loc:SymLoc) => Loc [owise]

     syntax Bool ::= notBase(Provenance) [function]
     rule notBase(basedOn(_, _)) => false
     rule notBase(_) => true [owise]

     rule ifFromArrayInBounds(loc(_, _, SetItem(K:K) S:Set), T::UType, I:Int)
          => #ifFromArrayInBounds(K, S, T, I)
     rule ifFromArrayInBounds(Loc:SymLoc, _, _) => true
          requires notBool isFromArray(Loc)

     syntax Bool ::= #ifFromArrayInBounds(K, Set, UType, Int) [function]
     rule #ifFromArrayInBounds(fromArray(Offset:Int, Len:Int), _, T::UType, I:Int)
          => true
          requires (Offset +Int (I *Int byteSizeofType(innerType(T))) >=Int 0)
               andBool (Offset +Int (I *Int byteSizeofType(innerType(T))) <=Int Len)
     rule #ifFromArrayInBounds(fromArray(Offset:Int, Len:Int), _, T::UType, I:Int)
          => false
          requires (Offset +Int (I *Int byteSizeofType(innerType(T))) <Int 0)
               orBool (Offset +Int (I *Int byteSizeofType(innerType(T))) >Int Len)
     rule #ifFromArrayInBounds(K:K, .Set, _, _) => true
          requires getKLabel(K) =/=K #klabel(`fromArray`)
     rule #ifFromArrayInBounds(K:K, SetItem(K':K) S:Set, T::UType, I:Int)
          => #ifFromArrayInBounds(K', S, T, I)
          requires getKLabel(K) =/=K #klabel(`fromArray`)

     rule stripLastAccessType(loc(Base::SymBase, Offset::Int, Prov:Set SetItem(objectType(_))))
          => stripLastAccessType(loc(Base, Offset, Prov))
     rule stripLastAccessType(V::CValue) => V [owise]

endmodule
