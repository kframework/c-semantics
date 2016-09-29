module C-TYPING-MISC
     imports C-TYPING-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports FLOAT
     imports INT
     imports COMPAT-SYNTAX
     imports SYMLOC-SYNTAX
     imports C-SORTS
     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX

     //TODO(chathhorn): a lot of junk dumped here.

     rule simpleType(t(_, _, T::SimpleType)) => T

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
          => bitfieldType({flipSignedness({T}:>SimpleIntegerType)}:>BitfieldFieldType, N)

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

     rule inRange(V:Int, T:IntegerUType)
          => (V <=Int max(T)) andBool (V >=Int min(T))
     rule inRange(V:Float, T:FloatUType)
          => ((V <=Float fmax(T)) andBool (V >=Float fmin(T)))
          orBool isInfinite(V) orBool isNaN(V)

     rule fmin(T:FloatUType) => zeroCFloat(T) -Float maxValueFloat(typePrecision(T), typeExponent(T))
     rule fmax(T:FloatUType) => maxValueFloat(typePrecision(T), typeExponent(T))

     rule getParams(t(_, _, functionType(_, P::List))) => P
     rule getParams(T::Type) => .List
          requires notBool isFunctionType(T)

     rule setParams(t(Qs::Quals, Mods::Set, functionType(R::UType, _)), P::List)
          => t(Qs, Mods, functionType(R, P))

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
          SetItem(Packed()) // Pseudo-storage specifier.
          // Also typedef, technically.

     rule functionSpecifiers =>
          SetItem(Noreturn())
          SetItem(Inline())

     syntax Set ::= "constantModifiers" [function]
     rule constantModifiers =>
          SetItem(IntegerConstant)

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

     rule getFields(fieldInfo(L:List, _, _, _, _)) => L
     rule getFieldsTypes(fieldInfo(_, _, Ts:Map, _, _)) => Ts
     rule getFieldsOffsets(fieldInfo(_, _, _, Offs:Map, _)) => Offs
     rule getOffsetForField(F:CId, T:Type,
            fieldInfo(_, _,
                F |-> T _,
                F |-> Offset:Int _, _))
          => Offset
     rule getTypeForField(F:CId, ListItem(
                                  fieldInfo(_, _,
                                      F |-> T::Type _,
                                      _, _)) _)
          => T

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

     rule anonInDecls(ListItem(typedDeclaration(T:StructOrUnionType, _:NoName)) _)
          => true
     rule anonInDecls(ListItem(typedDeclaration(T::Type, F::CId)) Decls'::List)
          => anonInDecls(Decls')
          requires notBool isNoName(F) orBool notBool isStructOrUnionType(T)
     rule anonInDecls(.List) => false

     // Search anonymous fields
     syntax List  ::= searchAnonsNoName(CId, Bool, FieldInfo, Int, List, List,
                                        CId, Bool, FieldInfo, Int, List, List) [function]
     // recursion steps
     rule searchAnons(F:CId, IsUnion:Bool, Fields:FieldInfo, Offset:Int,
                   ListItem(typedDeclaration(T:StructOrUnionType, #NoName(I:Int))) Decls:List, Path:List)
          => searchAnonsNoName(F, IsUnion, Fields, Offset, Decls, Path,
                #NoName(I), isUnionType(T), getFieldInfo(T),          // F', IsUnion', Fields'
                Offset +Int getOffsetForField(#NoName(I), T, Fields), // Offset'
                getFields(getFieldInfo(T)),                           // Decls'
                Path ListItem(provInfo(#NoName(I), IsUnion, Fields))) // Path'

     rule searchAnonsNoName(F :CId, IsUnion :Bool, Fields :FieldInfo, Offset :Int, Decls :List, Path :List,
                            F':CId, IsUnion':Bool, Fields':FieldInfo, Offset':Int, Decls':List, Path':List)
          => searchAnons(F, IsUnion', Fields', Offset', Decls', Path')
             searchAnons(F, IsUnion, Fields, Offset, Decls, Path)
          requires (notBool F in_keys(getFieldsTypes(Fields')))
           andBool (notBool F in_keys(getFieldsOffsets(Fields')))
           andBool anonInDecls(Decls')

     rule searchAnonsNoName(F:CId, IsUnion:Bool, Fields :FieldInfo, Offset:Int, Decls :List, Path:List,
                            _    , _           , Fields':FieldInfo, _         , Decls':List, _)
          => searchAnons(F, IsUnion, Fields, Offset, Decls, Path)
          requires (notBool F in_keys(getFieldsTypes(Fields')))
           andBool (notBool F in_keys(getFieldsOffsets(Fields')))
           andBool (notBool anonInDecls(Decls'))

     rule searchAnons(F:CId, IsUnion:Bool, Fields:FieldInfo, Offset:Int,
                   ListItem(typedDeclaration(T::Type, F':CId)) Decls:List, Path:List)
          => searchAnons(F, IsUnion, Fields, Offset, Decls, Path)
         requires F =/=K F' andBool notBool (isNoName(F') andBool isStructOrUnionType(T))

     // recursion base cases
     rule searchAnons(_, _, _, _, .List, _) => .List

     // two bases cases to accomodate different clients
     // note: instead of creating a new type wrapper,
     //       the heterogenous list with element and the offset is returned
     rule searchAnonsNoName(F:CId, _            , _                , _          , _          , _         ,
                            _    , IsUnion':Bool, Fields':FieldInfo, Offset':Int, Decls':List, Path':List)
          => ListItem(Fields') ListItem(Offset') ListItem(IsUnion') Path'
          requires F in_keys(getFieldsTypes(Fields'))
           andBool F in_keys(getFieldsOffsets(Fields'))

     rule searchAnons(F:CId, IsUnion:Bool, fieldInfo(Decls:List, Size:Int,
                   F |-> T::Type Tys:Map, F |-> I:Int Offs:Map, PO:Set), Offset:Int, _:List,
                   Path:List)
         => ListItem(fieldInfo(Decls, Size, F |-> T Tys, F |-> I Offs, PO))
            ListItem(Offset) ListItem(IsUnion)
            Path

endmodule
