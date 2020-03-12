module C-TYPING-EFFECTIVE-SYNTAX
     imports BASIC-K
     imports INT-SYNTAX
     imports C-DYNAMIC-SORTS
     imports C-TYPING-SORTS
     imports SYMLOC-SORTS

     syntax K ::= checkEffectiveType(Type, Int, EffectiveType) [function]
     syntax KItem ::= adjustPointerBounds(RValue)

     syntax KItem ::= getLastAccessType(SymLoc)
     syntax CValue ::= stripLastAccessType(CValue) [function]
     syntax SymLoc ::= updateLastAccessType(SymLoc, Type, EffectiveType) [function]

     syntax SymLoc ::= updateLastAccessVariant(SymLoc, CId, EffectiveType) [function]

     syntax KItem ::= getEffectiveType(SymBase)
     syntax K ::= updateEffectiveType(SymLoc) [function]

     syntax Bool ::= effectivelyCompat(Type, List) [function]

     // Returns all types at an offset -- i.e., for a struct, union, or array,
     // it'll return the struct/union/array type in addition to the type or
     // types of its members. It only returns the type of the active variant of
     // a union, if there is one. Otherwise, it returns the types of all
     // variants.
     syntax List ::= getTypesAtOffset(Type, Int) [function]

     syntax KItem ::= getFixedFieldType(SymLoc, CId, Type)
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

     rule updateLastAccessType(Loc::SymLoc, T::Type, dynamicType(LAT::Type))
          => setLastAccessType(Loc, dynamicType(LAT))
          requires effectivelyCompat(T, getTypesAtOffset(LAT, bitOffset(Loc)))
               andBool notBool isNoType(LAT)
     rule updateLastAccessType(Loc::SymLoc, T::Type, dynamicType(LAT::Type))
          => setLastAccessType(Loc, dynamicType(T))
          requires effectivelyCompat(LAT, getTypesAtOffset(T, bitOffset(Loc)))
               andBool notBool effectivelyCompat(T, getTypesAtOffset(LAT, bitOffset(Loc)))
               andBool notBool isNoType(LAT)
     rule updateLastAccessType(Loc::SymLoc, T::Type, dynamicType(t(... st: no-type)))
          => setLastAccessType(Loc, dynamicType(T))
     rule updateLastAccessType(Loc::SymLoc, T::Type, t(... st: no-type))
          => setLastAccessType(Loc, dynamicType(T))
     rule updateLastAccessType(Loc::SymLoc, _, _) => Loc [owise]

     rule updateLastAccessVariant(Loc::SymLoc, F::CId, LAT::EffectiveType)
          => setLastAccessType(Loc, setVariantAtOffset(LAT, F, bitOffset(Loc)))
          requires Loc =/=K NullPointer
     rule updateLastAccessVariant(Loc::SymLoc, _, _) => Loc [owise]

     rule <k> getLastAccessType(loc(Base::SymBase, _, SetItem(objectType(T::EffectiveType)) _::Set))
               => fixFlexibleType(T, Len)
          ...</k>
          <mem>... Base |-> object(_, Len::Int, _) ...</mem>
     rule <k> getLastAccessType(Loc::SymLoc) => getEffectiveType(base(Loc)) ...</k>
          <mem> Mem::Map </mem>
          requires Loc =/=K NullPointer
               andBool (notBool hasLAT(Loc) orBool notBool base(Loc) in_keys(Mem))
     rule getLastAccessType(NullPointer) => type(no-type)

     syntax Bool ::= hasLAT(SymLoc) [function]
     rule hasLAT(loc(_, _, SetItem(objectType(_)) _)) => true
     rule hasLAT(_) => false [owise]

     syntax SymLoc ::= setLastAccessType(SymLoc, EffectiveType) [function]
     rule setLastAccessType(Loc::SymLoc, T::EffectiveType)
          => addProv(objectType(T), {stripLastAccessType(Loc)}:>SymLoc)

     rule stripLastAccessType(loc(Base::SymBase, Offset::Int, Prov::Set SetItem(objectType(_))))
          => stripLastAccessType(loc(Base, Offset, Prov))
     rule stripLastAccessType(V::CValue) => V [owise]

     // Set the length of the flexible array member for structs in a malloced
     // region.
     rule <k> getEffectiveType(Base::SymBase) => fixFlexibleType(T, Len) ...</k>
          <mem>... Base |-> object(T::EffectiveType, Len::Int, _) ...</mem>
          [structural]
     rule <k> getEffectiveType(Base::SymBase) => T ...</k>
          <functions>... Base |-> functionObject(... defType: t(...) #as T::Type) ...</functions>
          [structural]
     rule <k> getEffectiveType(Base::SymBase) => type(no-type) ...</k>
          <mem> Mem::Map </mem>
          <functions> Funs::Map </functions>
          requires notBool (Base in_keys(Mem))
               andBool notBool (Base in_keys(Funs))
          [structural]

     // Set the new effective type to a last-access type attached to the
     // lvalue, if it exists.
     rule updateEffectiveType(loc(Base::SymBase, _, SetItem(objectType(T::EffectiveType)) _))
          => setEffectiveType(Base, T)
     rule updateEffectiveType(_) => .K [owise]

     syntax KItem ::= setEffectiveType(SymBase, KItem) [strict(2)]
     rule <k> setEffectiveType(Base::SymBase, T'::EffectiveType) => .K ...</k>
          <mem>... Base |-> object(T::EffectiveType => mergeVariants(T, T'), _, _) ...</mem>
          requires notBool isNoType(T')
     rule <k> setEffectiveType(Base::SymBase, t(... st: no-type) #as T'::Type) => .K ...</k>
          <mem>... Base |-> object(dynamicType(_ => T'), _, _) ...</mem>
     rule <k> setEffectiveType(Base::SymBase, t(... st: no-type) #as T'::Type) => .K ...</k>
          <mem>... Base |-> object(T::EffectiveType, _, _) ...</mem>
          requires notBool isDynamicType(T)

     rule getFixedFieldType(loc(_, _, _) #as Loc::SymLoc, F::CId, T::Type)
          => getFixedFieldType(stripProv(Loc), F, T)
     rule getFixedFieldType(loc(_, _), F::CId, T::Type) => findFieldType(F, T)
          requires notBool isFlexibleArrayType(findFieldType(F, T))
     rule <k> getFixedFieldType(loc(Base::SymBase, Offset::Int), F::CId, T::Type)
               => fixFlexibleArray'(findFieldType(F, T), Len -Int (Offset +Int (findFieldOffset(F, T) /Int cfg:bitsPerByte)))
          ...</k>
          <mem>... Base |-> object(_, Len::Int, _) ...</mem>
          requires isFlexibleArrayType(findFieldType(F, T))
     rule <k> getFixedFieldType(loc(Base::SymBase, _), F::CId, T::Type)
               => findFieldType(F, T)
          ...</k>
          <mem> Mem::Map </mem>
          requires isFlexibleArrayType(findFieldType(F, T))
               andBool notBool (Base in_keys(Mem))

     // Locks the type of the flexible array member to a fixed array.
     syntax EffectiveType ::= fixFlexibleType(EffectiveType, Int) [function]
     rule fixFlexibleType(dynamicType(T::Type), N::Int) => dynamicType(fixFlexibleType'(T, N))
          requires isFlexibleType(T)
     rule fixFlexibleType(t(...) #as T::Type, N::Int) => fixFlexibleType'(T, N)
          requires isFlexibleType(T)
     rule fixFlexibleType(T::EffectiveType, _) => T [owise]

     syntax Type ::= "fixFlexibleType'" "(" Type "," Int ")" [function]
     rule fixFlexibleType'(t(... st: structType(_)) #as T::Type, N::Int) => fixFlexibleStruct(T, findFieldNames(T), N -Int lastFieldByteOffset(T))
     rule fixFlexibleType'(t(... st: unionType(_)) #as T::Type, N::Int) => fixFlexibleUnion(T, getFieldNames(T), N)

     syntax Type ::= fixFlexibleStruct(Type, List, Int) [function]
     rule fixFlexibleStruct(T::Type, _ ListItem(F::CId), N::Int)
          => setFieldType(F, fixFlexibleArray'(findFieldType(F, T), N), resizeFlexibleType(T, F, N))
          requires isFlexibleArrayType(findFieldType(F, T))
     // GCC extension
     rule fixFlexibleStruct(T::Type, _ ListItem(F::CId), N::Int)
          => setFieldType(F, fixFlexibleType'(findFieldType(F, T), N), resizeFlexibleType(T, F, N))
          requires isFlexibleType(findFieldType(F, T))
     rule fixFlexibleStruct(T::Type, _, _) => T [owise]

     syntax Type ::= fixFlexibleUnion(Type, List, Int) [function]
     rule fixFlexibleUnion(T::Type, ListItem(F::CId) Decls::List, N::Int)
          => fixFlexibleUnion(setFieldType(F, fixFlexibleType'(getFieldType(F, T), N), resizeFlexibleType(T, F, N)), Decls, N)
          requires isFlexibleType(getFieldType(F, T))
     rule fixFlexibleUnion(T::Type, ListItem(F::CId) Decls::List, N::Int)
          => fixFlexibleUnion(T, Decls, N)
          requires notBool isFlexibleType(getFieldType(F, T))
     rule fixFlexibleUnion(T::Type, _, _) => T [owise]

     syntax Type ::= "fixFlexibleArray'" "(" Type "," Int ")" [function]
     rule fixFlexibleArray'(t(Qs::Quals, Mods::Set, flexibleArrayType(T'::Type)), N::Int)
          => t(Qs, Mods, arrayType(T', N /Int byteSizeofType(T')))
          requires (N /Int byteSizeofType(T')) >Int 0
     rule fixFlexibleArray'(t(Qs::Quals, Mods::Set, flexibleArrayType(T'::Type)), N::Int)
          => t(Qs, Mods, arrayType(T', 1))
          requires (N /Int byteSizeofType(T')) <=Int 0

     syntax EffectiveType ::= setVariantAtOffset(EffectiveType, CId, Int) [function]
     syntax Type ::= setVariantAtOffset(Type, CId, Int) [function]
     rule setVariantAtOffset(dynamicType(T::Type), F::CId, Offset::Int)
          => dynamicType(setVariantAtOffset(T, F, Offset))

     rule setVariantAtOffset(t(... st: _:SimpleArrayType) #as T::Type, F::CId, Offset::Int)
          => setElementType(Offset, setVariantAtOffset(getElementType(Offset, T), F, Offset %Int bitSizeofType(innerType(T))), T)
          requires bitSizeofType(innerType(T)) >Int 0

     rule setVariantAtOffset(t(... st: structType(_)) #as T::Type, F::CId, Offset::Int)
          => setFieldTypeAtOffset(Offset, setVariantAtOffset(getFieldTypeAtOffset(Offset, T), F, Offset -Int floorBitOffset(Offset, T)), T)
          requires Offset =/=Int 0
     rule setVariantAtOffset(t(... st: structType(_)) #as T::Type, F::CId, 0)
          => setFieldType(getUnnamed(F, T), setVariantAtOffset(getFieldType(getUnnamed(F, T), T), F, 0), T)
          requires isNoType(getFieldType(F, T))
               andBool notBool isNoType(findFieldType(F, T))
     rule setVariantAtOffset(t(... st: structType(_)) #as T::Type, F::CId, 0)
          => setFieldType(getFirstField(T), setVariantAtOffset(getFieldType(getFirstField(T), T), F, 0), T)
          requires isNoType(getFieldType(F, T))
               andBool isNoType(findFieldType(F, T))

     rule setVariantAtOffset(t(... st: unionType(_)) #as T::Type, F::CId, Offset::Int)
          => setActiveVariant(setVariantAtOffset(getActiveVariant(T), F, Offset), T)
          requires Offset =/=Int 0

     rule setVariantAtOffset(t(... st: unionType(_)) #as T::Type, F::CId, 0)
          => setActiveVariantId(F, T)
          requires notBool isNoType(getFieldType(F, T))
               andBool isNoType(getActiveVariant(T))

     rule setVariantAtOffset(t(... st: unionType(_)) #as T::Type, F::CId, 0)
          => #if notBool isNoType(findFieldType(F, getActiveVariant(T)))
               #then setActiveVariant(setVariantAtOffset(getActiveVariant(T), F, 0), T)
               #else setActiveVariantId(F, T) #fi
          requires (notBool isNoType(getFieldType(F, T)) orBool isNoType(findFieldType(F, T)))
               andBool notBool isNoType(getActiveVariant(T))

     rule setVariantAtOffset(t(... st: unionType(_)) #as T::Type, F::CId, 0)
          => setActiveVariant(setVariantAtOffset(getFieldType(getUnnamed(F, T), T), F, 0), setActiveVariantId(getUnnamed(F, T), T))
          requires isNoType(getFieldType(F, T))
               andBool notBool isNoType(findFieldType(F, T))

     rule setVariantAtOffset(T::Type, _, _) => T [owise]

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
     rule #effectivelyCompat(signedIntegerType #as L::Type, Eff::Type) => true
          requires type(correspondingUnsignedType(utype(L)))
                    ==Type stripQualifiers(Eff)
               andBool getQualifiers(Eff) <=Quals getQualifiers(L)
     rule #effectivelyCompat(unsignedIntegerType #as L::Type, Eff::Type) => true
          requires notBool isBoolType(L)
               andBool type(correspondingSignedType(utype(L)))
                    ==Type stripQualifiers(Eff)
               andBool getQualifiers(Eff) <=Quals getQualifiers(L)
     rule #effectivelyCompat(_, _) => false [owise]

     // - an aggregate or union type that includes one of the aforementioned
     // types among its members (including, recursively, a member of a
     // subaggregate or contained union), or
     rule effectivelyCompat(L::Type, ListItem(Eff::Type) _) => true
          requires #effectivelyCompat(L, Eff)
     rule effectivelyCompat(L::Type, (ListItem(Eff::Type) => .List) _)
          requires notBool #effectivelyCompat(L, Eff)
     // - a character type.
     rule effectivelyCompat(charType, _) => true
     rule effectivelyCompat(_, _) => false [owise]

     rule getTypesAtOffset(t(Qs::Quals, _, bitfieldType(InnerT::SimpleType, _)) #as T::Type, 0)
          => ListItem(T) ListItem(t(Qs, .Set, InnerT))
     // we have some redundancy here because we are trying to make matching as fast as possible,
     // so we avoid side conditions on these rules as much as we can.
     rule getTypesAtOffset(t(Qs::Quals, _, _:SimpleArrayType) #as T::Type, 0)
          => ListItem(T) getTypesAtOffset(addQualifiers(Qs, getElementType(0, T)), 0)
     rule getTypesAtOffset(t(Qs::Quals, _, structType(_)) #as T::Type, 0)
          => ListItem(T) getTypesAtOffset(addQualifiers(Qs, getFieldTypeAtOffset(0, T)), 0)
     rule getTypesAtOffset(t(Qs::Quals, _, unionType(_)) #as T::Type, 0)
          => ListItem(T) #if isNoType(getActiveVariant(T))
               #then .List
               #else getTypesAtOffset(addQualifiers(Qs, getActiveVariant(T)), 0) #fi

     rule getTypesAtOffset(t(Qs::Quals, _, arrayType(InnerT::Type, _)) #as T::Type, Offset::Int)
          => #if isCompleteType(InnerT) andBool bitSizeofType(InnerT) >Int 0
               #then getTypesAtOffset(addQualifiers(Qs, getElementType(Offset, T)), Offset %Int bitSizeofType(InnerT)) #else .List #fi
          requires Offset >Int 0 andBool Offset <Int bitSizeofType(T)
     rule getTypesAtOffset(t(Qs::Quals, _, variableLengthArrayType(InnerT::Type, _)) #as T::Type, Offset::Int)
          => #if isCompleteType(InnerT) andBool bitSizeofType(InnerT) >Int 0
               #then getTypesAtOffset(addQualifiers(Qs, getElementType(Offset, T)), Offset %Int bitSizeofType(InnerT)) #else .List #fi
          requires Offset >Int 0 andBool Offset <Int bitSizeofType(T)
     rule getTypesAtOffset(t(Qs::Quals, _, structType(_)) #as T::Type, Offset::Int)
          => getTypesAtOffset(addQualifiers(Qs, getFieldTypeAtOffset(Offset, T)), Offset -Int floorBitOffset(Offset, T))
          requires Offset >Int 0 andBool Offset <Int bitSizeofType(T)
     rule getTypesAtOffset(t(Qs::Quals, _, unionType(_)) #as T::Type, Offset::Int)
          => #if isNoType(getActiveVariant(T))
               #then .List
               #else getTypesAtOffset(addQualifiers(Qs, getActiveVariant(T)), Offset) #fi
          requires Offset >Int 0 andBool Offset <Int bitSizeofType(T)
     rule getTypesAtOffset(T::Type, Offset::Int)
          => getTypesAtOffset(T, Offset %Int bitSizeofType(T))
          requires bitSizeofType(T) >Int 0 andBool Offset >=Int bitSizeofType(T)
     rule getTypesAtOffset(T::Type, Offset::Int)
          => #if Offset ==Int 0 #then ListItem(T) #else .List #fi [owise]

     syntax List ::= addQualifiersToList(Quals, List) [function]
     rule addQualifiersToList(Qs::Quals, ListItem(T::Type) Ts::List)
          => ListItem(addQualifiers(Qs, T)) addQualifiersToList(Qs, Ts)
     rule addQualifiersToList(_, _) => .List [owise]

endmodule
