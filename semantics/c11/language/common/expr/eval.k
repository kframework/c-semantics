module C-COMMON-EXPR-EVAL-SYNTAX
     imports BASIC-K
     imports C-TYPING-SORTS
     imports SYMLOC-SORTS

     syntax KItem ::= instantiate(SymLoc, Type)
     syntax KItem ::= checkUse(K) [strict]
     syntax KItem ::= checkLoc(SymLoc)
     syntax UType ::= arrayToPtrType(Type) [function]

endmodule

module C-COMMON-EXPR-EVAL
     imports C-COMMON-EXPR-EVAL-SYNTAX
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

     syntax KItem ::= "reval" "(" ")"
     rule reval(HOLE:K) => HOLE ~> reval() [heat]
     rule HOLE:KItem ~> reval() => reval(HOLE) [cool, ndlocal]

     // If the lvalue designates an object of automatic storage duration that
     // could have been declared with the register storage class (never had its
     // address taken), and that object is uninitialized (not declared with an
     // initializer and no assignment to it has been performed prior to use),
     // the behavior is undefined.

     /*@ \fromStandard{\source[n1570]{\para{6.3.2.1}{2}}}{
     Except when it is the operand of the \cinline{sizeof} operator, the
     \cinline{_Alignof} operator, the unary \cinline{&} operator, the
     \cinline{++} operator, the \cinline{--} operator, or the left operand of
     the \cinline{.} operator or an assignment operator, an lvalue that does
     not have an array type is converted to the value stored in the designated
     object (and is no longer an lvalue); this is called lvalue conversion.  If
     the lvalue has qualified type, the value has the unqualified version of
     the type of the lvalue; additionally, if the lvalue has atomic type, the
     value has the non-atomic version of the type of the lvalue; otherwise, the
     value has the type of the lvalue. \ldots
     }*/

     syntax KItem ::= checkCompleteLValue(Type)
     rule checkCompleteLValue(T::Type) => .K
          requires isCompleteType(T)
     rule (.K => UNDEF("CEE5", "Trying to convert an incomplete lvalue not of array type.", "6.3.2.1:2, J.2:1 item 20"))
          ~> checkCompleteLValue(T::Type)
          requires notBool isCompleteType(T)

     // Lvalue conversion.
     rule reval(nclv(Loc::SymLoc, T::Type)
          => checkCompleteLValue(T)
          ~> checkUse(instantiate(Loc, T)))
          requires notBool isArrayOrFunctionType(T)
          [structural]

     rule lv(Loc::SymLoc, T::Type)
          => checkEffectiveType(Loc, T)
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.3.2.1}{3}}}{
     Except when it is the operand of the \cinline{sizeof} operator, the
     \cinline{_Alignof} operator, or the unary \cinline{&} operator, or is a
     string literal used to initialize an array, an expression that has type
     ``array of type'' is converted to an expression with type ``pointer to
     type'' that points to the initial element of the array object and is not
     an lvalue. If the array object has register storage class, the behavior is
     undefined.
     }*/

     rule reval(nclv(Loc::SymLoc, T:ArrayType)
          => checkRegister(Loc)
          ~> checkUse(tv(arrayToPtrLoc(Loc, T), arrayToPtrType(T))))
          [structural]

     rule arrayToPtrType(T::Type)
          => ut(getModifiers(T), pointerType(innerType(T)))

     syntax SymLoc ::= arrayToPtrLoc(SymLoc, Type) [function]
     rule arrayToPtrLoc(Loc::SymLoc, T:FixedLengthArrayType)
          => addProv(basedOn(base(Loc), getRestrictBlock(T)),
             addProv(fromArray(0, byteSizeofType(innerType(T)) *Int arrayLength(T)), Loc))
          requires isRestrictType(T)
     rule arrayToPtrLoc(Loc::SymLoc, T::Type)
          => addProv(basedOn(base(Loc), getRestrictBlock(T)), Loc)
          requires isRestrictType(T) andBool notBool isFixedLengthArrayType(T)
     rule arrayToPtrLoc(Loc::SymLoc, T:FixedLengthArrayType)
          => addProv(fromArray(0, byteSizeofType(innerType(T)) *Int arrayLength(T)), Loc)
          requires notBool isRestrictType(T)
     rule arrayToPtrLoc(Loc::SymLoc, _) => Loc [owise]

     /*@ \fromStandard{\source[n1570]{\para{6.3.2.1}{4}}}{
     A function designator is an expression that has function type. Except
     when it is the operand of the \cinline{sizeof} operator, the
     \cinline{_Alignof} operator, or the unary \cinline{&} operator, a function
     designator with type ``function returning T'' is converted to an
     expression that has type ``pointer to a function returning T''.
     }*/

     rule reval(nclv(Loc::SymLoc, T:FunctionType)
               => checkUse(tv(Loc, utype(pointerType(T)))))
          [structural]

     rule reval(trap(T::UType)
               => UNDEF("CEE2", "Indeterminate value used in an expression.",
                    "6.2.4, 6.7.9, 6.8, J.2:1 item 11")
               ~> tv(trap, T))
          [structural]

     syntax KItem ::= checkRegister(SymLoc)
     rule <k> checkRegister(_) => .K ...</k>
          <initializing> true </initializing>
          [structural]
     rule <k> checkRegister(Loc:SymLoc) => .K ...</k>
          <initializing> false </initializing>
          requires notBool isRegisterLoc(Loc)
          [structural]
     rule <k> (.K => UNDEF("CEE1",
                    "Address of an array declared with register storage class used in an expression.",
                    "6.3.2.1:3, J.2:1 item 22"))
              ~> checkRegister(Loc:SymLoc)
          ...</k>
          <initializing> false </initializing>
          requires isRegisterLoc(Loc)
          [structural]

     rule checkUse(V:KResult) => V
          requires getKLabel(V) =/=K #klabel(`tv`)
          [structural]
     rule checkUse(tv(V::CValue, T::UType)) => tv(V, T)
          requires isSymLoc(V) =/=K true andBool isTrap(V) =/=K true
          [structural]
     rule checkUse(tv(trap, T::UType)) => trap(T)
          [structural]
     rule checkUse(tv(V:SymLoc, T::UType)) => checkLoc(V) ~> tv(V, T)
          [structural]

     rule checkLoc(Loc::SymLoc) => checkLoc'(stripProv(Loc))
          [structural]

     syntax KItem ::= "checkLoc'" "(" SymLoc ")"
     rule checkLoc'(NullPointer) => .K
          [structural]
     rule <k> checkLoc'(Loc::SymLoc) => .K ...</k>
          <mem> Mem::Map </mem>
          requires (isStaticDuration(Loc) orBool isNativeLoc(Loc))
               andBool notBool (base(Loc) in_keys(Mem))
          [structural]
     rule <k> checkLoc'(loc(Base::SymBase, Offset::Int))
               => checkOffsets(Offset, Len)
          ...</k>
          <mem>... Base |-> object(_, Len::Int, _) ...</mem>
          [structural]
     rule <k> checkLoc'(loc(Base::SymBase, Offset::Int)) => errorLocInvalid ...</k>
          <mem> Mem::Map </mem>
          requires notBool (Base in_keys(Mem))
               andBool notBool isStaticDuration(loc(Base, Offset))
               andBool notBool isNativeLoc(loc(Base, Offset))
          [structural]

     syntax KItem ::= checkOffsets(Int, Int) [function]
     rule checkOffsets(Offset::Int, Len::Int) => .K
          requires (Offset <=Int Len) andBool (Offset >=Int 0)
     rule checkOffsets(_, _) => errorLocBounds [owise]

     syntax Error ::= "errorLocBounds"
     syntax KItem ::= "errorLocInvalid"
     rule (.K => UNDEF("CEE4",
               "Referring to an object outside of its lifetime.",
               "6.2.4:2, J.2:1 item 9"))
          ~> errorLocInvalid
          [structural]
     rule (.K => UNDEF("CEE3",
               "Found pointer that refers outside the bounds of an object + 1.",
               "6.3.2.1:1, J.2:1 item 19"))
          ~> errorLocBounds
          [structural]

     syntax KItem ::= checkEffectiveType(SymLoc, Type)
     rule <k> checkEffectiveType(Loc::SymLoc, T::Type)
              => checkEffectiveType'(Loc, T,
                   offset(Loc) *Int cfg:bitsPerByte +Int getBitOffset(Loc),
                   base(Loc), getLastAccessType(Loc))
          ...</k>
          requires notBool isLinkerLoc(Loc)
               andBool Loc =/=K NullPointer
          [structural]
     rule <k> checkEffectiveType(loc(Base::SymBase => Base', _, _), _) ...</k>
          <linkings>... Base |-> Base'::SymBase ...</linkings>
          [structural]
     rule <k> checkEffectiveType(loc(Base::SymBase => Base', _), _) ...</k>
          <linkings>... Base |-> Base'::SymBase ...</linkings>
          [structural]
     rule <k> checkEffectiveType(Loc::SymLoc, T::Type) => nclv(Loc, T) ...</k>
          <linkings> Linkings:Map </linkings>
          requires isLinkerLoc(Loc) andBool notBool base(Loc) in_keys(Linkings)
          [structural]
     rule checkEffectiveType(NullPointer, T::Type) => nclv(NullPointer, T)
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
     rule checkEffectiveType'(Loc::SymLoc, L::Type, _, _, _) => nclv(Loc, L)
          requires isNoType(L)
          [structural]
     rule checkEffectiveType'(Loc::SymLoc, L::Type, Offset::Int, Base::SymBase, LAT:Type)
          // If compatible, the new last access type becomes a composite of the
          // current last-access object type and the type of the current lvalue
          // expression.
          => nclv(setLastAccessType(Loc, newLastAccessType(LAT, L, Offset)), L)
          requires notBool isNoType(L) andBool notBool isNoType(LAT)
               // An lvalue is compatible if it's compatible with at least one
               // of the types at the given offset into the object.
               andBool effectivelyCompat(L, getTypesAtOffset(LAT, Offset))
          [structural]
     rule checkEffectiveType'(Loc::SymLoc, L::Type, Offset::Int, Base::SymBase, LAT:Type)
          => checkEffectiveType''(Loc, L, Offset, Base, getEffectiveType(Base))
          requires notBool isNoType(L)
               andBool (notBool effectivelyCompat(L, getTypesAtOffset(LAT, Offset)) orBool isNoType(LAT))
          [structural]

     // If the lvalue isn't compatible with the last access type, then we try
     // the current effective type.
     syntax KItem ::= "checkEffectiveType''" "(" SymLoc "," Type "," Int "," SymBase "," K ")" [strict(5)]
     rule checkEffectiveType''(Loc::SymLoc, L::Type, Offset::Int, Base::SymBase, Eff:Type)
          => nclv(setLastAccessType(Loc, newLastAccessType(Eff, L, Offset)), L)
          requires effectivelyCompat(L, getTypesAtOffset(Eff, Offset))
               orBool isNoType(Eff)
          [structural]
     rule (.K => UNDEF("EIO10", "Type of lvalue not compatible with the effective type of the object being accessed.", "6.5:7, J.2:1 item 37"))
          ~> checkEffectiveType''(_, L::Type, Offset::Int, _, Eff:Type)
          requires notBool effectivelyCompat(L, getTypesAtOffset(Eff, Offset))
               andBool notBool isNoType(Eff)
          [structural]

     syntax Type ::= newLastAccessType(Type, Type, Int) [function]
     rule newLastAccessType(Eff::Type, L::Type, _) => Eff
          requires isCharType(L)
     rule newLastAccessType(Eff::Type, L::Type, Offset::Int) => L
          requires notBool isCharType(L) andBool isNoType(tracePath(Eff, L, Offset))
     rule newLastAccessType(Eff::Type, L::Type, Offset::Int) => tracePath(Eff, L, Offset) [owise]

     // We form a composite type by locating the lvalue type in the (larger)
     // object type and tracing the path (i.e., union variants) that gets us
     // there. We lock unions to a particular variant when we pick a variant
     // and unlock them when the path ends in a union type (as opposed to the
     // type of a paricular variant).
     syntax Type ::= tracePath(Type, Type, Int) [function]
     rule tracePath(T::Type, L::Type, 0) => unlock(0, T)
          requires #effectivelyCompat(L, T)
     rule tracePath(t(Qs::Quals, Mods::Set, bitfieldType(T'::BitfieldFieldType, N::Int)), L::Type, Offset::Int)
          => t(Qs, Mods, bitfieldType(T', N))
          requires notBool #effectivelyCompat(L, t(Qs, Mods, bitfieldType(T', N)))
               andBool #effectivelyCompat(L, addQualifiers(Qs, type(T')))

     // In the case of aggregates, the type might be the type of the aggregate
     // or its first element if the offset is 0.
     rule tracePath(T:ArrayType, L::Type, Offset::Int)
          => addModifier(lock(0, tracePath(innerType(T), L, Offset %Int bitSizeofType(innerType(T)))), unlock(0, T))
          requires notBool #effectivelyCompat(L, T)
               andBool bitSizeofType(innerType(T)) >Int 0
               andBool notBool isNoType(tracePath(innerType(T), L, Offset %Int bitSizeofType(innerType(T))))

     rule tracePath(T:StructType, L::Type, Offset::Int)
          => tracePathInStructOrUnion(T, L, Offset)
          requires notBool #effectivelyCompat(L, T)
     rule tracePath(T:UnionType, L::Type, Offset::Int)
          => tracePathInStructOrUnion(T, L, Offset)
          requires notBool #effectivelyCompat(L, T)

     rule tracePath(_, _, _) => type(no-type) [owise]

     syntax Type ::= tracePathInStructOrUnion(StructOrUnionType, Type, Int) [function]
     rule tracePathInStructOrUnion(T:StructType, L::Type, Offset::Int)
          => tracePathInStruct(getFieldInfo(T), T, L, Offset)
     rule tracePathInStructOrUnion(T:UnionType, L::Type, Offset::Int)
          => tracePathInUnion(getFieldInfo(T), T, L, Offset)

     syntax Type ::= tracePathInStruct(FieldInfo, StructType, Type, Int) [function]
     rule tracePathInStruct(fieldInfo(
                    Ds':List ListItem(typedDeclaration(_, FId::CId)),
                    N::Int,
                    Ts:Map,
                    Offs:Map FId |-> FOffset::Int,
                    PaddingOffs:Set
               ), T::StructType, L::Type, Offset::Int)
          => tracePathInStruct(fieldInfo(Ds', N, Ts, Offs FId |-> FOffset, PaddingOffs), T, L, Offset)
          requires FOffset >Int Offset
     rule tracePathInStruct(fieldInfo(
                    _:List ListItem(typedDeclaration(_, FId::CId)),
                    _,
                    _:Map FId |-> T'::Type,
                    _:Map FId |-> FOffset::Int,
                    _
               ), T::StructType, L::Type, Offset::Int)
          => addModifier(lock(FOffset, tracePath(T', L, Offset -Int FOffset)), unlock(FOffset, T))
          requires FOffset <=Int Offset
               andBool notBool isNoType(tracePath(T', L, Offset -Int FOffset))
     rule tracePathInStruct(_, _, _, _) => type(no-type) [owise]

     // In the case of unions, we make the first compatible variant active (via
     // the "lock" modifier) and continue from the type of the variant.
     syntax Type ::= tracePathInUnion(FieldInfo, UnionType, Type, Int) [function]
     rule tracePathInUnion(fieldInfo(
                    ListItem(typedDeclaration(_, FId::CId)) _:List,
                    _,
                    _:Map FId |-> T'::Type,
                    _, _
               ), T::UnionType, L::Type, Offset::Int)
          => addModifier(lock(0, tracePath(T', L, Offset)), unlock(0, T))
          requires notBool isNoType(tracePath(T', L, Offset))
     rule tracePathInUnion(fieldInfo(
                    ListItem(typedDeclaration(_, FId::CId)) Ds':List,
                    N::Int,
                    Ts:Map FId |-> T'::Type,
                    Offs::Map,
                    PaddingOffs::Set
               ), T::UnionType, L::Type, Offset::Int)
          => tracePathInUnion(fieldInfo(Ds', N, Ts, Offs, PaddingOffs), T, L, Offset)
          requires isNoType(tracePath(T', L, Offset))
     rule tracePathInUnion(_, _, _, _) => type(no-type) [owise]

     syntax Bool ::= effectivelyCompat(Type, List) [function]
     rule effectivelyCompat(_:CharType, _) => true
     rule effectivelyCompat(L::Type, ListItem(Eff:Type) _) => true
          requires #effectivelyCompat(L, Eff)
     rule effectivelyCompat(L::Type, (ListItem(Eff:Type) => .List) _)
          requires notBool #effectivelyCompat(L, Eff)
     rule effectivelyCompat(_, _) => false [owise]

     // An  object shall have its stored value accessed only by an lvalue
     // expression that has one of the following types:
     syntax Bool ::= #effectivelyCompat(Type, Type) [function]
     // - a type compatible with the effective type of the object,
     // - a qualified version of a type compatible with the effective type of
     // the object,
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
     // - an aggregate or union type that includes one of the aforementioned
     // types among its members (including, recursively, a member of a
     // subaggregate or contained union), or

     // (We're assuming the standard is talking about subobjects at this point,
     // which we handle by considering the set of subobject types at a
     // particular offset.)

     // - a character type.
     rule #effectivelyCompat(_:CharType, _) => true

     rule #effectivelyCompat(_, _) => false [owise]

     syntax KItem ::= getEffectiveType(SymBase)
     rule <k> getEffectiveType(Base::SymBase) => T ...</k>
          <mem>... Base |-> object(T::Type, _, _) ...</mem>
          [structural]
     rule <k> getEffectiveType(Base::SymBase) => type(no-type) ...</k>
          <mem> Mem:Map </mem>
          requires notBool Base in_keys(Mem)
          [structural]

     syntax SymLoc ::= setLastAccessType(SymLoc, Type) [function]
     rule setLastAccessType(Loc::SymLoc, T::Type)
          => addProv(objectType(T), stripLastAccessType(Loc))

     syntax Type ::= getLastAccessType(SymLoc) [function]
     rule getLastAccessType(loc(_, _, _:Set SetItem(objectType(T::Type)))) => T
     rule getLastAccessType(_) => type(no-type) [owise]

endmodule
