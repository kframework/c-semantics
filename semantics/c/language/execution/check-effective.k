module C-CHECK-EFFECTIVE
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
     imports C-TYPING-COMMON-SYNTAX
     imports C-TYPING-EFFECTIVE-SYNTAX
     imports C-TYPING-SYNTAX

     // The lvalue SymLoc carries with it a last-access object type which, in a
     // sense, is a composite type formed from the current effective type plus
     // the type of compatible lvalue expressions based on it (which may only
     // refer to a part of the object). By composite type, we just mean the
     // effective type with extra annotations for tracking locked union
     // variants. When a write occurs through a SymLoc, its attached
     // last-access type becomes the effective type of the object.

     rule checkEffectiveType(L::Type, Offset::Int, LAT:Type)
          => effTypeUB(L, LAT) ~> effectiveTypeViolation(L, Offset, LAT)
          requires notBool effectivelyCompat(L, getTypesAtOffset(LAT, Offset))
     rule checkEffectiveType(L::Type, Offset::Int, dynamicType(LAT::Type))
          => effTypeUB(L, LAT) ~> effectiveTypeViolation(L, Offset, dynamicType(LAT))
          requires notBool (effectivelyCompat(L, getTypesAtOffset(LAT, Offset))
               orBool effectivelyCompat(LAT, getTypesAtOffset(L, Offset))
               orBool isNoType(LAT))
     rule checkEffectiveType(_, _, _) => .K [owise]

     syntax KItem ::= effectiveTypeViolation(Type, Int, EffectiveType)
     syntax KItem ::= effTypeUB(Type, Type) [function]
     rule effTypeUB(L::Type, Eff::Type)
          => UNDEF("EIO10", "Type of lvalue (" +String showType(L) +String ") not compatible with the effective type of the object being accessed (" +String showType(Eff) +String ").")
          requires L =/=Type Eff
     rule effTypeUB(L::Type, _)
          => UNDEF("EIO10", "Type of lvalue (" +String showType(L) +String ") not compatible with the effective type of the object being accessed.")
          [owise]

     rule Eff:EffectiveType
          ~> adjustPointerBounds(tv(Loc::SymLoc, ut(_, pointerType(T'::Type)) #as T::UType))
          => adjustPointerBounds'(Loc, T, T', Eff)
     rule <k> (.K => getEffectiveType(base(Loc)))
               ~> adjustPointerBounds(tv(Loc::SymLoc, ut(_, pointerType(T'::Type)) #as T::UType))
          ...</k>
          <mem> Mem::Map </mem>
          requires base(Loc) in_keys(Mem)
     rule <k> adjustPointerBounds(tv(Loc::SymLoc, T::UType)) => tv(Loc, T) ...</k>
          <mem> Mem::Map </mem>
          requires notBool (base(Loc) in_keys(Mem))

     syntax RValue ::= "adjustPointerBounds'" "(" SymLoc "," UType "," Type "," EffectiveType ")" [function]
     rule adjustPointerBounds'(Loc::SymLoc, T::UType, T'::Type, t(...) #as Eff::Type)
          => tv(adjustBounds(Loc, T'), T)
          requires notBool isCharType(T') andBool effectivelyCompat(T', getTypesAtOffset(Eff, bitOffset(Loc)))
     rule adjustPointerBounds'(Loc::SymLoc, T::UType, T'::Type, dynamicType(Eff::Type))
          => tv(adjustBounds(Loc, T'), T)
          requires notBool isCharType(T') andBool (effectivelyCompat(T', getTypesAtOffset(Eff, bitOffset(Loc)))
               orBool effectivelyCompat(Eff, getTypesAtOffset(T', offset(Loc))))
     rule adjustPointerBounds'(Loc::SymLoc, T::UType, _, _)
          => tv(Loc, T)
          [owise]

     syntax SymLoc ::= adjustBounds(SymLoc, Type) [function]
     rule adjustBounds(loc(_, _, SetItem(fromArray(_, N::Int, _)) _) #as Loc::SymLoc, T::Type)
          => addProv(fromArray(0, byteSizeofType(T), T), stripFromArray(Loc))
          requires byteSizeofType(T) >Int N
     // TODO(chathhorn): only allow adjusting the size up for now (because we
     // need to be able to distinguish a pointer into an array of T from a
     // pointer to a T not in an array here).
     rule adjustBounds(Loc::SymLoc, _) => Loc [owise]

endmodule
