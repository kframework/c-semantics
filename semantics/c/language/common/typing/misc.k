module C-TYPING-MISC
     imports C-TYPING-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports FLOAT
     imports INT
     imports C-ALIGNMENT-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports COMPAT-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SORTS
     imports C-SYNTAX
     imports SYMLOC-SYNTAX

     //TODO(chathhorn): a lot of junk dumped here.
     rule simpleType(t(_, _, T::SimpleType)) => T

     rule correspondingUnsignedType(ut(S::Set, T:SimpleSignedType))
          => ut(S, flipSignedness(T))
          requires notBool isSimpleEnumType(T)
     rule correspondingUnsignedType(ut(S::Set, bitfieldType(_:SimpleSignedType, _) #as T::SimpleIntegerType))
          => ut(S, flipSignedness(T))
     rule correspondingUnsignedType(ut(S::Set, enumType(Tag::TagId)))
          => correspondingUnsignedType(ut(S, getEnumAlias(Tag)))
     rule correspondingUnsignedType(T::UType) => T [owise]

     rule correspondingSignedType(ut(S::Set, T:SimpleUnsignedType))
          => ut(S, flipSignedness(T))
          requires notBool isSimpleEnumType(T)
     rule correspondingSignedType(ut(S::Set, bitfieldType(_:SimpleUnsignedType, _) #as T::SimpleIntegerType))
          => ut(S, flipSignedness(T))
     rule correspondingSignedType(ut(S::Set, enumType(Tag::TagId)))
          => correspondingSignedType(ut(S, getEnumAlias(Tag)))
     rule correspondingSignedType(T::UType) => T [owise]

     syntax SimpleIntegerType ::= flipSignedness(SimpleIntegerType) [function]
     rule flipSignedness(bitfieldType(T::SimpleType, N::Int))
          => bitfieldType(flipSignedness({T}:>SimpleIntegerType), N)

     rule flipSignedness(_:SimpleUnsignedCharType) => signed-char
     rule flipSignedness(unsigned-short-int) => short-int
     rule flipSignedness(unsigned-int) => int
     rule flipSignedness(unsigned-long-int) => long-int
     rule flipSignedness(unsigned-long-long-int) => long-long-int
     rule flipSignedness(unsigned-oversized-int) => oversized-int

     rule flipSignedness(_:SimpleSignedCharType) => unsigned-char
     rule flipSignedness(short-int) => unsigned-short-int
     rule flipSignedness(int) => unsigned-int
     rule flipSignedness(signed-int) => unsigned-int
     rule flipSignedness(long-int) => unsigned-long-int
     rule flipSignedness(long-long-int) => unsigned-long-long-int
     rule flipSignedness(oversized-int) => unsigned-oversized-int

     rule flipSignedness(bool) => bool

     rule intInRange(V::Int, T::UType)
          => (V <=Int max(T)) andBool (V >=Int min(T))

     rule withinRange(V::Int, T::SimpleIntegerType)
          => (V <=Int imax(T)) andBool (V >=Int imin(T))

     rule floatInRange(V::Float, T::UType)
          => ((V <=Float fmax(T)) andBool (V >=Float fmin(T)))
               orBool isInfinite(V) orBool isNaN(V)

     rule fmin(ut(... st: _:SimpleFloatType) #as T::UType) => zeroCFloat(T) -Float maxValueFloat(typePrecision(T), typeExponent(T))
     rule fmax(ut(... st: _:SimpleFloatType) #as T::UType) => maxValueFloat(typePrecision(T), typeExponent(T))

     rule getParams(t(_, _, functionType(_, P::List))) => P
     rule getParams(T::Type) => .List
          requires notBool isFunctionType(T)

     rule setParams(t(Qs::Quals, Mods::Set, functionType(R::UType, _)), P::List)
          => t(Qs, Mods, functionType(R, P))

     rule getStorageSpecifiers(T::Type)
          => intersectSet(getModifiers(T), storageSpecifiers)

     rule getFunctionSpecifiers(T::Type)
          => getFunctionSpecifiers'(getModifiers(T))

     syntax Set ::= "getFunctionSpecifiers'" "(" Set ")" [function]
     rule getFunctionSpecifiers'((SetItem(S:KItem) => .Set) _)
          requires notBool isFunctionSpecifier(S)
     rule getFunctionSpecifiers'(S::Set) => S [owise]

     rule getSpecifiers(T::Type)
          => getStorageSpecifiers(T) getFunctionSpecifiers(T)

     rule getConstants(T::UType)
          => intersectSet(getModifiers(T), constantModifiers)

     // These are the only actual members "type qualifier" syntactic class.
     rule typeQualifiers =>
          SetItem(Const())
          SetItem(Restrict())
          SetItem(Volatile())
          SetItem(Atomic())

     rule storageSpecifiers =>
          SetItem(Static())
          SetItem(Extern())
          SetItem(Auto())
          SetItem(ThreadLocal())
          SetItem(Register())
          SetItem(Packed()) // Pseudo-storage specifier.
          // Also typedef, technically.

     syntax Set ::= "constantModifiers" [function]
     rule constantModifiers =>
          SetItem(IntegerConstant)

     rule stripStorageSpecifiers(t(Qs::Quals, Mods::Set, T::SimpleType))
          => t(Qs, Mods -Set storageSpecifiers, T)

     rule stripFunctionSpecifiers(t(Qs::Quals, Mods::Set, T::SimpleType))
          => t(Qs, stripFunctionSpecifiers'(Mods), T)

     syntax Set ::= "stripFunctionSpecifiers'" "(" Set ")" [function]
     rule stripFunctionSpecifiers'((SetItem(_:FunctionSpecifier) => .Set) _)
     rule stripFunctionSpecifiers'(S::Set) => S [owise]

     rule stripSpecifiers(T:UType) => utype(stripSpecifiers(type(T)))
     rule stripSpecifiers(T:Type) => stripStorageSpecifiers(stripFunctionSpecifiers(T))

     syntax UType ::= stripReadFrom(UType) [function]
     rule stripReadFrom(ut((SetItem(K:KItem) => .Set) _, _))
          requires readFrom(...) :=K K
     rule stripReadFrom(T::UType) => T [owise]

     rule stripConstants(ut(Mods::Set, T::SimpleUType)) => ut(Mods -Set constantModifiers, T)
     rule stripConstants(t(Qs::Quals, Mods::Set, T::SimpleType)) => t(Qs, Mods -Set constantModifiers, T)

     rule stripConstants(tv(V:CValue, T::UType)) => tv(V, stripConstants(T))
     rule stripConstants(V:RValue) => V [owise]

     rule addQualifier(Q:Qualifier, T:Type) => addQualifiers(noQuals +Qual Q, T)

     rule addStorage(S:StorageClassSpecifier, T:Type) => addModifier(S, T)

     rule addModifier(M:Modifier, T:UType) => utype(addModifier(M, type(T)))
     rule addModifiers(Mods::Set, T:UType) => utype(addModifiers(Mods, type(T)))

     rule addModifier(M:Modifier, T:Type) => addModifiers(SetItem(M), T)
     rule addModifiers(Mods'::Set, t(Qs::Quals, Mods::Set, T::SimpleType))
          => t(Qs, Mods' Mods, T)
     rule addModifiers(_, T::Type) => T [owise]

     rule idsFromParams(
               ListItem(typedDeclaration(t(_, _, T::SimpleType), X::CId)) L::List )
          => ListItem(X) idsFromParams(L)
          requires T =/=K void
     rule idsFromParams(ListItem(typedDeclaration(t(_, _, void), _))) => .List
     rule idsFromParams(ListItem(variadic)) => .List
     rule idsFromParams(.List) => .List

     rule tagRestrict(Tag::Scope, t(Qs::Quals, Mods::Set, T::SimpleType))
          => t(Qs, SetItem(RestrictBlock(Tag)) Mods, tagRestrict(Tag, T))
          requires Restrict() inQuals Qs
     rule tagRestrict(Tag::Scope, t(Qs::Quals, Mods::Set, T::SimpleType))
          => t(Qs, Mods, tagRestrict(Tag, T))
          requires notBool (Restrict() inQuals Qs)

     syntax SimpleType ::= tagRestrict(Scope, SimpleType)
          [function, klabel(tagRestrictSimpleType)]
     rule tagRestrict(Tag::Scope, arrayType(T::Type, N::Int))
          => arrayType(tagRestrict(Tag, T), N)
     rule tagRestrict(Tag::Scope, incompleteArrayType(T::Type))
          => incompleteArrayType(tagRestrict(Tag, T))
     rule tagRestrict(Tag::Scope, flexibleArrayType(T::Type))
          => flexibleArrayType(tagRestrict(Tag, T))
     rule tagRestrict(Tag::Scope, unspecifiedArrayType(T::Type))
          => unspecifiedArrayType(tagRestrict(Tag, T))
     rule tagRestrict(Tag::Scope, variableLengthArrayType(T::Type, K:K))
          => variableLengthArrayType(tagRestrict(Tag, T), K)
     rule tagRestrict(Tag::Scope, pointerType(T::Type))
          => pointerType(tagRestrict(Tag, T))
     rule tagRestrict(_, T:SimpleType) => T [owise]
     //TODO(chathhorn): structs/unions?

     rule hasRestrict(t(Qs::Quals, _, _)) => true
          requires Restrict() inQuals Qs
     rule hasRestrict(t(Qs::Quals, _, _:SimpleArrayType) #as T::Type)
          => hasRestrict(innerType(T))
          requires notBool (Restrict() inQuals Qs)
     rule hasRestrict(t(Qs::Quals, _, _:SimplePointerType) #as T::Type)
          => hasRestrict(innerType(T))
          requires notBool (Restrict() inQuals Qs)
     rule hasRestrict(_) => false [owise]
     //TODO(chathhorn): structs/unions?

     rule getRestrictBlock(t(_, Mods::Set, _)) => getRestrictBlock'(.K, Mods)

     // TODO(chathhorn): more map pattern ugliness.
     syntax Scope ::= "getRestrictBlock'" "(" K "," Set ")" [function]
     rule getRestrictBlock'(RestrictBlock(Tag:Scope), _) => Tag
     rule getRestrictBlock'(_, S:Set) => getRestrictBlock''(S) [owise]

     syntax Scope ::= "getRestrictBlock''" "(" Set ")" [function]
     rule getRestrictBlock''(SetItem(K:KItem) S:Set) => getRestrictBlock'(K, S)
     rule getRestrictBlock''(.Set) => none

     rule getReadFromLoc(T::UType) => #getReadFromLoc(getModifiers(T))

     syntax SymLoc ::= #getReadFromLoc(Set) [function]
     rule #getReadFromLoc(SetItem(readFrom(Loc:SymLoc, _)) _) => Loc
     rule #getReadFromLoc(_) => NullPointer [owise]

     syntax Int ::= #getReadFromLen(Set) [function]
     rule getReadFromLen(T::UType) => #getReadFromLen(getModifiers(T))

     rule #getReadFromLen(SetItem(readFrom(_, Len:Int)) _) => Len
     rule #getReadFromLen(_) => 0 [owise]

     rule updateReadFrom(T::UType, Loc::SymLoc)
          => updateReadFrom(T, Loc, byteSizeofType(T))
     rule updateReadFrom(T::UType, Loc::SymLoc, Len::Int)
          => addModifier(readFrom(stripProv(Loc), Len), stripReadFrom(T))

     rule arrayLength(t(_, _, arrayType(_, N:Int))) => N

     rule getFieldNames(structOrUnionType #as T::Type) => getFieldNames'(getFields(T))
     rule getFieldNames(_) => .List [owise]

     rule findFieldNames(structOrUnionType #as T::Type) => getFieldNames'(getFlatFields(T))
     rule findFieldNames(_) => .List [owise]

     rule findUnnamedBitfields(structOrUnionType #as T::Type) => getUnnamedBitfields'(getFlatFields(T))
     rule findUnnamedBitfields(_) => .List [owise]

     rule getFieldTypes(T::Type) => getFieldTypes'(getFields(T))

     syntax List ::= "getUnnamedBitfields'" "(" FieldInfo ")" [function]
     rule getUnnamedBitfields'(fieldInfo(ListItem(typedDeclaration(_, F:NoName)) Decls::List, Sz::Int, Types::Map (F |-> t(... st: bitfieldType(...)) #as T::Type), Offsets::Map, Padding::Set))
          => ListItem(F) getUnnamedBitfields'(fieldInfo(Decls, Sz, Types, Offsets, Padding))
     rule getUnnamedBitfields'(fieldInfo(ListItem(typedDeclaration(_, F::CId)) Decls::List, Sz::Int, Types::Map, Offsets::Map, Padding::Set))
          => getUnnamedBitfields'(fieldInfo(Decls, Sz, Types, Offsets, Padding)) [owise]
     rule getUnnamedBitfields'(fieldInfo(.List, _, _, _, _)) => .List

     syntax List ::= "getFieldTypes'" "(" FieldInfo ")" [function]
     rule getFieldTypes'(fieldInfo(ListItem(typedDeclaration(_, F::CId)) Decls::List, Sz::Int, Types::Map (F |-> T::Type), Offsets::Map, Padding::Set))
          => ListItem(T) getFieldTypes'(fieldInfo(Decls, Sz, Types, Offsets, Padding))
     rule getFieldTypes'(_) => .List [owise]

     syntax List ::= "getFieldNames'" "(" FieldInfo ")" [function]
     rule getFieldNames'(fieldInfo(ListItem(typedDeclaration(_, F::CId)) Fields::List, Sz::Int, Types::Map, Offsets::Map, Padding::Set))
          => ListItem(F) getFieldNames'(fieldInfo(Fields, Sz, Types, Offsets, Padding))
     rule getFieldNames'(_) => .List [owise]

     rule getFieldOffset(F::CId, T::Type) => getFieldOffset'(F, getFields(T))

     rule findFieldOffset(F::CId, T::Type) => getFieldOffset'(F, getFlatFields(T))

     syntax Int ::= "getFieldOffset'" "(" CId "," FieldInfo ")" [function]
     rule getFieldOffset'(F::CId, fieldInfo(_, _, _, F |-> Offset::Int _, _)) => Offset

     rule getFieldType(F::CId, T::Type) => getFieldType'(F, getFields(T))

     rule findFieldType(F::CId, structOrUnionType #as T::Type) => getFieldType'(F, getFlatFields(T))
     rule findFieldType(_, _) => type(no-type) [owise]

     syntax Type ::= "getFieldType'" "(" CId "," FieldInfo ")" [function]
     rule getFieldType'(F::CId, fieldInfo(_, _, F |-> T::Type _, _, _)) => T
     rule getFieldType'(_, _) => type(no-type) [owise]

     syntax Modifier ::= activeVariant(CId)
     rule getActiveVariant(t(_, SetItem(activeVariant(F::CId)) _, _) #as T::Type)
          => getFieldType(F, T)
     rule getActiveVariant(_) => type(no-type) [owise]

     rule getActiveVariantId(t(_, SetItem(activeVariant(F'::CId)) _, _)) => F'

     rule setActiveVariantId(F::CId, T::Type)
          => addModifier(activeVariant(F), clearActiveVariant(T))

     rule setActiveVariant(A::Type, t(_, SetItem(activeVariant(F'::CId)) _, _) #as T::Type)
          => setFieldType(F', A, T)
     rule setActiveVariant(_, T::Type) => T [owise]

     rule mergeVariants(t(_, SetItem(activeVariant(F::CId)) _, unionType(_)) #as T::Type, T'::Type)
          => mergeUnionVariants(F, T, T')
     rule mergeVariants(t(_, SetItem(elementTypes(ETs::Map)) _, _:SimpleArrayType), T'::Type)
          => mergeArrayVariants(ETs, T')
     rule mergeVariants(t(... st: structType(...)) #as T::Type, t(... st: structType(...)) #as T'::Type)
          => mergeStructVariants(T, T', getFieldNames(T'))
     rule mergeVariants(_, T'::EffectiveType) => T' [owise]

     syntax EffectiveType ::= mergeUnionVariants(CId, Type, Type) [function]
     rule mergeUnionVariants(F::CId, T::Type,
               t(_, SetItem(activeVariant(F)) _, unionType(_)) #as T'::Type)
          => setFieldType(F, {mergeVariants(getFieldType(F, T), getFieldType(F, T'))}:>Type, T')
     rule mergeUnionVariants(_, _, T'::Type) => T' [owise]

     syntax EffectiveType ::= mergeArrayVariants(Map, Type) [function]
     rule mergeArrayVariants(ETs::Map, t(_, SetItem(elementTypes(ETs'::Map)) _, _:SimpleArrayType) #as T'::Type)
          => setElementTypes(mergeElementVariants(ETs, ETs'), T')
     rule mergeArrayVariants(_, T'::Type) => T' [owise]

     syntax Map ::= mergeElementVariants(Map, Map) [function]
     rule mergeElementVariants((N:Int |-> T::Type) ETs::Map, ETs'::Map)
          => mergeElementVariants(ETs, ETs'[N <- mergeVariants(T, {ETs'[N]}:>EffectiveType)])
          requires N in_keys(ETs')
     rule mergeElementVariants((N:Int |-> T::Type) ETs::Map, ETs'::Map)
          => mergeElementVariants(ETs, (N |-> T) ETs')
          requires notBool (N in_keys(ETs'))
     rule mergeElementVariants(.Map, ETs'::Map) => ETs'

     syntax Type ::= mergeStructVariants(Type, Type, List) [function]
     rule mergeStructVariants(T::Type, T'::Type, ListItem(F::CId) Fs'::List)
          => mergeStructVariants(T, setFieldType(F, {mergeVariants(getFieldType(F, T), getFieldType(F, T'))}:>Type, T'), Fs')
     rule mergeStructVariants(_, T'::Type, .List) => T'

     rule clearActiveVariant(t(_, _::Set (SetItem(activeVariant(_)) => .Set), unionType(_)))
     rule clearActiveVariant(T::Type) => T
          requires notBool isUnionType(T)
     rule clearActiveVariant(t(... st: unionType(_)) #as T::Type)
          => setFields(clearActiveVariant'(getFieldNames(T), getFields(T)), T) [owise]

     syntax FieldInfo ::= "clearActiveVariant'" "(" List "," FieldInfo ")" [function]
     rule clearActiveVariant'(ListItem(F::CId) Decls::List, Fields::FieldInfo)
          => clearActiveVariant'(Decls, setFieldType'(F, clearActiveVariant(getFieldType'(F, Fields)), Fields))
     rule clearActiveVariant'(_, Fields::FieldInfo) => Fields [owise]

     syntax CId ::= "getFieldAtOffset'" "(" Int "," FieldInfo ")" [function]
     rule getFieldAtOffset'(Offset::Int, fieldInfo(_::List (ListItem(typedDeclaration(_, F::CId)) => .List), _, _, _::Map (F |-> FOffset::Int => .Map), _))
          requires FOffset >Int Offset
     rule getFieldAtOffset'(_, fieldInfo(_ ListItem(typedDeclaration(_, F::CId)), _, _, _, _)) => F [owise]

     syntax CId ::= "getFieldFollowingOffset'" "(" Int "," FieldInfo ")" [function]
     rule getFieldFollowingOffset'(Offset::Int, fieldInfo((ListItem(typedDeclaration(_, F::CId)) => .List) _, _, _, _::Map (F |-> FOffset::Int => .Map), _))
          requires FOffset <=Int Offset
     rule getFieldFollowingOffset'(_, fieldInfo(.List, _, _, _, _)) => #NoName
     rule getFieldFollowingOffset'(_, fieldInfo(ListItem(typedDeclaration(_, F::CId)) _, _, _, _, _)) => F [owise]

     rule floorBitOffset(Offset::Int, structOrUnionType #as T::Type)
          => floorFieldOffset'(Offset, getFields(T))
          requires Offset >=Int 0
     rule floorBitOffset(Offset::Int, t(... st: _:SimpleArrayType) #as T::Type)
          => (Offset /Int bitSizeofType(innerType(T))) *Int bitSizeofType(innerType(T))
          requires Offset >=Int 0 andBool bitSizeofType(innerType(T)) >Int 0

     rule ceilBitOffset(Offset::Int, structOrUnionType #as T::Type)
          => ceilFieldOffset'(Offset, getFields(T))
          requires Offset >=Int 0
     rule ceilBitOffset(Offset::Int, t(... st: _:SimpleArrayType) #as T::Type)
          => (Offset /Int bitSizeofType(innerType(T)) +Int 1) *Int bitSizeofType(innerType(T))
          requires Offset >=Int 0 andBool bitSizeofType(innerType(T)) >Int 0

     rule lastFieldByteOffset(T::Type)
          => getFieldOffset({(reverseList(getFieldNames(T)))[0]}:>CId, T) /Int cfg:bitsPerByte

     syntax Int ::= "floorFieldOffset'" "(" Int "," FieldInfo ")" [function]
     rule floorFieldOffset'(Offset::Int, fieldInfo(.List, _, _, _, _)) => Offset
     rule floorFieldOffset'(Offset::Int, Fields::FieldInfo)
          => getFieldOffset'(getFieldAtOffset'(Offset, Fields), Fields) [owise]

     syntax Int ::= "ceilFieldOffset'" "(" Int "," FieldInfo ")" [function]
     rule ceilFieldOffset'(Offset::Int, fieldInfo(.List, _, _, _, _)) => Offset
     rule ceilFieldOffset'(Offset::Int, fieldInfo(Decls::List, Sz::Int, _, _, _) #as Fields::FieldInfo) => Sz
          requires (Decls =/=K .List) andBool getFieldFollowingOffset'(Offset, Fields) ==K #NoName
     rule ceilFieldOffset'(Offset::Int, Fields::FieldInfo)
          => getFieldOffset'(getFieldFollowingOffset'(Offset, Fields), Fields) [owise]

     rule getFieldTypeAtOffset(Offset::Int, T::Type)
          => getFieldTypeAtOffset'(Offset, getFields(T))

     syntax Type ::= "getFieldTypeAtOffset'" "(" Int "," FieldInfo ")" [function]
     rule getFieldTypeAtOffset'(Offset::Int, fieldInfo(.List, _, _, _, _)) => type(no-type)
     rule getFieldTypeAtOffset'(Offset::Int, Fields::FieldInfo)
          => getFieldType'(getFieldAtOffset'(Offset, Fields), Fields) [owise]

     rule getFieldAtOffset(Offset::Int, T::Type)
          => getFieldAtOffset'(Offset, getFields(T))

     rule resizeFlexibleType(T::Type, F::CId, N::Int)
          => setFieldsSize((N *Int cfg:bitsPerByte) +Int getFieldOffset(F, T), clearPaddingAfter(F, T))

     syntax Type ::= setFieldsSize(Int, Type) [function]
     rule setFieldsSize(Sz::Int, T::Type)
          => setFields(setFieldsSize'(Sz, getFields(T)), T)

     syntax FieldInfo ::= "setFieldsSize'" "(" Int "," FieldInfo ")" [function]
     rule setFieldsSize'(Sz::Int, fieldInfo(Decls::List, _, Types::Map, Offsets::Map, Padding::Set))
          => fieldInfo(Decls, Sz, Types, Offsets, Padding)

     syntax Type ::= clearPaddingAfter(CId, Type) [function]
     rule clearPaddingAfter(F::CId, T::Type)
          => setFields(clearPaddingAfter'(getFieldOffset(F, T), getFields(T)), T)

     syntax FieldInfo ::= "clearPaddingAfter'" "(" Int "," FieldInfo ")" [function]
     rule clearPaddingAfter'(Offset::Int, fieldInfo(_, _, _, _, (SetItem(N::Int) => .Set) _::Set))
          requires N >=Int Offset
     rule clearPaddingAfter'(_, Fields::FieldInfo) => Fields [owise]

     rule getUnnamed(F::CId, T::Type)
          => getFieldAtOffset'(findFieldOffset(F, T), getFields(T))
          requires notBool isNoType(findFieldType(F, T))

     rule getFirstField(T::Type) => getFieldAtOffset'(0, getFields(T))

     rule getFlatFields(T::Type) => toFlatFieldInfo(getFields(T))

     syntax FieldInfo ::= toFlatFieldInfo(TagInfo) [function]
     rule toFlatFieldInfo(Fields:FieldInfo) => flattenFieldInfo(.K, .K, Fields, fieldInfo(.List, 0, .Map, .Map, .Set))
     rule toFlatFieldInfo(_) => fieldInfo(.List, 0, .Map, .Map, .Set) [owise]

     syntax FieldInfo ::= flattenFieldInfo(K, K, FieldInfo, FieldInfo) [function]
     rule flattenFieldInfo(.K => getFlatFields(T), .K => Offset,
               fieldInfo((ListItem(typedDeclaration(structOrUnionType #as T::Type, F:NoName)) => .List) _, _, _, (F |-> Offset::Int) _, _),
               _)
     rule flattenFieldInfo(.K, .K,
               fieldInfo((ListItem(typedDeclaration(T::Type, F::CId)) => .List) _,
                    _, (F |-> T'::Type) _, (F |-> Offset::Int) _, _),
               fieldInfo(
                    _::List (.List => ListItem(typedDeclaration(T, F))),
                    _,
                    _::Map (.Map => F |-> T'),
                    _::Map (.Map => F |-> Offset),
                    _)) [owise]
     rule flattenFieldInfo(fieldInfo(Fields::List, _, Types::Map, Offsets::Map, Padding::Set) => .K, Offset:Int => .K,
               _,
               fieldInfo(
                    _::List (.List => Fields),
                    _,
                    _::Map (.Map => Types),
                    _::Map (.Map => addOffset(Offset, Offsets)),
                    _::Set (.Set => addPaddingOffset(Offset, Padding))))
     rule flattenFieldInfo(.K, .K, fieldInfo(.List, Sz::Int, _, _, Padding::Set),
               fieldInfo(Decls::List, _, Types::Map, Offsets::Map, Padding'::Set))
          => fieldInfo(Decls, Sz, Types, Offsets, Padding Padding')

     syntax Map ::= addOffset(Int, Map) [function]
     rule addOffset(Offset::Int, (K:KItem |-> N:Int) M::Map)
          => K |-> (N +Int Offset) addOffset(Offset, M)
     rule addOffset(_, _) => .Map [owise]

     syntax Set ::= addPaddingOffset(Int, Set) [function]
     rule addPaddingOffset(Offset::Int, SetItem(N::Int) S::Set)
          => SetItem(N +Int Offset) addPaddingOffset(Offset, S)
     rule addPaddingOffset(_, _) => .Set [owise]

     rule setFieldType(F::CId, T'::Type, T::Type)
          => setFields(setFieldType'(F, T', getFields(T)), T)

     syntax FieldInfo ::= "setFieldType'" "(" CId "," Type "," FieldInfo ")" [function]
     rule setFieldType'(F::CId, T::Type, fieldInfo(Decls::List, Sz::Int, Types::Map, Offsets::Map, Padding::Set))
          => fieldInfo(Decls, Sz, Types[F <- T], Offsets, Padding)

     syntax Type ::= setFields(FieldInfo, Type) [function]
     rule setFields(_, t(_, (SetItem(fieldInfo(_, _, _, _, _)) => .Set) _::Set, structType(_)))
     rule setFields(_, t(_, (SetItem(fieldInfo(_, _, _, _, _)) => .Set) _::Set, unionType(_)))
     rule setFields(Fields::FieldInfo, T::Type) => addModifier(Fields, T) [owise]

     rule setFieldTypeAtOffset(Offset::Int, T'::Type, T::Type)
          => setFields(setFieldType'(getFieldAtOffset'(Offset, getFields(T)), T', getFields(T)), T)

     syntax Modifier ::= elementTypes(Map)
     rule setElementType(Offset::Int, T::Type, A::Type)
          => setElementTypes((getElementTypes(A))[floorBitOffset(Offset, A) <- T], A)
          requires T =/=K innerType(A)
     rule setElementType(_, _, A::Type) => A [owise]

     rule getElementType(Offset::Int, A::Type)
          => {(getElementTypes(A))[floorBitOffset(Offset, A)] orDefault innerType(A)}:>Type

     syntax Map ::= getElementTypes(Type) [function]
     rule getElementTypes(t(_, SetItem(elementTypes(ETs::Map)) _, _)) => ETs
     rule getElementTypes(_) => .Map [owise]

     syntax Type ::= setElementTypes(Map, Type) [function]
     rule setElementTypes(ETs::Map, t(Qs::Quals, SetItem(elementTypes(_)) Mods::Set, T::SimpleArrayType))
          => t(Qs, SetItem(elementTypes(ETs)) Mods, T)
     rule setElementTypes(ETs::Map, T::Type) => addModifier(elementTypes(ETs), T)
          [owise]

     // TODO(chathhorn): move/refactor?
     rule <k> (.K => stabilize(T)) ~> stabilizeVLA(T::Type) ...</k>
          <curr-scope> S::Scope </curr-scope>
          requires isVariablyModifiedType(T) andBool S =/=K fileScope
          [structural]
     rule <k> stabilize(T::Type) ~> stabilizeVLA(_) => T ...</k>
          <curr-scope> S::Scope </curr-scope>
          requires notBool isVariablyModifiedType(T) andBool S =/=K fileScope
          [structural]
     rule <k> stabilizeVLA(T::Type) => T ...</k>
          <curr-scope> S::Scope </curr-scope>
          requires notBool isVariablyModifiedType(T) andBool S =/=K fileScope
          [structural]

     // Although GCC seems to allow it, I don't think structs/unions are
     // allowed to have VM types (see 6.7.2.1p9).
     syntax KItem ::= stabilize(K)

     context stabilize(t(_, _, variableLengthArrayType(_, (HOLE:KItem => reval(HOLE)))))
          [result(RValue)]

     rule (.K => stabilize(T)) ~> stabilize(t(_, _, arrayType(T::Type, _)))
          requires isVariablyModifiedType(T)
          [structural]
     rule stabilize(T:Type) ~> stabilize(t(Qs::Quals, Mods::Set, arrayType(_, N::Int)))
          => stabilize(t(Qs, Mods, arrayType(T, N)))
          requires notBool isVariablyModifiedType(T)
          [structural]
     rule (.K => stabilize(T)) ~> stabilize(t(_, _, pointerType(T:Type)))
          requires isVariablyModifiedType(T)
          [structural]
     rule stabilize(T:Type) ~> stabilize(t(Qs::Quals, Mods::Set, pointerType(_)))
          => stabilize(t(Qs, Mods, pointerType(T)))
          requires notBool isVariablyModifiedType(T)
          [structural]

     rule stabilize(t(Qs::Quals, Mods::Set, variableLengthArrayType(T::Type, tv(N:Int, _)))
          => t(Qs, Mods, arrayType(T, N)))
          requires N >Int 0
          [structural]
     rule (.K => UNDEF("CTM1", "Variable-length array with length that evaluates to non-positive value at execution."))
          ~> stabilize(t(_, _, variableLengthArrayType(_, tv(N:Int, _))))
          requires N <=Int 0
          [structural]

     rule toPrototype(t(Qs::Quals, Mods::Set, functionType(R::UType, ListItem(typedDeclaration(P::Type, _)) Ps::List)))
          => t(Qs, Mods, functionType(R, .List))
          requires oldStyle in Mods
               andBool notBool isVoidType(P)
     rule toPrototype(t(Qs::Quals, Mods::Set, functionType(R::UType, ListItem(P:Type) Ps::List)))
          => t(Qs, Mods, functionType(R, .List))
          requires oldStyle in Mods
               andBool notBool isVoidType(P)
     rule toPrototype(T::Type) => T [owise]

     // Round up to the nearest multiple of the second arg * cfg:bitsPerByte.
     syntax Int ::= roundBits(Int, Int) [function]
     rule roundBits(N::Int, A::Int) => N
          requires (N %Int (A *Int cfg:bitsPerByte)) ==Int 0
     rule roundBits(N::Int, A::Int)
          => N +Int ((A *Int cfg:bitsPerByte) -Int (N %Int (A *Int cfg:bitsPerByte))) [owise]

     rule allComplete(ListItem(V:KItem) _) => false
          requires notBool isCompleteType(type(V))
     rule allComplete(.List) => true
     rule allComplete((ListItem(_) => .List) _) [owise]

     rule makeUnionFieldInfo(Pack::Bool, Fs::List)
          => makeUnionFieldInfo'(Pack, Fs, .Map, .Map, .List)

     syntax FieldInfo ::= "makeUnionFieldInfo'" "(" Bool "," List "," Map ","  Map "," List ")" [function]
     rule makeUnionFieldInfo'(Pack::Bool,
               ListItem(typedDeclaration(T::Type, Field::CId)) L::List,
               Types::Map,
               Offsets::Map,
               NL::List)
          => makeUnionFieldInfo'(Pack, L,
               Types[Field <- T], Offsets[Field <- 0],
               NL ListItem(typedDeclaration(T, Field)))
     rule makeUnionFieldInfo'(true, .List, Types::Map, Offsets::Map, NL::List)
          => fieldInfo(NL, maxByteSizeofList(NL) *Int cfg:bitsPerByte, Types, Offsets, .Set)
     rule makeUnionFieldInfo'(false, .List, Types::Map, Offsets::Map, NL::List)
          => fieldInfo(NL,
               roundBits(maxByteSizeofList(NL) *Int cfg:bitsPerByte, maxByteAlignofDecls(NL)),
               Types, Offsets, getPaddingOffsets(maxByteSizeofList(NL) *Int cfg:bitsPerByte, roundBits(maxByteSizeofList(NL) *Int cfg:bitsPerByte, maxByteAlignofDecls(NL))))

     syntax Set ::= computePaddingOffsets(List, Int, Map, Map) [function]
     rule computePaddingOffsets(ListItem(typedDeclaration(_, A::CId)) ListItem(typedDeclaration(BT::Type, B::CId)) L::List, Len::Int, Types::Map, Offsets::Map)
          => getPaddingOffsets({{Offsets[A]}<:KItem}:>Int +Int bitSizeofType({{Types[A]}<:KItem}:>Type), {{Offsets[B]}<:KItem}:>Int)
               computePaddingOffsets(ListItem(typedDeclaration(BT, B)) L, Len, Types, Offsets)
     rule computePaddingOffsets(ListItem(typedDeclaration(_, A::CId)), Len::Int, Types::Map, Offsets::Map)
          => getPaddingOffsets({{Offsets[A]}<:KItem}:>Int +Int bitSizeofType({{Types[A]}<:KItem}:>Type), Len)
     rule computePaddingOffsets(.List, _, _, _) => .Set

     syntax Set ::= getPaddingOffsets(Int, Int) [function]
     rule getPaddingOffsets(Off::Int, BOff::Int)
          => getPaddingOffsets(Off +Int (cfg:bitsPerByte -Int (Off %Int cfg:bitsPerByte)), BOff)
          requires Off <Int BOff andBool (Off %Int cfg:bitsPerByte) =/=K 0
     rule getPaddingOffsets(Off::Int, BOff::Int) => .Set
          requires Off >=Int BOff
     rule getPaddingOffsets(Off::Int, BOff::Int)
          => SetItem(Off) getPaddingOffsets(Off +Int cfg:bitsPerByte, BOff)
          [owise]

     syntax Bool ::= isNonPaddingOffset(Int, List, Map, Map) [function]
     rule isNonPaddingOffset(Offset:Int, ListItem(typedDeclaration(_, F:CId)) Decls:List, Types:Map, Offsets:Map)
          => ({{Offsets[F]}<:KItem}:>Int <=Int Offset andBool Offset <Int {{Offsets[F]}<:KItem}:>Int +Int
               bitSizeofType({{Types[F]}<:KItem}:>Type))
          orBool isNonPaddingOffset(Offset, Decls, Types, Offsets)
     rule isNonPaddingOffset(_, .List, _, _) => false

     rule rvalType(t(... st: _:SimpleArrayType) #as T::Type)
          => utype(arrayToPtrType(T))
     rule rvalType(t(... st: functionType(...)) #as T::Type)
          => utype(pointerType(T))
     rule rvalType(T::Type) => utype(T) [owise]

endmodule
