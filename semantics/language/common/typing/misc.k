module C-TYPING-MISC
     imports C-TYPING-SYNTAX

     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX

     imports C-ERROR-SYNTAX
     imports K-REFLECTION
     imports C-CONFIGURATION

     //TODO(chathhorn): a lot of junk dumped here.

     rule simpleType(t(_, _, T::SimpleType)) => T

     rule char => cfg:charAlias

     rule correspondingUnsignedType(ut(S::Set, T:SimpleSignedType))
          => ut(S, flipSignedness(T))
          requires notBool isSimpleEnumType(T)
     rule correspondingUnsignedType(ut(S::Set, enumType(_)))
          => correspondingUnsignedType(ut(S, cfg:enumAlias))
     rule correspondingUnsignedType(T::UType) => T [owise]

     rule correspondingSignedType(ut(S::Set, T:SimpleUnsignedType))
          => ut(S, flipSignedness(T))
          requires notBool isSimpleEnumType(T)
     rule correspondingSignedType(ut(S::Set, enumType(_)))
          => correspondingSignedType(ut(S, cfg:enumAlias))
     rule correspondingSignedType(T::UType) => T [owise]

     syntax SimpleIntegerType ::= flipSignedness(SimpleIntegerType) [function]
     rule flipSignedness(bitfieldType(T::BitfieldFieldType, N::Int))
          => bitfieldType(flipSignedness(T:>SimpleIntegerType):>BitfieldFieldType, N)

     rule flipSignedness(unsigned-char) => signed-char
     rule flipSignedness(unsigned-short-int) => short-int
     rule flipSignedness(unsigned-int) => int
     rule flipSignedness(unsigned-long-int) => long-int
     rule flipSignedness(unsigned-long-long-int) => long-long-int

     rule flipSignedness(signed-char) => unsigned-char
     rule flipSignedness(short-int) => unsigned-short-int
     rule flipSignedness(int) => unsigned-int
     rule flipSignedness(long-int) => unsigned-long-int
     rule flipSignedness(long-long-int) => unsigned-long-long-int

     rule min(ut(_, bitfieldType(_:SignedBitfieldFieldType, N::Int)))
          => 0 -Int (1 <<Int absInt(N -Int 1))
     rule max(ut(_, bitfieldType(_:SignedBitfieldFieldType, N::Int)))
          => (1 <<Int absInt(N -Int 1)) -Int 1

     rule min(ut(_, signed-char))
          => 0 -Int (1 <<Int absInt(bitSizeofType(type(signed-char)) -Int 1))
     rule max(ut(_, signed-char))
          => (1 <<Int absInt(bitSizeofType(type(signed-char)) -Int 1)) -Int 1
     rule min(ut(_, short-int))
          => 0 -Int (1 <<Int absInt(bitSizeofType(type(short-int)) -Int 1))
     rule max(ut(_, short-int))
          => (1 <<Int absInt(bitSizeofType(type(short-int)) -Int 1)) -Int 1
     rule min(ut(_, int))
          => 0 -Int (1 <<Int absInt(bitSizeofType(type(int)) -Int 1))
     rule max(ut(_, int))
          => (1 <<Int absInt(bitSizeofType(type(int)) -Int 1)) -Int 1
     rule min(ut(_, long-int))
          => 0 -Int (1 <<Int absInt(bitSizeofType(type(long-int)) -Int 1))
     rule max(ut(_, long-int))
          => (1 <<Int absInt(bitSizeofType(type(long-int)) -Int 1)) -Int 1
     rule min(ut(_, long-long-int))
          => 0 -Int (1 <<Int absInt(bitSizeofType(type(long-long-int)) -Int 1))
     rule max(ut(_, long-long-int))
          => (1 <<Int absInt(bitSizeofType(type(long-long-int)) -Int 1)) -Int 1

     rule min(_:UnsignedIntegerUType) => 0

     rule max(ut(_, bool)) => 1

     rule max(ut(_, bitfieldType(_:UnsignedBitfieldFieldType, N::Int)))
          => (1 <<Int absInt(N)) -Int 1

     rule max(ut(_, unsigned-char))
          => (1 <<Int absInt(bitSizeofType(type(unsigned-char)))) -Int 1
     rule max(ut(_, unsigned-short-int))
          => (1 <<Int absInt(bitSizeofType(type(unsigned-short-int)))) -Int 1
     rule max(ut(_, unsigned-int))
          => (1 <<Int absInt(bitSizeofType(type(unsigned-int)))) -Int 1
     rule max(ut(_, unsigned-long-int))
          => (1 <<Int absInt(bitSizeofType(type(unsigned-long-int)))) -Int 1
     rule max(ut(_, unsigned-long-long-int))
          => (1 <<Int absInt(bitSizeofType(type(unsigned-long-long-int)))) -Int 1

     rule min(ut(_, enumType(_) => cfg:enumAlias))
     rule max(ut(_, enumType(_) => cfg:enumAlias))

     rule inRange(V:Int, T:IntegerUType)
          => (V <=Int max(T)) andBool (V >=Int min(T))
     rule inRange(V:Float, T:FloatUType)
          => ((V <=Float fmax(T)) andBool (V >=Float fmin(T)))
          orBool isInfinite(V) orBool isNaN(V)

     rule fmin(ut(_, float)) => 0.0f -Float maxValueFloat(24, 8)
     rule fmax(ut(_, float)) => maxValueFloat(24, 8)

     rule fmin(ut(_, double)) => 0.0 -Float maxValueFloat(53, 11)
     rule fmax(ut(_, double)) => maxValueFloat(53, 11)

     rule fmin(ut(_, long-double)) => Int2Float(0, 64, 15) -Float maxValueFloat(64, 15)
     rule fmax(ut(_, long-double)) => maxValueFloat(64, 15)

     rule getParams(t(_, _, functionType(_, P::List))) => P
     rule getParams(T::Type) => .List
          requires notBool isFunctionType(T)

     rule setParams(t(Qs::Quals, Mods::Set, functionType(R::UType, _)), P::List)
          => t(Qs, Mods, functionType(R, P))

     rule noQuals => quals(.Set)

     rule Q::Qualifier inQuals quals(Qs::Set) => Q in Qs

     rule quals(Qs::Set) +Qual Q::Qualifier => quals(Qs SetItem(Q))

     rule quals(SetItem(Q) Qs::Set) -Qual Q::Qualifier => quals(Qs)
     rule Qs::Quals -Qual _ => Qs [owise]

     rule quals(Qs::Set) <=Quals quals(Qs'::Set) => Qs <=Set Qs'

     rule quals(Qs::Set) +Quals quals(Qs'::Set) => quals(Qs Qs')

     rule toQuals(SetItem(Q:Qualifier) S::Set) => toQuals(S) +Qual Q
     rule toQuals(SetItem(K::K) S::Set) => toQuals(S)
          requires notBool isQualifier(K)
     rule toQuals(.Set) => noQuals

     rule getModifiers(ut(S::Set, _)) => S
     rule getModifiers(t(_, S::Set, _)) => S

     rule getQualifiers(t(Qs::Quals, _, T:SimpleArrayType))
          => Qs +Quals getQualifiers(innerType(type(T)))
     rule getQualifiers(t(Qs::Quals, _, _)) => Qs [owise]

     rule getStorageSpecifiers(T::Type)
          => intersectSet(getModifiers(T), storageSpecifiers)

     rule getFunctionSpecifiers(T::Type)
          => intersectSet(getModifiers(T), functionSpecifiers)

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
          // Also typedef, technically.

     rule functionSpecifiers =>
          SetItem(Noreturn())
          SetItem(Inline())

     syntax Set ::= "constantModifiers" [function]
     rule constantModifiers =>
          SetItem(IntegerConstant)

     rule stripQualifiers(T::Type) => type(utype(T))

     rule stripStorageSpecifiers(t(Qs::Quals, Mods::Set, T::SimpleType))
          => t(Qs, Mods -Set storageSpecifiers, T)

     rule stripFunctionSpecifiers(t(Qs::Quals, Mods::Set, T::SimpleType))
          => t(Qs, Mods -Set functionSpecifiers, T)

     rule stripSpecifiers(T:UType) => utype(stripSpecifiers(type(T)))
     rule stripSpecifiers(T:Type) => stripStorageSpecifiers(stripFunctionSpecifiers(T))

     syntax UType ::= stripReadFrom(UType) [function]
     rule stripReadFrom(ut(Mods::Set, T::SimpleUType))
          => ut(filterSet(Mods, #klabel(`isNotReadFrom`)), T)

     syntax Bool ::= isNotReadFrom(Modifier) [function]
     rule isNotReadFrom(readFrom(_, _)) => false
     rule isNotReadFrom(_) => true [owise]

     rule stripConstants(ut(Mods::Set, T::SimpleUType)) => ut(Mods -Set constantModifiers, T)
     rule stripConstants(t(Qs::Quals, Mods::Set, T::SimpleType)) => t(Qs, Mods -Set constantModifiers, T)

     rule stripConstants(tv(V:CValue, T::UType)) => tv(V, stripConstants(T))
     rule stripConstants(V:RValue) => V [owise]

     rule addQualifier(Q:Qualifier, T:Type) => addQualifiers(noQuals +Qual Q, T)

     rule addQualifiers(Qs'::Quals, t(Qs::Quals, Mods::Set, arrayType(T::Type, N:Int)))
          => t(Qs +Quals Qs', Mods, arrayType(addQualifiers(Qs', T), N))
     rule addQualifiers(Qs'::Quals, t(Qs::Quals, Mods::Set, incompleteArrayType(T:Type)))
          => t(Qs +Quals Qs', Mods, incompleteArrayType(addQualifiers(Qs', T)))
     rule addQualifiers(Qs'::Quals, t(Qs::Quals, Mods::Set, flexibleArrayType(T:Type)))
          => t(Qs +Quals Qs', Mods, flexibleArrayType(addQualifiers(Qs', T)))
     rule addQualifiers(Qs'::Quals, t(Qs::Quals, Mods::Set, unspecifiedArrayType(T:Type)))
          => t(Qs +Quals Qs', Mods, unspecifiedArrayType(addQualifiers(Qs', T)))
     rule addQualifiers(Qs'::Quals, t(Qs::Quals, Mods::Set, variableLengthArrayType(T:Type, N:K)))
          => t(Qs +Quals Qs', Mods, variableLengthArrayType(addQualifiers(Qs', T), N))
     rule addQualifiers(Qs'::Quals, t(Qs::Quals, Mods::Set, T::SimpleType))
          => t(Qs +Quals Qs', Mods, T)
          [owise]

     rule addStorage(S:Storage, T:Type) => addModifier(S, T)

     rule addModifier(M:Modifier, T:UType) => utype(addModifier(M, type(T)))
     rule addModifiers(Mods::Set, T:UType) => utype(addModifiers(Mods, type(T)))

     rule addModifier(M:Modifier, T:Type) => addModifiers(SetItem(M), T)
     rule addModifiers(Mods'::Set, t(Qs::Quals, Mods::Set, T::SimpleType))
          => t(Qs, Mods' Mods, T)
     rule addModifiers(_, T::Type) => T [owise]

     rule innerType(T:UType) => innerType(type(T))

     rule innerType(t(_, _, arrayType(T::Type, _))) => T
     rule innerType(t(_, _, incompleteArrayType(T::Type))) => T
     rule innerType(t(_, _, flexibleArrayType(T::Type))) => T
     rule innerType(t(_, _, unspecifiedArrayType(T::Type))) => T
     rule innerType(t(_, _, variableLengthArrayType(T::Type, _))) => T
     rule innerType(t(_, _, pointerType(T::Type))) => T
     rule innerType(t(_, _, functionType(T::UType, _))) => type(T)

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
     rule tagRestrict(_, T::SimpleType) => T [owise]
     //TODO(chathhorn): structs/unions?

     rule getRestrictBlock(t(_, Mods::Set, _)) => getRestrictBlock'(.K, Mods)

     // TODO(chathhorn): more map pattern ugliness.
     syntax Scope ::= "getRestrictBlock'" "(" K "," Set ")" [function]
     rule getRestrictBlock'(RestrictBlock(Tag:Scope), _) => Tag
     rule getRestrictBlock'(_, S:Set) => getRestrictBlock''(S) [owise]

     syntax Scope ::= "getRestrictBlock''" "(" Set ")" [function]
     rule getRestrictBlock''(SetItem(K:K) S:Set) => getRestrictBlock'(K, S)
     rule getRestrictBlock''(.Set) => none

     syntax Modifier ::= getReadFrom(UType) [function]
     rule getReadFrom(ut(Mods::Set, _::SimpleUType)) => getReadFrom'(.K, Mods)

     syntax Modifier ::= "getReadFrom'" "(" K "," Set ")" [function]
     rule getReadFrom'(readFrom(Loc:SymLoc, Len:Int), _) => readFrom(Loc, Len)
     rule getReadFrom'(_, S:Set) => getReadFrom''(S) [owise]

     syntax Modifier ::= "getReadFrom''" "(" Set ")" [function]
     rule getReadFrom''(SetItem(K:K) S:Set) => getReadFrom'(K, S)
     rule getReadFrom''(.Set) => noModifier

     rule getReadFromLoc(T::UType) => #getReadFromLoc(getReadFrom(T))

     syntax SymLoc ::= #getReadFromLoc(Modifier) [function]
     rule #getReadFromLoc(readFrom(Loc:SymLoc, _)) => Loc
     rule #getReadFromLoc(_) => NullPointer [owise]

     syntax Int ::= #getReadFromLen(Modifier) [function]
     rule getReadFromLen(T::UType) => #getReadFromLen(getReadFrom(T))

     rule #getReadFromLen(readFrom(_, Len:Int)) => Len
     rule #getReadFromLen(_) => 0 [owise]

     rule updateReadFrom(T::UType, Loc::SymLoc)
          => updateReadFrom(T, Loc, byteSizeofType(T))
     rule updateReadFrom(T::UType, Loc::SymLoc, Len::Int)
          => addModifier(readFrom(stripProv(Loc), Len), stripReadFrom(T))

     rule arrayLength(t(_, _, arrayType(_, N:Int))) => N

     rule getFieldInfo(S:StructId) => #getFieldInfo(S, #configuration)
     rule getFieldInfo(t(_, Mods::Set, structType(S::StructId))) => getFieldInfo(S)
     rule getFieldInfo(t(_, Mods::Set, unionType(S::StructId))) => getFieldInfo(S)

     syntax FieldInfo ::= #getFieldInfo(StructId, K) [function]
     rule #getFieldInfo(tag(X::CId, Tu::String, B::BlockRef), <generatedTop>... <global>... <structs> M::Map </structs> ...</global> ...</generatedTop>)
          => extractFieldInfo(M[Tu]:>Map[tag(X, Tu, B)])
     syntax FieldInfo ::= extractFieldInfo(K) [function]
     rule extractFieldInfo(fieldInfo(L::List, I::Int, M1::Map, M2::Map, S::Set)) => fieldInfo(L, I, M1, M2, S)
     rule extractFieldInfo(_) => #incomplete [owise]

     rule getTag(tag(S:CId, _, _)) => S

     rule getTypesAtOffset(T::Type, 0) => ListItem(T)
          requires notBool isAggregateOrUnionType(T) andBool notBool isBitfieldType(T)
     rule getTypesAtOffset(t(Qs::Quals, Mods::Set, bitfieldType(T::BitfieldFieldType, N::Int)), 0)
          => ListItem(t(Qs, Mods, bitfieldType(T, N))) ListItem(addQualifiers(Qs, type(T)))
     rule getTypesAtOffset(T:ArrayType, 0)
          => ListItem(T) getTypesAtOffset(addQualifiers(getQualifiers(T), innerType(T)), 0)
          requires isNoType(getLock(0, T))
     rule getTypesAtOffset(T:StructType, 0)
          => ListItem(T) getTypesAtOffsetInStruct(T, getFieldInfo(T), 0)
          requires isCompleteType(T) andBool isNoType(getLock(0, T))
     rule getTypesAtOffset(T:UnionType, 0)
          => ListItem(T) getTypesAtOffsetInUnion(T, getFieldInfo(T), 0)
          requires isCompleteType(T) andBool isNoType(getLock(0, T))
     rule getTypesAtOffset(T::Type, 0)
          => ListItem(T) getTypesAtOffset(addQualifiers(getQualifiers(T), getLock(0, T)), 0)
          requires notBool isNoType(getLock(0, T))

     rule getTypesAtOffset(T:ArrayType, Offset::Int)
          => getTypesAtOffset(addQualifiers(getQualifiers(T), innerType(T)),
               Offset %Int bitSizeofType(innerType(T)))
          requires Offset >Int 0 andBool isCompleteType(innerType(T))
               andBool bitSizeofType(innerType(T)) >Int 0
               andBool isNoType(getLock(0, T))
     rule getTypesAtOffset(T:ArrayType, Offset::Int)
          => getTypesAtOffset(addQualifiers(getQualifiers(T), getLock(0, T)),
               Offset %Int bitSizeofType(innerType(T)))
          requires Offset >Int 0 andBool notBool isNoType(getLock(0, T))
     rule getTypesAtOffset(T:StructType, Offset::Int)
          => getTypesAtOffsetInStruct(T, getFieldInfo(T), Offset)
          requires Offset >Int 0 andBool isCompleteType(T)
     rule getTypesAtOffset(T:UnionType, Offset::Int)
          => getTypesAtOffsetInUnion(T, getFieldInfo(T), Offset)
          requires Offset >Int 0 andBool isCompleteType(T)
               andBool isNoType(getLock(0, T))
     rule getTypesAtOffset(T:UnionType, Offset::Int)
          => getTypesAtOffset(addQualifiers(getQualifiers(T), getLock(0, T)), Offset)
          requires Offset >Int 0 andBool isCompleteType(T)
               andBool notBool isNoType(getLock(0, T))

     rule getTypesAtOffset(_, _) => .List [owise]

     syntax List ::= getTypesAtOffsetInStruct(Type, FieldInfo, Int) [function]
     rule getTypesAtOffsetInStruct(T::Type, fieldInfo(
               Ds:List ListItem(typedDeclaration(_, FId::CId)),
               N::Int,
               Ts:Map,
               Offs:Map FId |-> FOffset::Int,
               PaddingOffs:Set
          ), Offset::Int)
          => getTypesAtOffsetInStruct(T, fieldInfo(Ds, N, Ts, Offs, PaddingOffs), Offset)
          requires FOffset >Int Offset
     rule getTypesAtOffsetInStruct(T::Type, fieldInfo(
               _ ListItem(typedDeclaration(T'::Type, FId::CId)),
               _,
               _,
               _ FId |-> FOffset::Int,
               _
          ), Offset::Int)
          => getTypesAtOffset(addQualifiers(getQualifiers(T), T'), Offset -Int FOffset)
          requires FOffset <=Int Offset
               andBool isNoType(getLock(FOffset, T))
     rule getTypesAtOffsetInStruct(T::Type, fieldInfo(
               _ ListItem(typedDeclaration(_, FId::CId)),
               _,
               _,
               _ FId |-> FOffset::Int,
               _
          ), Offset::Int)
          => getTypesAtOffset(addQualifiers(getQualifiers(T), getLock(FOffset, T)), Offset -Int FOffset)
          requires FOffset <=Int Offset
               andBool notBool isNoType(getLock(FOffset, T))
     rule getTypesAtOffsetInStruct(_, _, _) => .List [owise]

     syntax List ::= getTypesAtOffsetInUnion(Type, FieldInfo, Int) [function]
     rule getTypesAtOffsetInUnion(T::Type, fieldInfo(
               ListItem(typedDeclaration(T'::Type, FId::CId)) Ds:List,
               N::Int,
               Ts:Map,
               Offs:Map,
               PaddingOffs:Set
          ), Offset::Int)
          => getTypesAtOffset(addQualifiers(getQualifiers(T), T'), Offset)
               getTypesAtOffsetInUnion(T, fieldInfo(Ds, N, Ts, Offs, PaddingOffs), Offset)
     rule getTypesAtOffsetInUnion(_, _, _) => .List [owise]

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
     rule (.K => UNDEF("CTM1", "Variable-length array with length that evaluates to non-positive value at execution.",
                       "6.7.6.2:5, J.2:1 item 75"))
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

     rule unlock(Offset::Int, t(Qs::Quals, Mods::Set SetItem(lock(Offset, _)), T::SimpleType))
          => unlock(Offset, t(Qs, Mods, T))
     rule unlock(_, T::Type) => T [owise]

     rule unlockAll(t(Qs::Quals, Mods::Set SetItem(lock(_, _)), T::SimpleType))
          => unlockAll(t(Qs, Mods, T))
     rule unlockAll(T::Type) => T [owise]

     syntax Type ::= getLock(Int, Type) [function]
     rule getLock(Offset::Int, t(_, _:Set SetItem(lock(Offset, T::Type)), _)) => T
     rule getLock(_, _) => type(no-type) [owise]

     rule lockFlexibleStruct(T:StructType, N::Int) => lockFlexibleStruct'(T, getFieldInfo(T), N)
     rule lockFlexibleStruct(T::Type, _) => T [owise]

     syntax Type ::= "lockFlexibleStruct'" "(" Type "," FieldInfo "," Int ")" [function]
     rule lockFlexibleStruct'(T::Type, fieldInfo(
               _:List ListItem(typedDeclaration(t(Qs::Quals, Mods::Set, flexibleArrayType(T::Type)), FId::CId)),
               _, _,
               _:Map FId |-> FOffset:Int, _), N::Int)
          => addModifier(lock(FOffset, t(Qs, Mods, arrayType(T, N /Int byteSizeofType(T)))), T)
     rule lockFlexibleStruct'(T::Type, _, _) => T [owise]

     rule isStructOrUnionKLabel(#klabel(`structType`)) => true
     rule isStructOrUnionKLabel(#klabel(`unionType`)) => true
     rule isStructOrUnionKLabel(_) => false [owise]

endmodule
