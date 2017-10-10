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

     rule arrayToPtrType(T:ArrayType)
          => ut(getModifiers(T), pointerType(innerType(T)))
     rule arrayToPtrType(T::Type) => utype(T) [owise]

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
     rule flipSignedness(bitfieldType(T::SimpleType, N::Int))
          => bitfieldType(flipSignedness({T}:>SimpleIntegerType), N)

     rule flipSignedness(_:SimpleUnsignedCharType) => signed-char
     rule flipSignedness(unsigned-short-int) => short-int
     rule flipSignedness(unsigned-int) => int
     rule flipSignedness(unsigned-long-int) => long-int
     rule flipSignedness(unsigned-long-long-int) => long-long-int

     rule flipSignedness(_:SimpleSignedCharType) => unsigned-char
     rule flipSignedness(short-int) => unsigned-short-int
     rule flipSignedness(int) => unsigned-int
     rule flipSignedness(long-int) => unsigned-long-int
     rule flipSignedness(long-long-int) => unsigned-long-long-int

     rule flipSignedness(bool) => bool

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
     rule getRestrictBlock''(SetItem(K:K) S:Set) => getRestrictBlock'(K, S)
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

     rule getFieldDecls(T:StructOrUnionType) => getFieldDecls'(getFields(T))
     rule getFieldDecls(_) => .List [owise]

     rule findFieldDecls(T:StructOrUnionType) => getFieldDecls'(getFlatFields(T))
     rule findFieldDecls(_) => .List [owise]

     rule getFieldTypes(T::StructOrUnionType) => getFieldTypes'(getFields(T))

     syntax List ::= "getFieldTypes'" "(" FieldInfo ")" [function]
     rule getFieldTypes'(fieldInfo(ListItem(typedDeclaration(_, F::CId)) Decls::List, Sz::Int, Types::Map (F |-> T::Type), Offsets::Map, Padding::Set))
          => ListItem(T) getFieldTypes'(fieldInfo(Decls, Sz, Types, Offsets, Padding))
     rule getFieldTypes'(_) => .List [owise]

     syntax List ::= "getFieldDecls'" "(" FieldInfo ")" [function]
     rule getFieldDecls'(fieldInfo(L::List, _, _, _, _)) => L

     rule getFieldOffset(F::CId, T::StructOrUnionType) => getFieldOffset'(F, getFields(T))

     rule findFieldOffset(F::CId, T::StructOrUnionType) => getFieldOffset'(F, getFlatFields(T))

     syntax Int ::= "getFieldOffset'" "(" CId "," FieldInfo ")" [function]
     rule getFieldOffset'(F::CId, fieldInfo(_, _, _, F |-> Offset::Int _, _)) => Offset
     rule getFieldOffset'(_, _) => -1 [owise]

     rule getFieldType(F::CId, T::StructOrUnionType) => getFieldType'(F, getFields(T))

     rule findFieldType(F::CId, T::StructOrUnionType) => getFieldType'(F, getFlatFields(T))

     syntax Type ::= "getFieldType'" "(" CId "," FieldInfo ")" [function]
     rule getFieldType'(F::CId, fieldInfo(_, _, F |-> T::Type _, _, _)) => T
     rule getFieldType'(_, _) => type(no-type) [owise]

     syntax Modifier ::= activeVariant(CId)
     rule getActiveVariant(t(_, SetItem(activeVariant(F::CId)) _, _) #as T::UnionType)
          => getFieldType(F, T)
     rule getActiveVariant(_) => type(no-type) [owise]

     rule setActiveVariant(F::CId, T::UnionType) => addModifier(activeVariant(F), T)

     rule clearActiveVariant(t(_, _::Set (SetItem(activeVariant(_)) => .Set), unionType(_)))
     rule clearActiveVariant(T::Type) => T
          requires notBool isUnionType(T)
     rule clearActiveVariant(T:UnionType)
          => setFields(clearActiveVariant'(getFieldDecls(T), getFields(T)), T) [owise]

     syntax FieldInfo ::= "clearActiveVariant'" "(" List "," FieldInfo ")" [function]
     rule clearActiveVariant'(ListItem(typedDeclaration(_, F::CId)) Decls::List, Fields::FieldInfo)
          => clearActiveVariant'(Decls, setFieldType'(F, clearActiveVariant(getFieldType'(F, Fields)), Fields))
     rule clearActiveVariant'(_, Fields::FieldInfo) => Fields [owise]

     syntax CId ::= "getFieldAtOffset'" "(" Int "," FieldInfo ")" [function]
     rule getFieldAtOffset'(Offset::Int, fieldInfo(_::List (ListItem(typedDeclaration(_, F::CId)) => .List), _, _, _::Map (F |-> FOffset::Int => .Map), _))
          requires FOffset >Int Offset
     rule getFieldAtOffset'(_, fieldInfo(_ ListItem(typedDeclaration(_, F::CId)), _, _, _, _)) => F [owise]

     rule floorFieldOffset(Offset::Int, T::StructOrUnionType)
          => floorFieldOffset'(Offset, getFields(T))

     syntax Int ::= "floorFieldOffset'" "(" Int "," FieldInfo ")" [function]
     rule floorFieldOffset'(Offset::Int, Fields::FieldInfo)
          => getFieldOffset'(getFieldAtOffset'(Offset, Fields), Fields)

     rule getFieldTypeAtOffset(Offset::Int, T::StructOrUnionType)
          => getFieldTypeAtOffset'(Offset, getFields(T))

     syntax Type ::= "getFieldTypeAtOffset'" "(" Int "," FieldInfo ")" [function]
     rule getFieldTypeAtOffset'(Offset::Int, Fields::FieldInfo)
          => getFieldType'(getFieldAtOffset'(Offset, Fields), Fields)

     rule getFlatFields(T::StructOrUnionType) => toFlatFieldInfo(getFields(T))

     syntax FieldInfo ::= toFlatFieldInfo(TagInfo) [function]
     rule toFlatFieldInfo(Fields:FieldInfo) => flattenFieldInfo(.K, .K, Fields, fieldInfo(.List, 0, .Map, .Map, .Set))
     rule toFlatFieldInfo(_) => fieldInfo(.List, 0, .Map, .Map, .Set) [owise]

     syntax FieldInfo ::= flattenFieldInfo(K, K, FieldInfo, FieldInfo) [function]
     rule flattenFieldInfo(.K => getFlatFields(T), .K => Offset,
               fieldInfo((ListItem(typedDeclaration(T:StructOrUnionType, F:NoName)) => .List) _, _, _, (F |-> Offset::Int) _, _),
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
     rule addOffset(Offset::Int, (K:K |-> N:Int) M::Map)
          => K |-> (N +Int Offset) addOffset(Offset, M)
     rule addOffset(_, _) => .Map [owise]

     syntax Set ::= addPaddingOffset(Int, Set) [function]
     rule addPaddingOffset(Offset::Int, SetItem(N::Int) S::Set)
          => SetItem(N +Int Offset) addPaddingOffset(Offset, S)
     rule addPaddingOffset(_, _) => .Set [owise]

     rule setFieldType(F::CId, T'::Type, T::StructOrUnionType)
          => setFields(setFieldType'(F, T', getFields(T)), T)

     syntax FieldInfo ::= "setFieldType'" "(" CId "," Type "," FieldInfo ")" [function]
     rule setFieldType'(F::CId, T::Type, fieldInfo(Decls::List, Sz::Int, Types::Map, Offsets::Map, Padding::Set))
          => fieldInfo(Decls, Sz, Types[F <- T], Offsets, Padding)

     syntax StructOrUnionType ::= setFields(FieldInfo, StructOrUnionType) [function]
     rule setFields(_, t(_, (SetItem(fieldInfo(_, _, _, _, _)) => .Set), structType(_)))
     rule setFields(_, t(_, (SetItem(fieldInfo(_, _, _, _, _)) => .Set), unionType(_)))
     rule setFields(Fields::FieldInfo, T::StructOrUnionType) => addModifier(Fields, T) [owise]

     rule setFieldTypeAtOffset(Offset::Int, T'::Type, T::StructOrUnionType)
          => setFields(setFieldType'(getFieldAtOffset'(Offset, getFields(T)), T', getFields(T)), T)

     rule setInnerType(T::Type, t(Qs::Quals, Mods::Set, arrayType(_, N::Int)))
          => t(Qs, Mods, arrayType(T, N))
     rule setInnerType(T::Type, t(Qs::Quals, Mods::Set, flexibleArrayType(_)))
          => t(Qs, Mods, flexibleArrayType(T))
     rule setInnerType(T::Type, t(Qs::Quals, Mods::Set, incompleteArrayType(_)))
          => t(Qs, Mods, incompleteArrayType(T))
     rule setInnerType(T::Type, t(Qs::Quals, Mods::Set, unspecifiedArrayType(_)))
          => t(Qs, Mods, unspecifiedArrayType(T))
     rule setInnerType(T::Type, t(Qs::Quals, Mods::Set, variableLengthArrayType(_, N:K)))
          => t(Qs, Mods, variableLengthArrayType(T, N))

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

     rule isStructOrUnionKLabel(#klabel(`structType`)) => true
     rule isStructOrUnionKLabel(#klabel(`unionType`)) => true
     rule isStructOrUnionKLabel(_) => false [owise]

endmodule
