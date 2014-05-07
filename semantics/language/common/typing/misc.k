module C-TYPING-MISC
     imports C-TYPING-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports COMPAT-SYNTAX

     //TODO(chathhorn): a lot of junk dumped here.

     rule simplifyTruth(V:K) => V != tv(0, t(.Set, int))

     rule char => cfg:charAlias [structural, anywhere]

     syntax Int ::= numBytes(Type) [function]
     rule numBytes(t(_, bool)) => cfg:sizeofBool
     rule numBytes(t(_, signed-char)) => cfg:sizeofSignedChar
     rule numBytes(t(_, short-int)) => cfg:sizeofShortInt
     rule numBytes(t(_, int)) => cfg:sizeofInt
     rule numBytes(t(_, long-int)) => cfg:sizeofLongInt
     rule numBytes(t(_, long-long-int)) => cfg:sizeofLongLongInt
     
     rule numBytes(t(_, float)) => cfg:sizeofFloat
     rule numBytes(t(_, double)) => cfg:sizeofDouble
     rule numBytes(t(_, long-double)) => cfg:sizeofLongDouble

     rule numBytes(t(_, unsigned-char)) => numBytes(t(.Set, signed-char))
     rule numBytes(t(_, unsigned-short-int)) => numBytes(t(.Set, short-int))
     rule numBytes(t(_, unsigned-int)) => numBytes(t(.Set, int))
     rule numBytes(t(_, unsigned-long-int)) => numBytes(t(.Set, long-int))
     rule numBytes(t(_, unsigned-long-long-int)) 
          => numBytes(t(.Set, long-long-int))
     
     rule numBytes(t(_, enumType(_:Id))) => cfg:sizeofEnum
     
     rule numBits(t(S:Set, T:SimpleType)) 
          => numBytes(t(S, T)) *Int cfg:bitsPerByte
          when getKLabel(T) =/=KLabel 'bitfieldType
     rule numBits(t(_, bitfieldType(_, N:CSize))) => N

     rule stripConst(t(S:Set, T:SimpleType)) => t((S -Set SetItem(Const)), T)

     rule allowWrite(lval(N:SymLoc, T:Type)) => lv(N, stripConst(T))
          [structural, anywhere]
     
     rule [correspondingUnsigned-int]: 
          correspondingUnsignedType(t(S:Set, int))
          => t(S, unsigned-int)
     rule [correspondingUnsigned-long-int]: 
          correspondingUnsignedType(t(S:Set, long-int))
          => t(S, unsigned-long-int)
     rule [correspondingUnsigned-long-long-int]: 
          correspondingUnsignedType(t(S:Set, long-long-int))
          => t(S, unsigned-long-long-int)

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
          => 0 -Int (2 ^Int absInt(numBits(t(.Set, signed-char)) -Int 1))
     rule max(t(_, signed-char)) 
          => (2 ^Int absInt(numBits(t(.Set, signed-char)) -Int 1)) -Int 1
     rule min(t(_, short-int)) 
          => 0 -Int (2 ^Int absInt(numBits(t(.Set, short-int)) -Int 1))
     rule max(t(_, short-int)) 
          => (2 ^Int absInt(numBits(t(.Set, short-int)) -Int 1)) -Int 1
     rule min(t(_, int)) 
          => 0 -Int (2 ^Int absInt(numBits(t(.Set, int)) -Int 1))
     rule max(t(_, int)) 
          => (2 ^Int absInt(numBits(t(.Set, int)) -Int 1)) -Int 1
     rule min(t(_, long-int)) 
          => 0 -Int (2 ^Int absInt(numBits(t(.Set, long-int)) -Int 1))
     rule max(t(_, long-int)) 
          => (2 ^Int absInt(numBits(t(.Set, long-int)) -Int 1)) -Int 1
     rule min(t(_, long-long-int)) 
          => 0 -Int (2 ^Int absInt(numBits(t(.Set, long-long-int)) -Int 1))
     rule max(t(_, long-long-int)) 
          => (2 ^Int absInt(numBits(t(.Set, long-long-int)) -Int 1)) -Int 1
     
     rule min(t(_, unsigned-char)) => 0
     rule max(t(_, unsigned-char)) 
          => 2 ^Int absInt(numBits(t(.Set, unsigned-char))) -Int 1
     rule min(t(_, unsigned-short-int)) => 0
     rule max(t(_, unsigned-short-int)) 
          => (2 ^Int absInt(numBits(t(.Set, unsigned-short-int)))) -Int 1
     rule min(t(_, unsigned-int)) => 0
     rule max(t(_, unsigned-int)) 
          => (2 ^Int absInt(numBits(t(.Set, unsigned-int)))) -Int 1
     rule min(t(_, unsigned-long-int)) => 0
     rule max(t(_, unsigned-long-int)) 
          => (2 ^Int absInt(numBits(t(.Set, unsigned-long-int)))) -Int 1
     rule min(t(_, unsigned-long-long-int)) => 0
     rule max(t(_, unsigned-long-long-int)) 
          => (2 ^Int absInt(numBits(t(.Set, unsigned-long-long-int)))) -Int 1

     rule min(t(_, enumType(_:Id))) => cfg:enumMin
     rule max(t(_, enumType(_:Id))) => cfg:enumMax

     // Returns both type qualifiers and storage class specifiers.
     rule getModifiers(t(S:Set, _)) => S

     rule getQualifiers(T:Type)
          => intersectSet(getModifiers(T), typeQualifiers)

     rule getStorageSpecifiers(T:Type)
          => intersectSet(getModifiers(T), storageSpecifiers)

     // These are the only actual members "type qualifier" syntactic class.
     syntax Set ::= "typeQualifiers" [function]
     rule typeQualifiers =>
          SetItem(Const)
          SetItem(Restrict)
          SetItem(Volatile)
          SetItem(Atomic)

     syntax Set ::= "storageSpecifiers" [function]
     rule storageSpecifiers =>
          SetItem(Static)
          SetItem(Extern)
          SetItem(Auto)
          SetItem(ThreadLocal)
          SetItem(Register)
          // Also typedef, technically.

     rule unqualifyType(t(Mods:Set, T:SimpleType))
          => t(Mods -Set typeQualifiers, T)
          
     rule stripModifiers(t(_, T:SimpleType)) => t(.Set, T)

     rule stripStorageSpecifiers(t(Mods:Set, T:SimpleType))
          => t(Mods -Set storageSpecifiers, T)

     rule addStorage(S:Storage, t(Mods:Set, T:SimpleType))
          => t(SetItem(S) Mods, T)
          
     rule innerType(t(_, arrayType(T:Type, _))) => T
     rule innerType(t(_, incompleteArrayType(T:Type))) => T
     rule innerType(t(_, flexibleArrayType(T:Type))) => T
     rule innerType(t(_, pointerType(T:Type))) => T
     rule innerType(t(_, bitfieldType(T:Type, _))) => T
     rule innerType(t(_, functionType(T:Type, _))) => T


     rule <k> completeTags(T:Type) => completeTags(Tags, T) ...</k>
          <structs> Tags:Map </structs>
          when Tags =/=Map .Map
     rule <k> completeTags(T:Type) => T ...</k>
          <structs> .Map </structs>

     // TODO(chathhorn): do this in a better way. Keeping all tags in a map and
     // checking it to tell whether a tag has been completed or not was
     // probably the better way to do things.
     rule completeTag(X:Id, Info:FieldInfo, T:Type)
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

     rule completeTags(_ X:Id |-> Info:FieldInfo,
               t(S:Set, incompleteStructType(X:Id)))
          => t(S, structType(X, bitSizeofStruct(Info), Info)) 
     rule completeTags(Tags:Map, t(S:Set, incompleteStructType(X:Id)))
          => t(S, incompleteStructType(X))
          when notBool X in keys Tags
     rule completeTags(X |-> _ Tags:Map, t(S:Set,
               structType(X:Id, NBits:Int,
                    fieldInfo(Decls:List, Types:Map, Offsets:Map))))
          => t(S, structType(X, NBits,
               fieldInfo(
                    completeTagsInList(Tags, Decls),
                    completeTagsInMap(Tags, Types),
                    Offsets)))
     // Don't complete recursive struct definitions.
     rule completeTags(Tags:Map, t(S:Set,
               structType(X:Id, NBits:Int,
                    fieldInfo(Decls:List, Types:Map, Offsets:Map))))
          => t(S, structType(X, NBits,
               fieldInfo(
                    completeTagsInList(Tags, Decls),
                    completeTagsInMap(Tags, Types),
                    Offsets)))
          when notBool (X in keys Tags)

     rule completeTags(_ X:Id |-> Info:FieldInfo,
               t(S:Set, incompleteUnionType(X:Id)))
          => t(S, unionType(X, bitSizeofUnion(Info), Info)) 
     rule completeTags(Tags:Map, t(S:Set, incompleteUnionType(X:Id)))
          => t(S, incompleteUnionType(X))
          when notBool X in keys Tags
     rule completeTags(X |-> _ Tags:Map, t(S:Set,
               unionType(X:Id, NBits:Int,
                    fieldInfo(Decls:List, Types:Map, Offsets:Map))))
          => t(S, unionType(X, NBits,
               fieldInfo(
                    completeTagsInList(Tags, Decls),
                    completeTagsInMap(Tags, Types),
                    Offsets)))
     rule completeTags(Tags:Map, t(S:Set,
               unionType(X:Id, NBits:Int,
                    fieldInfo(Decls:List, Types:Map, Offsets:Map))))
          => t(S, unionType(X, NBits,
               fieldInfo(
                    completeTagsInList(Tags, Decls),
                    completeTagsInMap(Tags, Types),
                    Offsets)))
          when notBool (X in keys Tags)

     rule completeTags(_, t(S:Set, T:SimpleType))
          => t(S, T)
          when (getKLabel(T) =/=KLabel 'bitfieldType)
               andBool (getKLabel(T) =/=KLabel 'functionType )
               andBool (getKLabel(T) =/=KLabel 'pointerType )
               andBool (getKLabel(T) =/=KLabel 'arrayType )
               andBool (getKLabel(T) =/=KLabel 'incompleteArrayType )
               andBool (getKLabel(T) =/=KLabel 'flexibleArrayType )
               andBool (getKLabel(T) =/=KLabel 'incompleteStructType)
               andBool (getKLabel(T) =/=KLabel 'incompleteUnionType)
     // Function parameters.
     rule completeTags(Tags:Map, typedDeclaration(T:Type, X:Id))
          => typedDeclaration(completeTags(Tags, T), X)

     rule completeTagsInList(Tags:Map, ListItem(T:Type) L:List)
          => ListItem(completeTags(Tags, T)) completeTagsInList(Tags, L)
     rule completeTagsInList(_, .List) => .List

     rule completeTagsInMap(Tags:Map, X:Id |-> T:Type M:Map)
          => X |-> completeTags(Tags, T) completeTagsInMap(Tags, M)
     rule completeTagsInMap(_, .Map) => .Map

     rule hasUnionMarker(T:Type) => #hasUnionMarker(T) ==K true

     syntax Bool ::= #hasUnionMarker(Type) [function]
     rule #hasUnionMarker(t((_:Set SetItem(fromUnion(_, _, _)) _:Set), _)) => true
endmodule

