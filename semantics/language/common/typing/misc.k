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

     syntax Type ::= stripConst(Type) [function]

     rule stripConst(t(S:Set, qualifiedType(T:Type, K:K))) 
          => t((S -Set SetItem(Const)), qualifiedType(stripConst(T), K))
     rule stripConst(t(S:Set, T:SimpleType)) => t((S -Set SetItem(Const)), T)
          when getKLabel(T) =/=KLabel 'qualifiedType

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
     rule getQualities(t(S:Set, qualifiedType(T:Type, K:K))) 
          => S SetItem(K) getQualities(T)
     rule getQualities(t(S:Set, T:SimpleType)) => S
          when (getKLabel(T) =/=KLabel 'qualifiedType)

     syntax Set ::= "getQualifiers'" "(" Type ")" [function]
     rule getQualifiers(T:Type) => SetItem(Const) getQualifiers'(T)
          when isConstType(T)
     rule getQualifiers(T:Type) => getQualifiers'(T)
          when notBool isConstType(T)

     rule getQualifiers'(t(_, qualifiedType(T:Type, K:K))) 
          => SetItem(K) getQualifiers'(T)
          when K in typeQualifiers
     rule getQualifiers'(t(_, qualifiedType(T:Type, K:K))) 
          => getQualifiers'(T)
          when notBool (K in typeQualifiers)
     rule getQualifiers'(t(_, T:SimpleType)) => .Set
          when (getKLabel(T) =/=KLabel 'qualifiedType)

     // These are the only actual members "type qualifier" syntactic class.
     syntax Set ::= "typeQualifiers" [function]
     rule typeQualifiers =>
          SetItem(Const)
          SetItem(Restrict)
          SetItem(Volatile)
          SetItem(Atomic)

     // TODO(chathhorn): probably poorly named.
     rule unqualifyType(t(_, qualifiedType(T:Type, _))) 
          => unqualifyType(T)
     rule unqualifyType(t(_, T:SimpleType)) => t(.Set, T)
          when getKLabel(T) =/=KLabel 'qualifiedType
          
     // TODO(chathhorn): doesn't do exactly what it claims to. It does the
     // same thing as unqualifyType, but I guess it leaves Const alone.
     rule removeStorageSpecifiers(t(_, qualifiedType(T:Type, _)))
          => removeStorageSpecifiers(T)
     rule removeStorageSpecifiers(t(S:Set, T:SimpleType)) => t(S, T)
          when getKLabel(T) =/=KLabel 'qualifiedType
          
     rule getModifiers(t(S:Set, _)) => S
          
     rule [innerType-arrayType]:
          innerType(t(_, arrayType(T:Type, _))) => T
     rule [innerType-incompleteArrayType]: 
          innerType(t(_, incompleteArrayType(T:Type))) => T
     rule [innerType-flexibleArrayType]: 
          innerType(t(_, flexibleArrayType(T:Type))) => T
     rule [innerType-qualifiedType]:
          innerType(t(_, qualifiedType(T:Type, _))) => innerType(T)
     rule [innerType-pointerType]:
          innerType(t(_, pointerType(T:Type))) => T
     rule [innerType-bitfieldType]:
          innerType(t(_, bitfieldType(T:Type, _))) => T
     rule [innerType-functionType]:
          innerType(t(_, functionType(T:Type, _))) => T

     // TODO(chathhorn): should probably generalize this.
     rule completeAgg(X:Id, NBits:Int, Info:AggInfo, t(S:Set, bitfieldType(T:Type, Sz:CSize)))
          => t(S, bitfieldType(completeAgg(X, NBits, Info, T), Sz))
     rule completeAgg(X:Id, NBits:Int, Info:AggInfo, t(S:Set, functionType(R:Type, Args:List)))
          => t(S, functionType(completeAgg(X, NBits, Info, R), completeAggInList(X, NBits, Info, Args)))
     rule completeAgg(X:Id, NBits:Int, Info:AggInfo, t(S:Set, pointerType(T:Type)))
          => t(S, pointerType(completeAgg(X, NBits, Info, T)))
     rule completeAgg(X:Id, NBits:Int, Info:AggInfo, t(S:Set, arrayType(T:Type, Sz:CSize)))
          => t(S, arrayType(completeAgg(X, NBits, Info, T), Sz))
     rule completeAgg(X:Id, NBits:Int, Info:AggInfo, t(S:Set, incompleteArrayType(T:Type)))
          => t(S, incompleteArrayType(completeAgg(X, NBits, Info, T)))
     rule completeAgg(X:Id, NBits:Int, Info:AggInfo, t(S:Set, flexibleArrayType(T:Type)))
          => t(S, flexibleArrayType(completeAgg(X, NBits, Info, T)))
     rule completeAgg(X:Id, NBits:Int, Info:AggInfo, t(S:Set, incompleteStructType(X)))
          => t(S, structType(X, NBits, Info)) 
     rule completeAgg(X:Id, NBits:Int, Info:AggInfo, t(S:Set, incompleteUnionType(X)))
          => t(S, unionType(X, NBits, Info)) 
     rule completeAgg(X:Id, NBits:Int, Info:AggInfo, t(S:Set, qualifiedType(T:Type, K:K)))
          => t(S, qualifiedType(completeAgg(X, NBits, Info, T), K))
     rule completeAgg(_, _, _, t(S:Set, T:SimpleType))
          => t(S, T)
          when (getKLabel(T) =/=KLabel 'bitfieldType)
               andBool (getKLabel(T) =/=KLabel 'functionType )
               andBool (getKLabel(T) =/=KLabel 'pointerType )
               andBool (getKLabel(T) =/=KLabel 'arrayType )
               andBool (getKLabel(T) =/=KLabel 'incompleteArrayType )
               andBool (getKLabel(T) =/=KLabel 'flexibleArrayType )
               andBool (getKLabel(T) =/=KLabel 'incompleteStructType)
               andBool (getKLabel(T) =/=KLabel 'incompleteUnionType)
               andBool (getKLabel(T) =/=KLabel 'qualifiedType )

     syntax List ::= completeAggInList(Id, Int, AggInfo, List) [function]
     rule completeAggInList(X:Id, NBits:Int, Info:AggInfo, ListItem(T:Type) L:List)
          => ListItem(completeAgg(X, NBits, Info, T)) completeAggInList(X, NBits, Info, L)
     rule completeAggInList(_, _, _, .List) => .List

endmodule

