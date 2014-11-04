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

     rule simplifyTruth(V:K) => V != tv(0, t(.Set, int))

     rule char => cfg:charAlias

     // Char types?
     rule correspondingUnsignedType(t(S:Set, int))
          => t(S, unsigned-int)
     rule correspondingUnsignedType(t(S:Set, long-int))
          => t(S, unsigned-long-int)
     rule correspondingUnsignedType(t(S:Set, long-long-int))
          => t(S, unsigned-long-long-int)

     rule correspondingSignedType(t(S:Set, unsigned-int))
          => t(S, int)
     rule correspondingSignedType(t(S:Set, unsigned-long-int))
          => t(S, long-int)
     rule correspondingSignedType(t(S:Set, unsigned-long-long-int))
          => t(S, long-long-int)

     rule min(t(_, bitfieldType(T:Type, _))) => 0
          when hasUnsignedIntegerType(T)
     rule max(t(_, bitfieldType(T:Type, N:Int))) 
          => (2 ^Int absInt(N)) -Int 1
          when hasUnsignedIntegerType(T)

     rule min(t(_, bitfieldType(T:Type, N:Int)))
          => 0 -Int (2 ^Int absInt(N -Int 1))
          when hasSignedIntegerType(T)
     rule max(t(_, bitfieldType(T:Type, N:Int)))
          => (2 ^Int absInt(N -Int 1)) -Int 1
          when hasSignedIntegerType(T)

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
          when hasIntegerType(T)
     rule inRange(V:Float, T:Type)
          => ((V <=Float fmax(T)) andBool (V >=Float fmin(T)))
          when hasFloatType(T)

     syntax Float ::= fmax(Type) [function]
     syntax Float ::= fmin(Type) [function]

     // TODO(chathhorn): real floating point support.
     rule fmin(t(_, float)) => 0.0 -Float (3.4 *Float (10.0 ^Float 38.0))
     rule fmax(t(_, float)) => 3.4 *Float (10.0 ^Float 38.0)

     // TODO(chathhorn): maude's floats are double-precision.
     // rule fmin(t(_, double)) => -1.79 *Float (10.0 ^Float 308.0)
     // rule fmax(t(_, double)) => 1.79 *Float (10.0 ^Float 308.0)
     rule fmin(t(_, double)) => 0.0 -Float (1.79 *Float (10.0 ^Float 308.0))
     rule fmax(t(_, double)) => 1.79 *Float (10.0 ^Float 308.0)

     // rule fmin(t(_, long-double)) => -1.19 *Float (10.0 ^Float 4932.0)
     // rule fmax(t(_, long-double)) => 1.19 *Float (10.0 ^Float 4932.0)
     rule fmin(t(_, long-double)) => 0.0 -Float (1.79 *Float (10.0 ^Float 308.0))
     rule fmax(t(_, long-double)) => 1.79 *Float (10.0 ^Float 308.0)

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
          when notBool isArrayType(T)

     rule getStorageSpecifiers(T:Type)
          => intersectSet(getModifiers(T), storageSpecifiers)

     rule getFunctionSpecifiers(T:Type)
          => intersectSet(getModifiers(T), functionSpecifiers)

     rule getSpecifiers(T:Type)
          => getStorageSpecifiers(T) getFunctionSpecifiers(T)

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

     syntax Set ::= "functionSpecifiers"
     rule functionSpecifiers =>
          SetItem(Noreturn)
          SetItem(Inline)

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
          when notBool isArrayType(T)

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

     rule stripAlignas(t(Mods:Set SetItem(alignas(_)), T:SimpleType))
          => stripAlignas(t(Mods, T))
     rule stripAlignas(T:Type) => T
          when notBool hasAlignas(T)

     rule stripReadFrom(t(Mods:Set SetItem(readFrom(_)), T:SimpleType))
          => stripReadFrom(t(Mods, T))
     rule stripReadFrom(T:Type) => T
          when notBool hasReadFrom(T)

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
          when notBool isArrayType(T)

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

     rule <k> completeTags(T:Type) => completeTags(Tags, T) ...</k>
          <structs> Tags:Map </structs>
          when Tags =/=Map .Map
     rule <k> completeTags(T:Type) => T ...</k>
          <structs> .Map </structs>

     // TODO(chathhorn): do this in a better way. Keeping all tags in a map and
     // checking it to tell whether a tag has been completed or not was
     // probably the better way to do things.
     rule completeTag(X:CId, Info:FieldInfo, T:Type)
          => completeTags(X |-> Info, T)

     rule completeTags(Tags:Map, t(S:Set, bitfieldType(T:Type, Sz:CSize)))
          => t(S, bitfieldType(completeTags(Tags, T), Sz))
     rule completeTags(Tags:Map, t(S:Set, functionType(R:Type, Args:List)))
          => t(S, functionType(completeTags(Tags, R), completeTagsInList(Tags, Args)))
     rule completeTags(Tags:Map, t(S:Set, pointerType(T:Type)))
          => t(S, pointerType(completeTags(Tags, T)))
     rule completeTags(Tags:Map, t(S:Set, arrayType(T:Type, Sz:CSize)))
          => t(S, arrayType(completeTags(Tags, T), Sz))
     rule completeTags(Tags:Map, t(S:Set, incompleteArrayType(T:Type)))
          => t(S, incompleteArrayType(completeTags(Tags, T)))
     rule completeTags(Tags:Map, t(S:Set, flexibleArrayType(T:Type)))
          => t(S, flexibleArrayType(completeTags(Tags:Map, T)))
     rule completeTags(Tags:Map, t(S:Set, variableLengthArrayType(T:Type, N:K)))
          => t(S, variableLengthArrayType(completeTags(Tags:Map, T), N))

     rule completeTags(_ X:CId |-> Info:FieldInfo,
               t(S:Set, incompleteStructType(X:CId)))
          => t(S, structType(X, bitSizeofStruct(Info), Info))
     rule completeTags(Tags:Map, t(S:Set, incompleteStructType(X:CId)))
          => t(S, incompleteStructType(X))
          when notBool X in keys(Tags)
     rule completeTags(X |-> _ Tags:Map, t(S:Set,
               structType(X:CId, NBits:Int,
                    fieldInfo(Decls:List, Types:Map, Offsets:Map))))
          => t(S, structType(X, NBits,
               fieldInfo(
                    completeTagsInList(Tags, Decls),
                    completeTagsInMap(Tags, Types),
                    Offsets)))
     // Don't complete recursive struct definitions.
     rule completeTags(Tags:Map, t(S:Set,
               structType(X:CId, NBits:Int,
                    fieldInfo(Decls:List, Types:Map, Offsets:Map))))
          => t(S, structType(X, NBits,
               fieldInfo(
                    completeTagsInList(Tags, Decls),
                    completeTagsInMap(Tags, Types),
                    Offsets)))
          when notBool (X in keys(Tags))

     rule completeTags(_ X:CId |-> Info:FieldInfo,
               t(S:Set, incompleteUnionType(X:CId)))
          => t(S, unionType(X, bitSizeofUnion(Info), Info)) 
     rule completeTags(Tags:Map, t(S:Set, incompleteUnionType(X:CId)))
          => t(S, incompleteUnionType(X))
          when notBool X in keys(Tags)
     rule completeTags(X |-> _ Tags:Map, t(S:Set,
               unionType(X:CId, NBits:Int,
                    fieldInfo(Decls:List, Types:Map, Offsets:Map))))
          => t(S, unionType(X, NBits,
               fieldInfo(
                    completeTagsInList(Tags, Decls),
                    completeTagsInMap(Tags, Types),
                    Offsets)))
     rule completeTags(Tags:Map, t(S:Set,
               unionType(X:CId, NBits:Int,
                    fieldInfo(Decls:List, Types:Map, Offsets:Map))))
          => t(S, unionType(X, NBits,
               fieldInfo(
                    completeTagsInList(Tags, Decls),
                    completeTagsInMap(Tags, Types),
                    Offsets)))
          when notBool (X in keys(Tags))

     rule completeTags(_, t(S:Set, T:SimpleType))
          => t(S, T)
          when (getKLabel(T) =/=KLabel 'bitfieldType)
               andBool (getKLabel(T) =/=KLabel 'functionType)
               andBool (getKLabel(T) =/=KLabel 'pointerType)
               andBool (getKLabel(T) =/=KLabel 'arrayType)
               andBool (getKLabel(T) =/=KLabel 'incompleteArrayType)
               andBool (getKLabel(T) =/=KLabel 'flexibleArrayType)
               andBool (getKLabel(T) =/=KLabel 'variableLengthArrayType)
               andBool (getKLabel(T) =/=KLabel 'incompleteStructType)
               andBool (getKLabel(T) =/=KLabel 'incompleteUnionType)
     // Function parameters.
     rule completeTags(Tags:Map, typedDeclaration(T:Type, X:CId))
          => typedDeclaration(completeTags(Tags, T), X)
     rule completeTags(_, variadic) => variadic

     rule completeTagsInList(Tags:Map, ListItem(T:Type) L:List)
          => ListItem(completeTags(Tags, T)) completeTagsInList(Tags, L)
     rule completeTagsInList(_, .List) => .List

     rule completeTagsInMap(Tags:Map, X:CId |-> T:Type M:Map)
          => X |-> completeTags(Tags, T) completeTagsInMap(Tags, M)
     rule completeTagsInMap(_, .Map) => .Map

     rule idsFromParams(
               ListItem(typedDeclaration(t(_, T:SimpleType), X:CId)) L:List )
          => ListItem(X) idsFromParams(L)
          when T =/=K void
     rule idsFromParams(ListItem(typedDeclaration(t(_, void), _))) => .List
     rule idsFromParams(ListItem(variadic)) => .List
     rule idsFromParams(.List) => .List

     rule tagRestrict(Tag:RestrictTag, t(Mods:Set, T:SimpleType))
          => t(tagRestrict(Tag, Mods), tagRestrict(Tag, T))
     rule tagRestrict(Tag:RestrictTag, typedDeclaration(T:Type, X:CId))
          => typedDeclaration(tagRestrict(Tag, T), X)
     rule tagRestrict(_, variadic) => variadic

     syntax SimpleType ::= tagRestrict(RestrictTag, SimpleType) [function]
     rule tagRestrict(_, T:BaseType) => T
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
     rule tagRestrict(Tag:RestrictTag, structType(X:CId, NBits:Int,
               fieldInfo(Decls:List, Types:Map, Offsets:Map)))
          => structType(X, NBits,
               fieldInfo(tagRestrict(Tag, Decls), tagRestrict(Tag, Types), Offsets))
     rule tagRestrict(_, incompleteUnionType(X:CId))
          => incompleteUnionType(X)
     rule tagRestrict(Tag:RestrictTag, unionType(X:CId, NBits:Int,
               fieldInfo(Decls:List, Types:Map, Offsets:Map)))
          => unionType(X, NBits,
               fieldInfo(tagRestrict(Tag, Decls), tagRestrict(Tag, Types), Offsets))
     rule tagRestrict(_, functionType(T:Type, Params:List))
          => functionType(T, Params)

     syntax List ::= tagRestrict(RestrictTag, List) [function]
     rule tagRestrict(Tag:RestrictTag, ListItem(T:Type) L:List)
          => ListItem(tagRestrict(Tag, T)) tagRestrict(Tag, L)
     rule tagRestrict(_, .List) => .List

     syntax Map ::= tagRestrict(RestrictTag, Map) [function]
     rule tagRestrict(Tag:RestrictTag, X:CId |-> T:Type M:Map)
          => X |-> tagRestrict(Tag, T) tagRestrict(Tag, M)
     rule tagRestrict(_, .Map) => .Map

     syntax Set ::= tagRestrict(RestrictTag, Set) [function]
     rule tagRestrict(Tag:RestrictTag, S:Set)
          => SetItem(RestrictBlock(Tag)) S
          when Restrict in S
     rule tagRestrict(_, S:Set) => S
          when notBool (Restrict in S)

     rule getRestrictBlock(t(SetItem(RestrictBlock(Tag:RestrictTag)) _, _))
          => Tag

     rule getReadFrom(t(_ SetItem(readFrom(Loc:SymLoc)), _)) => Loc

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
          when isInt(N) =/=K true

endmodule

