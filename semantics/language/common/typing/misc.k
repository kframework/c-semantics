module C-TYPING-MISC
     imports C-TYPING-SYNTAX

     imports C-BITSIZE-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX

     imports COMPAT-SYNTAX

     //TODO(chathhorn): a lot of junk dumped here.

     rule simpleType(t(_, T:SimpleType)) => T

     rule simplifyTruth(V:K) => V != tv(0, t(SetItem(IntegerConstant), int))

     rule char => cfg:charAlias

     rule correspondingUnsignedType(t(S:Set, signed-char))
          => t(S, unsigned-char)
     rule correspondingUnsignedType(t(S:Set, int))
          => t(S, unsigned-int)
     rule correspondingUnsignedType(t(S:Set, long-int))
          => t(S, unsigned-long-int)
     rule correspondingUnsignedType(t(S:Set, long-long-int))
          => t(S, unsigned-long-long-int)

     rule correspondingSignedType(t(S:Set, unsigned-char))
          => t(S, signed-char)
     rule correspondingSignedType(t(S:Set, unsigned-int))
          => t(S, int)
     rule correspondingSignedType(t(S:Set, unsigned-long-int))
          => t(S, long-int)
     rule correspondingSignedType(t(S:Set, unsigned-long-long-int))
          => t(S, long-long-int)

     rule min(t(_, bitfieldType(T:Type, _))) => 0
          requires hasUnsignedIntegerType(T)
     rule max(t(_, bitfieldType(T:Type, N:Int)))
          => (2 ^Int absInt(N)) -Int 1
          requires hasUnsignedIntegerType(T)

     rule min(t(_, bitfieldType(T:Type, N:Int)))
          => 0 -Int (2 ^Int absInt(N -Int 1))
          requires hasSignedIntegerType(T)
     rule max(t(_, bitfieldType(T:Type, N:Int)))
          => (2 ^Int absInt(N -Int 1)) -Int 1
          requires hasSignedIntegerType(T)

     rule min(t(_, bool)) => 0
     rule max(t(_, bool)) => 1

     rule min(t(_, signed-char))
          => 0 -Int (2 ^Int absInt(bitSizeofType(t(.Set, signed-char)) -Int 1))
     rule max(t(_, signed-char))
          => (2 ^Int absInt(bitSizeofType(t(.Set, signed-char)) -Int 1)) -Int 1
     rule min(t(_, short-int))
          => 0 -Int (2 ^Int absInt(bitSizeofType(t(.Set, short-int)) -Int 1))
     rule max(t(_, short-int))
          => (2 ^Int absInt(bitSizeofType(t(.Set, short-int)) -Int 1)) -Int 1
     rule min(t(_, int))
          => 0 -Int (2 ^Int absInt(bitSizeofType(t(.Set, int)) -Int 1))
     rule max(t(_, int))
          => (2 ^Int absInt(bitSizeofType(t(.Set, int)) -Int 1)) -Int 1
     rule min(t(_, long-int))
          => 0 -Int (2 ^Int absInt(bitSizeofType(t(.Set, long-int)) -Int 1))
     rule max(t(_, long-int))
          => (2 ^Int absInt(bitSizeofType(t(.Set, long-int)) -Int 1)) -Int 1
     rule min(t(_, long-long-int))
          => 0 -Int (2 ^Int absInt(bitSizeofType(t(.Set, long-long-int)) -Int 1))
     rule max(t(_, long-long-int))
          => (2 ^Int absInt(bitSizeofType(t(.Set, long-long-int)) -Int 1)) -Int 1

     rule min(t(_, unsigned-char)) => 0
     rule max(t(_, unsigned-char))
          => 2 ^Int absInt(bitSizeofType(t(.Set, unsigned-char))) -Int 1
     rule min(t(_, unsigned-short-int)) => 0
     rule max(t(_, unsigned-short-int))
          => (2 ^Int absInt(bitSizeofType(t(.Set, unsigned-short-int)))) -Int 1
     rule min(t(_, unsigned-int)) => 0
     rule max(t(_, unsigned-int))
          => (2 ^Int absInt(bitSizeofType(t(.Set, unsigned-int)))) -Int 1
     rule min(t(_, unsigned-long-int)) => 0
     rule max(t(_, unsigned-long-int))
          => (2 ^Int absInt(bitSizeofType(t(.Set, unsigned-long-int)))) -Int 1
     rule min(t(_, unsigned-long-long-int)) => 0
     rule max(t(_, unsigned-long-long-int))
          => (2 ^Int absInt(bitSizeofType(t(.Set, unsigned-long-long-int)))) -Int 1

     rule min(t(_, enumType(_))) => cfg:enumMin
     rule max(t(_, enumType(_))) => cfg:enumMax

     rule inRange(V:Int, T:Type)
          => ((V <=Int max(T)) andBool (V >=Int min(T)))
          requires hasIntegerType(T)
     rule inRange(V:Float, T:Type)
          => ((V <=Float fmax(T)) andBool (V >=Float fmin(T)))
          orBool isInfinite(V) orBool isNaN(V)
          requires hasFloatType(T)

     syntax Float ::= fmax(Type) [function]
     syntax Float ::= fmin(Type) [function]

     rule fmin(t(_, float)) => 0.0f -Float maxValueFloat(24, 8)
     rule fmax(t(_, float)) => maxValueFloat(24, 8)

     rule fmin(t(_, double)) => 0.0 -Float maxValueFloat(53, 11)
     rule fmax(t(_, double)) => maxValueFloat(53, 11)

     rule fmin(t(_, long-double)) => Int2Float(0, 64, 15) -Float maxValueFloat(64, 15)
     rule fmax(t(_, long-double)) => maxValueFloat(64, 15)

     rule getParams(t(_, functionType(_, P:List))) => P
     rule setParams(t(Mods:Set, functionType(R:Type, _)), P:List)
          => t(Mods, functionType(R, P))
     rule getReturn(t(_, functionType(R:Type, _))) => R

     rule getModifiers(t(S:Set, _)) => S
     rule getModifiers(typedDeclaration(T:Type, _)) => getModifiers(T)
     rule getModifiers(variadic) => .Set

     syntax Type ::= setModifiers(Type, Set) [function]
     rule setModifiers(t(_, T:SimpleType), Mods:Set) => t(Mods, T)

     rule setModifiers(typedDeclaration(T:Type, _), Mods:Set)
          => setModifiers(T, Mods)

     rule getQualifiers(t(Mods:Set, arrayType(T:Type, _)))
          => intersectSet(Mods, typeQualifiers) getQualifiers(T)
     rule getQualifiers(t(Mods:Set, incompleteArrayType(T:Type)))
          => intersectSet(Mods, typeQualifiers) getQualifiers(T)
     rule getQualifiers(t(Mods:Set, flexibleArrayType(T:Type)))
          => intersectSet(Mods, typeQualifiers) getQualifiers(T)
     rule getQualifiers(t(Mods:Set, variableLengthArrayType(T:Type, _)))
          => intersectSet(Mods, typeQualifiers) getQualifiers(T)
     rule getQualifiers(T:Type)
          => intersectSet(getModifiers(T), typeQualifiers)
          requires notBool isArrayType(T)

     rule getStorageSpecifiers(T:Type)
          => intersectSet(getModifiers(T), storageSpecifiers)

     rule getFunctionSpecifiers(T:Type)
          => intersectSet(getModifiers(T), functionSpecifiers)

     rule getSpecifiers(T:Type)
          => getStorageSpecifiers(T) getFunctionSpecifiers(T)

     rule getConstants(T:Type)
          => intersectSet(getModifiers(T), constantModifiers)

     // These are the only actual members "type qualifier" syntactic class.
     rule typeQualifiers =>
          SetItem(Const)
          SetItem(Restrict)
          SetItem(Volatile)
          SetItem(Atomic)

     rule storageSpecifiers =>
          SetItem(Static)
          SetItem(Extern)
          SetItem(Auto)
          SetItem(ThreadLocal)
          SetItem(Register)
          // Also typedef, technically.

     syntax Set ::= "functionSpecifiers" [function]
     rule functionSpecifiers =>
          SetItem(Noreturn)
          SetItem(Inline)

     syntax Set ::= "constantModifiers" [function]
     rule constantModifiers =>
          SetItem(IntegerConstant)

     rule stripQualifiers(t(Mods:Set, arrayType(T:Type, N:CSize)))
          => t(Mods -Set typeQualifiers, arrayType(stripQualifiers(T), N))
     rule stripQualifiers(t(Mods:Set, incompleteArrayType(T:Type)))
          => t(Mods -Set typeQualifiers, incompleteArrayType(stripQualifiers(T)))
     rule stripQualifiers(t(Mods:Set, flexibleArrayType(T:Type)))
          => t(Mods -Set typeQualifiers, flexibleArrayType(stripQualifiers(T)))
     rule stripQualifiers(t(Mods:Set, variableLengthArrayType(T:Type, N:K)))
          => t(Mods -Set typeQualifiers, variableLengthArrayType(stripQualifiers(T), N))
     rule stripQualifiers(T:Type)
          => setModifiers(T, getModifiers(T) -Set typeQualifiers)
          requires notBool isArrayType(T)

     rule stripStorageSpecifiers(t(Mods:Set, T:SimpleType))
          => t(Mods -Set storageSpecifiers, T)
     rule stripStorageSpecifiers(typedDeclaration(T:Type, X:CId))
          => typedDeclaration(stripStorageSpecifiers(T), X)

     rule stripFunctionSpecifiers(t(Mods:Set, T:SimpleType))
          => t(Mods -Set functionSpecifiers, T)
     rule stripFunctionSpecifiers(typedDeclaration(T:Type, X:CId))
          => typedDeclaration(stripFunctionSpecifiers(T), X)

     rule stripSpecifiers(T:Type)
          => stripStorageSpecifiers(stripFunctionSpecifiers(T))

     rule stripAlignas(t(Mods:Set, T:SimpleType))
          => t(filterSet(Mods, 'isNotAlignas), T)

     syntax Bool ::= isNotAlignas(Modifier) [function]
     rule isNotAlignas(alignas(_)) => false
     rule isNotAlignas(_) => true [owise]

     rule stripReadFrom(t(Mods:Set, T:SimpleType))
          => t(filterSet(Mods, 'isNotReadFrom), T)

     syntax Bool ::= isNotReadFrom(Modifier) [function]
     rule isNotReadFrom(readFrom(_)) => false
     rule isNotReadFrom(_) => true [owise]

     rule stripConstants(T:Type)
          => setModifiers(T, getModifiers(T) -Set constantModifiers)
     rule stripConstants(tv(V:CValue, T:Type)) => tv(V, stripConstants(T))
     rule stripConstants(V:KItem) => V [owise]

     rule addQualifier(Q:CVSpecifier, T:Type)
          => addQualifiers(SetItem(Q), T)

     rule addQualifiers(Quals:Set, t(Mods:Set, arrayType(T:Type, N:CSize)))
          => t(Mods intersectSet(Quals, typeQualifiers),
               arrayType(addQualifiers(Quals, T), N))
     rule addQualifiers(Quals:Set, t(Mods:Set, incompleteArrayType(T:Type)))
          => t(Mods intersectSet(Quals, typeQualifiers),
               incompleteArrayType(addQualifiers(Quals, T)))
     rule addQualifiers(Quals:Set, t(Mods:Set, flexibleArrayType(T:Type)))
          => t(Mods intersectSet(Quals, typeQualifiers),
               flexibleArrayType(addQualifiers(Quals, T)))
     rule addQualifiers(Quals:Set, t(Mods:Set, variableLengthArrayType(T:Type, N:K)))
          => t(Mods intersectSet(Quals, typeQualifiers),
               variableLengthArrayType(addQualifiers(Quals, T), N))
     rule addQualifiers(Quals:Set, T:Type) => addModifiers(Quals, T)
          requires notBool isArrayType(T)

     rule addStorage(S:Storage, T:Type) => addModifier(S, T)

     rule addModifier(M:Modifier, T:Type) => addModifiers(SetItem(M), T)

     rule addModifiers(Mods':Set, t(Mods:Set, T:SimpleType))
          => t(Mods' Mods, T)

     rule innerType(t(_, arrayType(T:Type, _))) => T
     rule innerType(t(_, incompleteArrayType(T:Type))) => T
     rule innerType(t(_, flexibleArrayType(T:Type))) => T
     rule innerType(t(_, variableLengthArrayType(T:Type, _))) => T
     rule innerType(t(_, pointerType(T:Type))) => T
     rule innerType(t(_, bitfieldType(T:Type, _))) => T
     rule innerType(t(_, functionType(T:Type, _))) => T
     rule innerType(typedDeclaration(T:Type, _)) => T

     rule idsFromParams(
               ListItem(typedDeclaration(t(_, T:SimpleType), X:CId)) L:List )
          => ListItem(X) idsFromParams(L)
          requires T =/=K void
     rule idsFromParams(ListItem(typedDeclaration(t(_, void), _))) => .List
     rule idsFromParams(ListItem(variadic)) => .List
     rule idsFromParams(.List) => .List

     rule tagRestrict(Tag:RestrictTag, t(Mods:Set, T:SimpleType))
          => t(tagRestrict(Tag, Mods), tagRestrict(Tag, T))
     rule tagRestrict(Tag:RestrictTag, typedDeclaration(T:Type, X:CId))
          => typedDeclaration(tagRestrict(Tag, T), X)
     rule tagRestrict(_, variadic) => variadic

     syntax SimpleType ::= tagRestrict(RestrictTag, SimpleType)
          [function, klabel('tagRestrictSimpleType)]
     rule tagRestrict(_, T:SimpleType) => T
     //TODO(chathhorn): reimplement
/*     rule tagRestrict(_, T:BaseType) => T
     rule tagRestrict(_, enumType(X:CId)) => enumType(X)
     rule tagRestrict(_, bitfieldType(T:Type, N:Int)) => bitfieldType(T, N)
     rule tagRestrict(Tag:RestrictTag, pointerType(T:Type))
          => pointerType(tagRestrict(Tag, T))
     rule tagRestrict(Tag:RestrictTag, arrayType(T:Type, Sz:CSize))
          => arrayType(tagRestrict(Tag, T), Sz)
     rule tagRestrict(Tag:RestrictTag, incompleteArrayType(T:Type))
          => incompleteArrayType(tagRestrict(Tag, T))
     rule tagRestrict(Tag:RestrictTag, flexibleArrayType(T:Type))
          => flexibleArrayType(tagRestrict(Tag, T))
     rule tagRestrict(Tag:RestrictTag, variableLengthArrayType(T:Type, N:K))
          => variableLengthArrayType(tagRestrict(Tag, T), N)
     rule tagRestrict(_, incompleteStructType(X:CId))
          => incompleteStructType(X)
     rule tagRestrict(Tag:RestrictTag, structType(X:CId,
               fieldInfo(Decls:List, NBits:Int, Types:Map, Offsets:Map)))
          => structType(X,
               fieldInfo(tagRestrict(Tag, Decls), NBits, tagRestrict(Tag, Types), Offsets))
     rule tagRestrict(_, incompleteUnionType(X:CId))
          => incompleteUnionType(X)
     rule tagRestrict(Tag:RestrictTag, unionType(X:CId,
               fieldInfo(Decls:List, NBits:Int, Types:Map, Offsets:Map)))
          => unionType(X,
               fieldInfo(tagRestrict(Tag, Decls), NBits, tagRestrict(Tag, Types), Offsets))
     rule tagRestrict(_, functionType(T:Type, Params:List))
          => functionType(T, Params)
*/
     syntax List ::= tagRestrict(RestrictTag, List)
          [function, klabel('tagRestrictList)]
     rule tagRestrict(Tag:RestrictTag, ListItem(T:Type) L:List)
          => ListItem(tagRestrict(Tag, T)) tagRestrict(Tag, L)
     rule tagRestrict(_, .List) => .List

     syntax Map ::= tagRestrict(RestrictTag, Map)
          [function, klabel('tagRestrictMap)]
     rule tagRestrict(Tag:RestrictTag, X:CId |-> T:Type M:Map)
          => X |-> tagRestrict(Tag, T) tagRestrict(Tag, M)
     rule tagRestrict(_, .Map) => .Map

     syntax Set ::= tagRestrict(RestrictTag, Set)
          [function, klabel('tagRestrictSet)]
     rule tagRestrict(Tag:RestrictTag, S:Set)
          => SetItem(RestrictBlock(Tag)) S
          requires Restrict in S
     rule tagRestrict(_, S:Set) => S
          requires notBool (Restrict in S)

     rule getRestrictBlock(t(Mods:Set, _)) => getRestrictBlock'(.K, Mods)

     // TODO(chathhorn): more map pattern ugliness.
     syntax RestrictTag ::= "getRestrictBlock'" "(" K "," Set ")" [function]
     rule getRestrictBlock'(.K, SetItem(K:K) S:Set) => getRestrictBlock'(K, S)
     rule getRestrictBlock'(RestrictBlock(Tag:RestrictTag), _) => Tag
     rule getRestrictBlock'(K:K, S:Set) => getRestrictBlock'(.K, S)
          requires getKLabel(K) =/=KLabel 'RestrictBlock
               andBool (K =/=K .K)

     rule getReadFrom(t(Mods:Set, _)) => getReadFrom'(.K, Mods)

     syntax SymLoc ::= "getReadFrom'" "(" K "," Set ")" [function]
     rule getReadFrom'(.K, SetItem(K:K) S:Set) => getReadFrom'(K, S)
     rule getReadFrom'(readFrom(Loc:SymLoc), _) => Loc
     rule getReadFrom'(K:K, S:Set) => getReadFrom'(.K, S)
          requires getKLabel(K) =/=KLabel 'readFrom
               andBool (K =/=K .K)
     rule getReadFrom'(.K, .Set) => NullPointer

     rule arrayLength(t(_, arrayType(_, N:Int))) => N
     /*@ these large numbers are used instead of an infinity---the result of
     these rules shouldn't be used later anyway */
     rule arrayLength(t(_, flexibleArrayType(_)))
          => 36893488147419103232
     // Probably should never come up.
     rule arrayLength(t(_, variableLengthArrayType(_, _)))
          => 36893488147419103232
     rule arrayLength(t(_, incompleteArrayType(_)))
          => 36893488147419103232
     rule arrayLength(t(_, arrayType(_, N:CSize))) // Also VLA.
          => 36893488147419103232
          requires isInt(N) =/=K true

     rule getFieldInfo(S:StructId) => #getFieldInfo(S, #configuration)
     rule getFieldInfo(t(_, structType(S:StructId))) => getFieldInfo(S)
     rule getFieldInfo(t(_, unionType(S:StructId))) => getFieldInfo(S)
     syntax KItem ::= #getFieldInfo(StructId, Bag) [function]
     rule #getFieldInfo(S:StructId, <generatedTop>... <global>... <structs>... S |-> F:FieldInfo ...</structs> ...</global> ...</generatedTop> _:Bag)
          => F
     rule #getFieldInfo(_, _) => #incomplete [owise]

     rule getTag(global(S:CId, _)) => S
     rule getTag(local(S:CId, _, _)) => S

     rule getTypeAtOffset(T:Type, 0) => T
     // Preserve the qualifiers.
     rule getTypeAtOffset(T:Type, Offset:Int) => t(getModifiers(T), no-type)
          requires (Offset =/=Int 0)
               andBool notBool isAggregateType(T)
     // Arrays.
     rule getTypeAtOffset(t(Mods:Set, arrayType(T:Type, _)), Offset:Int)
          => getTypeAtOffset(addQualifiers(Mods, T),
               Offset %Int byteSizeofType(T))
          requires Offset =/=Int 0 // We assume the offset must be in range.
     // Structs.
     rule getTypeAtOffset(t(Mods:Set, structType(S:StructId)), Offset:Int)
          => getTypeAtOffset(t(Mods, structType(S)), getFieldInfo(S), Offset)

     syntax Type ::= getTypeAtOffset(Type, K, Int) [function]
     rule getTypeAtOffset(t(Mods:Set, structType(S:StructId)), fieldInfo(
               Fields:List (ListItem(typedDeclaration(_, FId:CId))),
               SI:Int,
               Types:Map (FId |-> T:Type),
               Offsets:Map (FId |-> FOffset:Int)
          ), Offset:Int)
          => getTypeAtOffset(t(Mods, structType(S)), fieldInfo(
               Fields,
               SI,
               Types (FId |-> T),
               Offsets (FId |-> FOffset)
          ), Offset)
          requires (Offset =/=Int 0)
               andBool (FOffset >Int Offset)
     rule getTypeAtOffset(t(Mods:Set, structType(_)), fieldInfo(
               _ ListItem(typedDeclaration(_, FId:CId)),
               _,
               _ FId |-> T:Type,
               _ FId |-> FOffset:Int
          ), Offset:Int)
          => getTypeAtOffset(addQualifiers(Mods, T), Offset -Int FOffset)
          requires (Offset =/=Int 0)
               andBool (FOffset <=Int Offset)

endmodule
