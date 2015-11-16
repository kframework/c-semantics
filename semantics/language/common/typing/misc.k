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

     rule simpleType(t(_, T:SimpleType)) => T

     rule char => cfg:charAlias

     rule correspondingUnsignedType(t(S:Set, signed-char))
          => t(S, unsigned-char)
     rule correspondingUnsignedType(t(S:Set, short-int))
          => t(S, unsigned-short-int)
     rule correspondingUnsignedType(t(S:Set, int))
          => t(S, unsigned-int)
     rule correspondingUnsignedType(t(S:Set, long-int))
          => t(S, unsigned-long-int)
     rule correspondingUnsignedType(t(S:Set, long-long-int))
          => t(S, unsigned-long-long-int)
     rule correspondingUnsignedType(t(S:Set, bitfieldType(T:Type, I:Int)))
          => t(S, bitfieldType(correspondingUnsignedType(T), I))
     rule correspondingUnsignedType(t(S:Set, enumType(_))) 
          => correspondingUnsignedType(t(S, cfg:enumAlias))

     rule correspondingSignedType(t(S:Set, unsigned-char))
          => t(S, signed-char)
     rule correspondingSignedType(t(S:Set, unsigned-short-int))
          => t(S, short-int)
     rule correspondingSignedType(t(S:Set, unsigned-int))
          => t(S, int)
     rule correspondingSignedType(t(S:Set, unsigned-long-int))
          => t(S, long-int)
     rule correspondingSignedType(t(S:Set, unsigned-long-long-int))
          => t(S, long-long-int)
     rule correspondingSignedType(t(S:Set, bitfieldType(T:Type, I:Int)))
          => t(S, bitfieldType(correspondingSignedType(T), I))
     rule correspondingSignedType(t(S:Set, enumType(_))) 
          => correspondingSignedType(t(S, cfg:enumAlias))

     rule min(t(_, bitfieldType(_:UnsignedIntegerType, _))) => 0
     rule max(t(_, bitfieldType(_:UnsignedIntegerType, N:Int)))
          => (1 <<Int absInt(N)) -Int 1

     rule min(t(_, bitfieldType(_:SignedIntegerType, N:Int)))
          => 0 -Int (1 <<Int absInt(N -Int 1))
     rule max(t(_, bitfieldType(_:SignedIntegerType, N:Int)))
          => (1 <<Int absInt(N -Int 1)) -Int 1

     rule min(t(_, bool)) => 0
     rule max(t(_, bool)) => 1

     rule min(t(_, signed-char))
          => 0 -Int (1 <<Int absInt(bitSizeofType(t(.Set, signed-char)) -Int 1))
     rule max(t(_, signed-char))
          => (1 <<Int absInt(bitSizeofType(t(.Set, signed-char)) -Int 1)) -Int 1
     rule min(t(_, short-int))
          => 0 -Int (1 <<Int absInt(bitSizeofType(t(.Set, short-int)) -Int 1))
     rule max(t(_, short-int))
          => (1 <<Int absInt(bitSizeofType(t(.Set, short-int)) -Int 1)) -Int 1
     rule min(t(_, int))
          => 0 -Int (1 <<Int absInt(bitSizeofType(t(.Set, int)) -Int 1))
     rule max(t(_, int))
          => (1 <<Int absInt(bitSizeofType(t(.Set, int)) -Int 1)) -Int 1
     rule min(t(_, long-int))
          => 0 -Int (1 <<Int absInt(bitSizeofType(t(.Set, long-int)) -Int 1))
     rule max(t(_, long-int))
          => (1 <<Int absInt(bitSizeofType(t(.Set, long-int)) -Int 1)) -Int 1
     rule min(t(_, long-long-int))
          => 0 -Int (1 <<Int absInt(bitSizeofType(t(.Set, long-long-int)) -Int 1))
     rule max(t(_, long-long-int))
          => (1 <<Int absInt(bitSizeofType(t(.Set, long-long-int)) -Int 1)) -Int 1

     rule min(t(_, unsigned-char)) => 0
     rule max(t(_, unsigned-char))
          => (1 <<Int absInt(bitSizeofType(t(.Set, unsigned-char)))) -Int 1
     rule min(t(_, unsigned-short-int)) => 0
     rule max(t(_, unsigned-short-int))
          => (1 <<Int absInt(bitSizeofType(t(.Set, unsigned-short-int)))) -Int 1
     rule min(t(_, unsigned-int)) => 0
     rule max(t(_, unsigned-int))
          => (1 <<Int absInt(bitSizeofType(t(.Set, unsigned-int)))) -Int 1
     rule min(t(_, unsigned-long-int)) => 0
     rule max(t(_, unsigned-long-int))
          => (1 <<Int absInt(bitSizeofType(t(.Set, unsigned-long-int)))) -Int 1
     rule min(t(_, unsigned-long-long-int)) => 0
     rule max(t(_, unsigned-long-long-int))
          => (1 <<Int absInt(bitSizeofType(t(.Set, unsigned-long-long-int)))) -Int 1

     rule min(t(S:Set, enumType(_))) => min(t(S, cfg:enumAlias))
     rule max(t(S:Set, enumType(_))) => max(t(S, cfg:enumAlias))

     rule inRange(V:Int, T:IntegerType)
          => ((V <=Int max(T)) andBool (V >=Int min(T)))
     rule inRange(V:Float, T:FloatType)
          => ((V <=Float fmax(T)) andBool (V >=Float fmin(T)))
          orBool isInfinite(V) orBool isNaN(V)

     syntax Float ::= fmax(Type) [function]
     syntax Float ::= fmin(Type) [function]

     rule fmin(t(_, float)) => 0.0f -Float maxValueFloat(24, 8)
     rule fmax(t(_, float)) => maxValueFloat(24, 8)

     rule fmin(t(_, double)) => 0.0 -Float maxValueFloat(53, 11)
     rule fmax(t(_, double)) => maxValueFloat(53, 11)

     rule fmin(t(_, long-double)) => Int2Float(0, 64, 15) -Float maxValueFloat(64, 15)
     rule fmax(t(_, long-double)) => maxValueFloat(64, 15)

     rule getParams(t(_, functionType(_, P:List))) => P
     rule getParams(T:Type) => .List
          requires notBool isFunctionType(T)

     rule setParams(t(Mods:Set, functionType(R:Type, _)), P:List)
          => t(Mods, functionType(R, P))
     rule getReturn(t(_, functionType(R:Type, _))) => R

     rule getModifiers(t(S::Set, _)) => S
     rule getModifiers(typedDeclaration(T::Type, _)) => getModifiers(T)
     rule getModifiers(variadic) => .Set

     syntax Type ::= setModifiers(Type, Set) [function]
     rule setModifiers(t(_, T:SimpleType), Mods:Set) => t(Mods, T)

     rule setModifiers(typedDeclaration(T:Type, _), Mods:Set)
          => setModifiers(T, Mods)

     rule getQualifiers(t(Mods:Set, arrayType(T::Type, _)))
          => intersectSet(Mods, typeQualifiers) getQualifiers(T)
     rule getQualifiers(t(Mods:Set, incompleteArrayType(T::Type)))
          => intersectSet(Mods, typeQualifiers) getQualifiers(T)
     rule getQualifiers(t(Mods:Set, flexibleArrayType(T::Type)))
          => intersectSet(Mods, typeQualifiers) getQualifiers(T)
     rule getQualifiers(t(Mods:Set, variableLengthArrayType(T::Type, _)))
          => intersectSet(Mods, typeQualifiers) getQualifiers(T)
     rule getQualifiers(T::Type)
          => intersectSet(getModifiers(T), typeQualifiers) [owise]

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

     rule stripQualifiers(t(Mods::Set, arrayType(T::Type, N::Int)))
          => t(Mods -Set typeQualifiers, arrayType(stripQualifiers(T), N))
     rule stripQualifiers(t(Mods::Set, incompleteArrayType(T::Type)))
          => t(Mods -Set typeQualifiers, incompleteArrayType(stripQualifiers(T)))
     rule stripQualifiers(t(Mods::Set, flexibleArrayType(T::Type)))
          => t(Mods -Set typeQualifiers, flexibleArrayType(stripQualifiers(T)))
     rule stripQualifiers(t(Mods::Set, variableLengthArrayType(T::Type, N:K)))
          => t(Mods -Set typeQualifiers, variableLengthArrayType(stripQualifiers(T), N))
     rule stripQualifiers(T::Type)
          => setModifiers(T, getModifiers(T) -Set typeQualifiers) [owise]

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
          => t(filterSet(Mods, #klabel(`isNotAlignas`)), T)

     syntax Bool ::= isNotAlignas(Modifier) [function]
     rule isNotAlignas(alignas(_)) => false
     rule isNotAlignas(_) => true [owise]

     rule stripReadFrom(t(Mods:Set, T:SimpleType))
          => t(filterSet(Mods, #klabel(`isNotReadFrom`)), T)

     syntax Bool ::= isNotReadFrom(Modifier) [function]
     rule isNotReadFrom(readFrom(_, _)) => false
     rule isNotReadFrom(_) => true [owise]

     rule stripConstants(T:Type)
          => setModifiers(T, getModifiers(T) -Set constantModifiers)
     rule stripConstants(tv(V:CValue, T:Type)) => tv(V, stripConstants(T))
     rule stripConstants(V:RValue) => V [owise]

     rule addQualifier(Q:CVSpecifier, T:Type)
          => addQualifiers(SetItem(Q), T)

     rule addQualifiers(Quals:Set, t(Mods:Set, arrayType(T:Type, N:Int)))
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
     rule addModifiers(_, T:Type) => T [owise]

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

     rule tagRestrict(Tag:Scope, t(Mods:Set, T:SimpleType))
          => t(tagRestrict(Tag, Mods), tagRestrict(Tag, T))
     rule tagRestrict(Tag:Scope, typedDeclaration(T:Type, X:CId))
          => typedDeclaration(tagRestrict(Tag, T), X)
     rule tagRestrict(_, variadic) => variadic

     syntax SimpleType ::= tagRestrict(Scope, SimpleType)
          [function, klabel('tagRestrictSimpleType)]
     rule tagRestrict(_, T:SimpleType) => T
     //TODO(chathhorn): reimplement
/*     rule tagRestrict(_, T:SimpleType) => T
     rule tagRestrict(_, enumType(X:CId)) => enumType(X)
     rule tagRestrict(_, bitfieldType(T:Type, N:Int)) => bitfieldType(T, N)
     rule tagRestrict(Tag:Scope, pointerType(T:Type))
          => pointerType(tagRestrict(Tag, T))
     rule tagRestrict(Tag:Scope, arrayType(T:Type, Sz:Int))
          => arrayType(tagRestrict(Tag, T), Sz)
     rule tagRestrict(Tag:Scope, incompleteArrayType(T:Type))
          => incompleteArrayType(tagRestrict(Tag, T))
     rule tagRestrict(Tag:Scope, flexibleArrayType(T:Type))
          => flexibleArrayType(tagRestrict(Tag, T))
     rule tagRestrict(Tag:Scope, variableLengthArrayType(T:Type, N:K))
          => variableLengthArrayType(tagRestrict(Tag, T), N)
     rule tagRestrict(_, incompleteStructType(X:CId))
          => incompleteStructType(X)
     rule tagRestrict(Tag:Scope, structType(X:CId,
               fieldInfo(Decls:List, NBits:Int, Types:Map, Offsets:Map)))
          => structType(X,
               fieldInfo(tagRestrict(Tag, Decls), NBits, tagRestrict(Tag, Types), Offsets))
     rule tagRestrict(_, incompleteUnionType(X:CId))
          => incompleteUnionType(X)
     rule tagRestrict(Tag:Scope, unionType(X:CId,
               fieldInfo(Decls:List, NBits:Int, Types:Map, Offsets:Map)))
          => unionType(X,
               fieldInfo(tagRestrict(Tag, Decls), NBits, tagRestrict(Tag, Types), Offsets))
     rule tagRestrict(_, functionType(T:Type, Params:List))
          => functionType(T, Params)
*/
     syntax List ::= tagRestrict(Scope, List)
          [function, klabel('tagRestrictList)]
     rule tagRestrict(Tag:Scope, ListItem(T:Type) L:List)
          => ListItem(tagRestrict(Tag, T)) tagRestrict(Tag, L)
     rule tagRestrict(_, .List) => .List

     syntax Map ::= tagRestrict(Scope, Map)
          [function, klabel('tagRestrictMap)]
     rule tagRestrict(Tag:Scope, X:CId |-> T:Type M:Map)
          => X |-> tagRestrict(Tag, T) tagRestrict(Tag, M)
     rule tagRestrict(_, .Map) => .Map

     syntax Set ::= tagRestrict(Scope, Set)
          [function, klabel('tagRestrictSet)]
     rule tagRestrict(Tag:Scope, S:Set)
          => SetItem(RestrictBlock(Tag)) S
          requires Restrict in S
     rule tagRestrict(_, S:Set) => S
          requires notBool (Restrict in S)

     rule getRestrictBlock(t(Mods:Set, _)) => getRestrictBlock'(.K, Mods)

     // TODO(chathhorn): more map pattern ugliness.
     syntax Scope ::= "getRestrictBlock'" "(" K "," Set ")" [function]
     rule getRestrictBlock'(RestrictBlock(Tag:Scope), _) => Tag
     rule getRestrictBlock'(_, S:Set) => getRestrictBlock''(S) [owise]

     syntax Scope ::= "getRestrictBlock''" "(" Set ")" [function]
     rule getRestrictBlock''(SetItem(K:K) S:Set) => getRestrictBlock'(K, S)
     rule getRestrictBlock''(.Set) => none

     rule getReadFrom(t(Mods:Set, _)) => getReadFrom'(.K, Mods)

     syntax Modifier ::= "getReadFrom'" "(" K "," Set ")" [function]
     rule getReadFrom'(readFrom(Loc:SymLoc, Len:Int), _) => readFrom(Loc, Len)
     rule getReadFrom'(_, S:Set) => getReadFrom''(S) [owise]

     syntax Modifier ::= "getReadFrom''" "(" Set ")" [function]
     rule getReadFrom''(SetItem(K:K) S:Set) => getReadFrom'(K, S)
     rule getReadFrom''(.Set) => noModifier

     rule getReadFromLoc(T:Type) => #getReadFromLoc(getReadFrom(T))

     syntax SymLoc ::= #getReadFromLoc(Modifier) [function]
     rule #getReadFromLoc(readFrom(Loc:SymLoc, _)) => Loc
     rule #getReadFromLoc(_) => NullPointer [owise]

     syntax Int ::= #getReadFromLen(Modifier) [function]
     rule getReadFromLen(T:Type) => #getReadFromLen(getReadFrom(T))

     rule #getReadFromLen(readFrom(_, Len:Int)) => Len
     rule #getReadFromLen(_) => 0 [owise]

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

     rule getFieldInfo(S:StructId) => #getFieldInfo(S, #configuration)
     rule getFieldInfo(t(_, structType(S:StructId))) => getFieldInfo(S)
     rule getFieldInfo(t(_, unionType(S:StructId))) => getFieldInfo(S)

     syntax FieldInfo ::= #getFieldInfo(StructId, K) [function]
     rule #getFieldInfo(S:StructId, <generatedTop>... <global>... <structs>... S |-> F:FieldInfo ...</structs> ...</global> ...</generatedTop>)
          => F
     rule #getFieldInfo(_, _) => #incomplete [owise]

     rule getTag(global(S:CId, _)) => S
     rule getTag(local(S:CId, _, _)) => S

     rule getTypeAtOffset(T:Type, 0) => T
     // Preserve the qualifiers.
     rule getTypeAtOffset(T:Type, Offset:Int) => t(getModifiers(T), no-type) //unions go here and keep track of the effective type set by the write
          requires (Offset =/=Int 0)
               andBool notBool isAggregateType(T)
     // Arrays.
     rule getTypeAtOffset(t(Mods:Set, arrayType(T:Type, _)), Offset:Int)
          => getTypeAtOffset(addQualifiers(Mods, T),
               Offset %Int bitSizeofType(T))
          requires Offset =/=Int 0 // We assume the offset must be in range.
     // Structs
     rule getTypeAtOffset(T:StructType, Offset:Int)
          => getTypeAtOffset(T, getFieldInfo(T), Offset)
          requires Offset =/=Int 0

     syntax Type ::= getTypeAtOffset(Type, K, Int) [function, klabel(getTypeAtOffset2)]
     rule getTypeAtOffset(BaseT:Type, fieldInfo(
               Fields:List (ListItem(typedDeclaration(_, FId:CId))),
               SI:Int,
               Types:Map (FId |-> T:Type),
               Offsets:Map (FId |-> FOffset:Int)
          ), Offset:Int)
          => getTypeAtOffset(BaseT, fieldInfo(
               Fields,
               SI,
               Types (FId |-> T),
               Offsets (FId |-> FOffset)
          ), Offset)
          requires (Offset =/=Int 0)
               andBool (FOffset >Int Offset)
     rule getTypeAtOffset(BaseT:Type, fieldInfo(
               _ ListItem(typedDeclaration(_, FId:CId)),
               _,
               _ FId |-> T:Type,
               _ FId |-> FOffset:Int
          ), Offset:Int)
          => getTypeAtOffset(addQualifiers(getModifiers(BaseT), T), Offset -Int FOffset)
          requires (Offset =/=Int 0)
               andBool (FOffset <=Int Offset)

     // TODO(chathhorn): move/refactor?
     rule <k> (.K => stabilize(T)) ~> stabilizeVLA(T:Type) ...</k>
          <curr-scope> S:Scope </curr-scope>
          requires isVariablyModifiedType(T) andBool S =/=K fileScope
          [structural]
     rule <k> stabilize(T:Type) ~> stabilizeVLA(_) => T ...</k>
          <curr-scope> S:Scope </curr-scope>
          requires notBool isVariablyModifiedType(T) andBool S =/=K fileScope
          [structural]
     rule <k> stabilizeVLA(T:Type) => T ...</k>
          <curr-scope> S:Scope </curr-scope>
          requires notBool isVariablyModifiedType(T) andBool S =/=K fileScope
          [structural]
     rule <k> (.K => CV("CTM2", "Variable-length array with file scope.", "6.7.6.2:2")) ~> stabilizeVLA(_) ...</k>
          <curr-scope> fileScope </curr-scope>

     // Although GCC seems to allow it, I don't think structs/unions are
     // allowed to have VM types (see 6.7.2.1p9).
     syntax KItem ::= stabilize(K)

     context stabilize(t(_, variableLengthArrayType(_, (HOLE:KItem => reval(HOLE)))))
          [result(RValue)]

     rule (.K => stabilize(T)) ~> stabilize(t(_, arrayType(T:Type, _)))
          requires isVariablyModifiedType(T)
          [structural]
     rule stabilize(T:Type) ~> stabilize(t(Mods:Set, arrayType(_, N:Int)))
          => stabilize(t(Mods, arrayType(T, N)))
          requires notBool isVariablyModifiedType(T)
          [structural]
     rule (.K => stabilize(T)) ~> stabilize(t(_, pointerType(T:Type)))
          requires isVariablyModifiedType(T)
          [structural]
     rule stabilize(T:Type) ~> stabilize(t(Mods:Set, pointerType(_)))
          => stabilize(t(Mods, pointerType(T)))
          requires notBool isVariablyModifiedType(T)
          [structural]

     rule stabilize(t(Mods:Set, variableLengthArrayType(T:Type, tv(N:Int, _)))
               => t(Mods, arrayType(T, N)))
          requires N >Int 0
          [structural]
     rule (.K => UNDEF("CTM1", "Variable-length array with length that evaluates to non-positive value at execution.", 
                       "6.7.6.2:5, J.2:1 item 75"))
          ~> stabilize(t(_, variableLengthArrayType(_, tv(N:Int, _))))
          requires N <=Int 0
          [structural]
     rule (_:ErrorExit => .K) ~> stabilize(t(Mods:Set, variableLengthArrayType(T:Type, tv((N:Int => 1), _))))
          requires N <=Int 0 andBool isErrorRecovery

endmodule
