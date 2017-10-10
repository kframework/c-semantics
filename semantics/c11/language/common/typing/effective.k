module C-TYPING-EFFECTIVE-SYNTAX
     imports BASIC-K
     imports C-DYNAMIC-SORTS
     imports C-TYPING-SORTS
     imports SYMLOC-SORTS

     syntax KItem ::= checkEffectiveType(SymLoc, Type)
     syntax KItem ::= getEffectiveType(SymBase)
     syntax SymLoc ::= stripLastAccessType(CValue) [function]
     syntax KItem ::= updateEffectiveType(SymLoc) [function]
     syntax KItem ::= adjustPointerBounds(RValue)
endmodule

module C-TYPING-EFFECTIVE
     imports C-TYPING-EFFECTIVE-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports K-REFLECTION
     imports INT
     imports BITS-SYNTAX
     imports SETTINGS-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-TYPING-COMMON-SYNTAX

     rule <k> checkEffectiveType(Loc::SymLoc, T::Type)
               => checkEffectiveType'(Loc, T,
                    offset(Loc) *Int cfg:bitsPerByte +Int getBitOffset(Loc),
                    base(Loc), getLastAccessType(Loc))
          ...</k>
          <mem> Mem::Map </mem>
          requires base(Loc) in_keys(Mem)
               andBool notBool isFunctionType(T)
          [structural]
     rule <k> checkEffectiveType(Loc::SymLoc, T::Type) => nclv(Loc, T) ...</k>
          <mem> Mem::Map </mem>
          requires notBool (base(Loc) in_keys(Mem))
               orBool isFunctionType(T)
          [structural]

     // The lvalue SymLoc carries with it a last-access object type which, in a
     // sense, is a composite type formed from the current effective type plus
     // the type of compatible lvalue expressions based on it (which may only
     // refer to a part of the object). By composite type, we just mean the
     // effective type with extra annotations for tracking locked union
     // variants. When a write occurs through a SymLoc, its attached
     // last-access type becomes the effective type of the object.

     // First we check the lvalue for compatibility with the last access type.
     syntax KItem ::= "checkEffectiveType'" "(" SymLoc "," Type "," Int "," SymBase "," K ")" [strict(5)]
     rule checkEffectiveType'(Loc::SymLoc, L::Type, Offset::Int, Base::SymBase, t(...) #as LAT::Type)
          // If compatible, the new last access type becomes a composite of the
          // current last-access object type and the type of the current lvalue
          // expression.
          => nclv(setLastAccessType(Loc, newLastAccessType(LAT, L, Offset)), L)
          // An lvalue is compatible if it's compatible with at least one of
          // the types at the given offset into the object.
          requires effectivelyCompat(L, getTypesAtOffset(LAT, Offset))
          [structural]
     rule checkEffectiveType'(Loc::SymLoc, L::Type, Offset::Int, Base::SymBase, dynamicType(Eff::Type))
          => nclv(setLastAccessType(Loc, dynamicType(newLastAccessType(Eff, L, Offset))), L)
          requires effectivelyCompat(L, getTypesAtOffset(Eff, Offset))
               orBool effectivelyCompat(Eff, getTypesAtOffset(L, Offset))
               orBool isNoType(Eff)
          [structural]
     rule (.K => effectiveTypeViolation(L, Eff))
          ~> checkEffectiveType'(_, L::Type, Offset::Int, _, t(...) #as Eff::Type)
          requires notBool effectivelyCompat(L, getTypesAtOffset(Eff, Offset))
          [structural]
     rule (.K => effectiveTypeViolation(L, Eff))
          ~> checkEffectiveType'(_, L::Type, Offset::Int, _, dynamicType(Eff::Type))
          requires notBool effectivelyCompat(L, getTypesAtOffset(Eff, Offset))
               andBool notBool effectivelyCompat(Eff, getTypesAtOffset(L, Offset))
               andBool notBool isNoType(Eff)
          [structural]

     syntax KItem ::= effectiveTypeViolation(Type, Type)
     rule effectiveTypeViolation(L::Type, Eff::Type)
          => UNDEF("EIO10", "Type of lvalue (" +String showType(L) +String ") not compatible with the effective type of the object being accessed (" +String showType(Eff) +String ").")
          [structural]

     syntax Type ::= newLastAccessType(Type, Type, Int) [function]
     rule newLastAccessType(Eff::Type, L:CharType, Offset::Int)
          => #if isNoType(tracePath(Eff, L, Offset))
               #then Eff #else tracePath(Eff, L, Offset) #fi
     rule newLastAccessType(Eff::Type, L::Type, Offset::Int)
          => #if isNoType(tracePath(Eff, L, Offset))
               #then L #else tracePath(Eff, L, Offset) #fi
          requires isFlexibleType(Eff) andBool notBool isCharType(L)
     rule newLastAccessType(Eff::Type, L::Type, Offset::Int)
          => #if (bitSizeofType(Eff) ==Int 0) orBool isNoType(tracePath(Eff, L, Offset %Int bitSizeofType(Eff)))
               #then L #else tracePath(Eff, L, Offset %Int bitSizeofType(Eff)) #fi
          [owise]

     // We form a composite type by locating the lvalue type in the (larger)
     // object type and tracing the path (i.e., union variants) that gets us
     // there. We lock unions to a particular variant when we pick a variant
     // and unlock them when the path ends in a union type (as opposed to the
     // type of a paricular variant).
     syntax Type ::= tracePath(Type, Type, Int) [function]
     rule tracePath(T::Type, L::Type, 0) => clearActiveVariant(T)
          requires #effectivelyCompat(L, T)
     rule tracePath(t(Qs::Quals, _, bitfieldType(T'::SimpleType, _)) #as T::Type, L::Type, _)
          => T
          requires notBool #effectivelyCompat(L, T)
               andBool #effectivelyCompat(L, addQualifiers(Qs, type(T')))

     // In the case of aggregates, the type might be the type of the aggregate
     // or its first element if the offset is 0.
     rule tracePath(T:ArrayType, L::Type, Offset::Int)
          => setInnerType(tracePath(innerType(T), L, Offset %Int bitSizeofType(innerType(T))), T)
          requires notBool #effectivelyCompat(L, T)
               andBool bitSizeofType(innerType(T)) >Int 0
               andBool notBool isNoType(tracePath(innerType(T), L, Offset %Int bitSizeofType(innerType(T))))

     rule tracePath(T:StructType, L::Type, Offset::Int)
          => setFieldTypeAtOffset(Offset, tracePath(getFieldTypeAtOffset(Offset, T), L, Offset -Int floorFieldOffset(Offset, T)), T)
          requires notBool #effectivelyCompat(L, T)
               andBool notBool isNoType(tracePath(getFieldTypeAtOffset(Offset, T), L, Offset -Int floorFieldOffset(Offset, T)))
     rule tracePath(T:UnionType, L::Type, Offset::Int)
          => tracePathInUnion(getFieldDecls(T), T, L, Offset)
          requires notBool #effectivelyCompat(L, T)

     rule tracePath(_, _, _) => type(no-type) [owise]

     // In the case of unions, we make the first compatible variant active (via
     // the "lock" modifier) and continue from the type of the variant.
     syntax Type ::= tracePathInUnion(List, UnionType, Type, Int) [function]
     rule tracePathInUnion(ListItem(typedDeclaration(_, F::CId)) _, T::UnionType, L::Type, Offset::Int)
          => setActiveVariant(F, {setFieldType(F, tracePath(getFieldType(F, T), L, Offset), T)}:>UnionType)
          requires notBool isNoType(tracePath(getFieldType(F, T), L, Offset))
     rule tracePathInUnion(ListItem(typedDeclaration(_, F::CId)) Decls::List, T::UnionType, L::Type, Offset::Int)
          => tracePathInUnion(Decls, T, L, Offset)
          requires isNoType(tracePath(getFieldType(F, T), L, Offset))
     rule tracePathInUnion(_, _, _, _) => type(no-type) [owise]

     // An  object shall have its stored value accessed only by an lvalue
     // expression that has one of the following types:
     // - a type compatible with the effective type of the object,
     // - a qualified version of a type compatible with the effective type of
     // the object,
     syntax Bool ::= #effectivelyCompat(Type, Type) [function]
     rule #effectivelyCompat(L::Type, Eff::Type) => true
          requires stripQualifiers(L) ==Type stripQualifiers(Eff)
               andBool getQualifiers(Eff) <=Quals getQualifiers(L)
     // - a type that is the signed or unsigned type corresponding to the
     // effective type of the object,
     // - a type that is the signed or unsigned type corresponding to a
     // qualified version of the effective type of the object,
     rule #effectivelyCompat(L:SignedIntegerType, Eff::Type) => true
          requires type(correspondingUnsignedType(utype(L)))
                    ==Type stripQualifiers(Eff)
               andBool getQualifiers(Eff) <=Quals getQualifiers(L)
     rule #effectivelyCompat(L:UnsignedIntegerType, Eff::Type) => true
          requires notBool isBoolType(L)
               andBool type(correspondingSignedType(utype(L)))
                    ==Type stripQualifiers(Eff)
               andBool getQualifiers(Eff) <=Quals getQualifiers(L)
     rule #effectivelyCompat(_, _) => false [owise]

     // - an aggregate or union type that includes one of the aforementioned
     // types among its members (including, recursively, a member of a
     // subaggregate or contained union), or
     syntax Bool ::= effectivelyCompat(Type, List) [function]
     rule effectivelyCompat(L::Type, ListItem(Eff::Type) _) => true
          requires #effectivelyCompat(L, Eff)
     rule effectivelyCompat(L::Type, (ListItem(Eff::Type) => .List) _)
          requires notBool #effectivelyCompat(L, Eff)
     // - a character type.
     rule effectivelyCompat(_:CharType, _) => true
     rule effectivelyCompat(_, _) => false [owise]

     // Used to tag lvalues with their last-access type for checking and
     // updating the effective types of accesses.
     syntax Provenance ::= objectType(EffectiveType)

     syntax SymLoc ::= setLastAccessType(SymLoc, EffectiveType) [function]
     rule setLastAccessType(Loc::SymLoc, T::EffectiveType)
          => addProv(objectType(T), stripLastAccessType(Loc))

     syntax KItem ::= getLastAccessType(SymLoc) [function]
     rule getLastAccessType(loc(_, _, _:Set SetItem(objectType(T::Type)))) => T
     rule getLastAccessType(Loc::SymLoc) => getEffectiveType(base(Loc)) [owise]

     rule stripLastAccessType(loc(Base::SymBase, Offset::Int, Prov:Set SetItem(objectType(_))))
          => stripLastAccessType(loc(Base, Offset, Prov))
     rule stripLastAccessType(V::CValue) => V [owise]

     rule getTypesAtOffset(t(Qs::Quals, _, bitfieldType(InnerT::SimpleType, _)) #as T::Type, 0)
          => ListItem(T) ListItem(t(Qs, .Set, InnerT))
     // we have some redundancy here because we are trying to make matching as fast as possible,
     // so we avoid side conditions on these rules as much as we can.
     rule getTypesAtOffset(t(Qs::Quals, _, arrayType(InnerT::Type, _)) #as T::Type, 0)
          => ListItem(T) getTypesAtOffset(addQualifiers(Qs, InnerT), 0)
     rule getTypesAtOffset(t(Qs::Quals, _, incompleteArrayType(InnerT::Type)) #as T::Type, 0)
          => ListItem(T) getTypesAtOffset(addQualifiers(Qs, InnerT), 0)
     rule getTypesAtOffset(t(Qs::Quals, _, flexibleArrayType(InnerT::Type)) #as T::Type, 0)
          => ListItem(T) getTypesAtOffset(addQualifiers(Qs, InnerT), 0)
     rule getTypesAtOffset(t(Qs::Quals, _, unspecifiedArrayType(InnerT::Type)) #as T::Type, 0)
          => ListItem(T) getTypesAtOffset(addQualifiers(Qs, InnerT), 0)
     rule getTypesAtOffset(t(Qs::Quals, _, variableLengthArrayType(InnerT::Type, _)) #as T::Type, 0)
          => ListItem(T) getTypesAtOffset(addQualifiers(Qs, InnerT), 0)
     rule getTypesAtOffset(t(Qs::Quals, _, structType(_)) #as T::StructType, 0)
          => ListItem(T) getTypesAtOffset(addQualifiers(Qs, getFieldTypeAtOffset(0, T)), 0)
     rule getTypesAtOffset(t(Qs::Quals, _, unionType(_)) #as T::UnionType, 0)
          => ListItem(T) #if isNoType(getActiveVariant(T))
               #then getTypesAtOffsetInTypes(addQualifiersToList(Qs, getFieldTypes(T)), 0)
               #else getTypesAtOffset(addQualifiers(Qs, getActiveVariant(T)), 0) #fi

     rule getTypesAtOffset(t(Qs::Quals, _, arrayType(InnerT::Type, _)) #as T::Type, Offset::Int)
          => #if isCompleteType(InnerT) andBool bitSizeofType(InnerT) >Int 0
               #then getTypesAtOffset(addQualifiers(Qs, InnerT), Offset %Int bitSizeofType(InnerT)) #else .List #fi
          requires Offset >Int 0 andBool Offset <Int bitSizeofType(T)
     rule getTypesAtOffset(t(Qs::Quals, _, incompleteArrayType(InnerT::Type)) #as T::Type, Offset::Int)
          => #if isCompleteType(InnerT) andBool bitSizeofType(InnerT) >Int 0
               #then getTypesAtOffset(addQualifiers(Qs, InnerT), Offset %Int bitSizeofType(InnerT)) #else .List #fi
          requires Offset >Int 0
     rule getTypesAtOffset(t(Qs::Quals, _, flexibleArrayType(InnerT::Type)) #as T::Type, Offset::Int)
          => #if isCompleteType(InnerT) andBool bitSizeofType(InnerT) >Int 0
               #then getTypesAtOffset(addQualifiers(Qs, InnerT), Offset %Int bitSizeofType(InnerT)) #else .List #fi
          requires Offset >Int 0
     rule getTypesAtOffset(t(Qs::Quals, _, unspecifiedArrayType(InnerT::Type)) #as T::Type, Offset::Int)
          => #if isCompleteType(InnerT) andBool bitSizeofType(InnerT) >Int 0
               #then getTypesAtOffset(addQualifiers(Qs, InnerT), Offset %Int bitSizeofType(InnerT)) #else .List #fi
          requires Offset >Int 0
     rule getTypesAtOffset(t(Qs::Quals, _, variableLengthArrayType(InnerT::Type, _)) #as T::Type, Offset::Int)
          => #if isCompleteType(InnerT) andBool bitSizeofType(InnerT) >Int 0
               #then getTypesAtOffset(addQualifiers(Qs, InnerT), Offset %Int bitSizeofType(InnerT)) #else .List #fi
          requires Offset >Int 0 andBool Offset <Int bitSizeofType(T)
     rule getTypesAtOffset(t(Qs::Quals, _, structType(_)) #as T::StructType, Offset::Int)
          => getTypesAtOffset(addQualifiers(Qs, getFieldTypeAtOffset(Offset, T)), Offset -Int floorFieldOffset(Offset, T))
          requires Offset >Int 0 andBool (isFlexibleType(T) orBool Offset <Int bitSizeofType(T))
     rule getTypesAtOffset(t(Qs::Quals, _, unionType(_)) #as T::UnionType, Offset::Int)
          => #if isNoType(getActiveVariant(T))
               #then getTypesAtOffsetInTypes(addQualifiersToList(Qs, getFieldTypes(T)), Offset)
               #else getTypesAtOffset(addQualifiers(Qs, getActiveVariant(T)), Offset) #fi
          requires Offset >Int 0 andBool (isFlexibleType(T) orBool Offset <Int bitSizeofType(T))
     rule getTypesAtOffset(T::Type, Offset::Int)
          => #if (bitSizeofType(T) >Int 0) andBool (Offset >=Int bitSizeofType(T)) #then getTypesAtOffset(T, Offset %Int bitSizeofType(T))
               #else #if Offset ==Int 0 #then ListItem(T) #else .List #fi #fi [owise]

     syntax List ::= getTypesAtOffsetInTypes(List, Int) [function]
     rule getTypesAtOffsetInTypes(ListItem(T::Type) Types::List, Offset::Int)
          => getTypesAtOffset(T, Offset) getTypesAtOffsetInTypes(Types, Offset)
     rule getTypesAtOffsetInTypes(_, _) => .List [owise]

     syntax List ::= addQualifiersToList(Quals, List) [function]
     rule addQualifiersToList(Qs::Quals, ListItem(T::Type) Ts::List)
          => ListItem(addQualifiers(Qs, T)) addQualifiersToList(Qs, Ts)
     rule addQualifiersToList(_, _) => .List [owise]

     rule <k> getEffectiveType(Base::SymBase) => T ...</k>
          <mem>... Base |-> object(t(...) #as T::Type, _, _) ...</mem>
          [structural]
     rule <k> getEffectiveType(Base::SymBase) => T ...</k>
          <functions>... Base |-> functionObject(_, t(...) #as T::Type, _) ...</functions>
          [structural]
     rule <k> getEffectiveType(Base::SymBase) => T ...</k>
          <mem>... Base |-> object(T:DynamicType, _, _) ...</mem>
          requires notBool isFlexibleType(T)
          [structural]
     // Set the length of the flexible array member for structs in a malloced
     // region.
     rule <k> getEffectiveType(Base::SymBase) => lockFlexibleType(T, Len) ...</k>
          <mem>... Base |-> object(T:DynamicType, Len::Int, _) ...</mem>
          requires isFlexibleType(T)
          [structural]

     // Set the new effective type to a last-access type attached to the
     // lvalue, if it exists.
     rule updateEffectiveType(Loc::SymLoc) => setEffectiveType(base(Loc), getLastAccessType(Loc))

     syntax KItem ::= setEffectiveType(SymBase, K) [strict(2)]
     rule <k> setEffectiveType(Base::SymBase, T::Type) => .K ...</k>
          <mem>... Base |-> object(_ => T, _, _) ...</mem>
          requires notBool isNoType(T)
     rule <k> setEffectiveType(Base::SymBase, T:NoType) => .K ...</k>
          <mem>... Base |-> object(_ => dynamicType(T), _, _) ...</mem>

     // Locks the type of the flexible array member to a fixed array.
     syntax DynamicType ::= lockFlexibleType(DynamicType, Int) [function]
     rule lockFlexibleType(dynamicType(T::Type), N::Int) => dynamicType(lockFlexibleType'(T, N -Int byteSizeofType(T)))
          requires N >Int byteSizeofType(T)
     rule lockFlexibleType(dynamicType(T::Type), _) => dynamicType(lockFlexibleType'(T, 1)) [owise]

     syntax Type ::= "lockFlexibleType'" "(" Type "," Int ")" [function]
     rule lockFlexibleType'(T:StructType, N::Int) => lockFlexibleStruct(T, findFieldDecls(T), N)
     rule lockFlexibleType'(T:UnionType, N::Int) => lockFlexibleUnion(T, getFieldDecls(T), N)

     syntax StructType ::= lockFlexibleStruct(StructType, List, Int) [function]
     rule lockFlexibleStruct(T::StructType, _ ListItem(typedDeclaration(t(Qs::Quals, Mods::Set, flexibleArrayType(T'::Type)), F::CId)), N::Int)
          => setFieldType(F, t(Qs, Mods, arrayType(T', N)), T)
     rule lockFlexibleStruct(T::StructType, _, _) => T [owise]

     syntax UnionType ::= lockFlexibleUnion(UnionType, List, Int) [function]
     rule lockFlexibleUnion(T::UnionType, ListItem(typedDeclaration(T':StructOrUnionType, F::CId)) Decls::List, N::Int)
          => lockFlexibleUnion({setFieldType(F, lockFlexibleType'(T', N), T)}:>UnionType, Decls, N)
     rule lockFlexibleUnion(T::UnionType, _, _) => T [owise]

     rule <k> adjustPointerBounds(tv(Loc::SymLoc, ut(_, pointerType(T'::Type)) #as T::UType))
               => adjustPointerBounds'(Loc, T, T', getEffectiveType(base(Loc)))
          ...</k>
          <mem> Mem::Map </mem>
          requires base(Loc) in_keys(Mem)
     rule <k> adjustPointerBounds(tv(Loc::SymLoc, T::UType)) => tv(Loc, T) ...</k>
          <mem> Mem::Map </mem>
          requires notBool (base(Loc) in_keys(Mem))

     syntax KItem ::= "adjustPointerBounds'" "(" SymLoc "," UType "," Type "," K ")" [strict(4)]
     rule adjustPointerBounds'(Loc::SymLoc, T::UType, T'::Type, Eff:Type)
          => tv(adjustBounds(Loc, T'), T)
          requires notBool isCharType(T') andBool effectivelyCompat(T', getTypesAtOffset(Eff, offset(Loc)))
     rule adjustPointerBounds'(Loc::SymLoc, T::UType, T'::Type, Eff:Type)
          => tv(Loc, T)
          requires isCharType(T') orBool notBool effectivelyCompat(T', getTypesAtOffset(Eff, offset(Loc)))
     rule adjustPointerBounds'(Loc::SymLoc, T::UType, T'::Type, dynamicType(Eff:Type))
          => tv(adjustBounds(Loc, T'), T)
          requires notBool isCharType(T') andBool (effectivelyCompat(T', getTypesAtOffset(Eff, offset(Loc)))
               orBool effectivelyCompat(Eff, getTypesAtOffset(T', offset(Loc))))
     rule adjustPointerBounds'(Loc::SymLoc, T::UType, T'::Type, dynamicType(Eff:Type))
          => tv(Loc, T)
          requires isCharType(T') orBool notBool (effectivelyCompat(T', getTypesAtOffset(Eff, offset(Loc)))
               orBool effectivelyCompat(Eff, getTypesAtOffset(T', offset(Loc))))

     syntax SymLoc ::= adjustBounds(SymLoc, Type) [function]
     rule adjustBounds(loc(_, _, SetItem(fromArray(_, N::Int)) _) #as Loc::SymLoc, T::Type)
          => addProv(fromArray(0, byteSizeofType(T)), stripFromArray(Loc))
          requires byteSizeofType(T) >Int N
     // TODO(chathhorn): only allow adjusting the size up for now (because we
     // need to be able to distinguish a pointer into an array of T from a
     // pointer to a T not in an array here).
     rule adjustBounds(Loc::SymLoc, _) => Loc [owise]

endmodule
