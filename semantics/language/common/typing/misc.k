module C-TYPING-MISC-SYNTAX
     syntax K ::= addStruct(Id, List)
     syntax K ::= addUnion(Id, List)
endmodule

module C-TYPING-MISC
     imports C-TYPING-MISC-SYNTAX
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
     
     syntax K ::= addGlobalAggregate(Id, K)
                | addLocalAggregate(Id, K)
     
     syntax K ::= "addStruct-aux" "(" Id "," List "," K "," Map "," Map "," List ")"
          [strict(3)]
     syntax K ::= "addUnion-aux" "(" Id "," List "," Map "," Map "," List ")"

     rule addStruct(S:Id, L:List) 
          => addStruct-aux(S:Id, L:List,
               tv(0, cfg:largestUnsigned), .Map, .Map, L:List)
          when L:List =/=List .List
          [structural]
     rule addStruct-aux(
               S:Id
               , ListItem(typedDeclaration(T:Type, Field:Id)) L:List
               , V:TypedValue
               , Types:Map
               , Offsets:Map
               , L':List
          ) 
          => addStruct-aux(S, L, V + bitSizeofType(T),
               Types:Map[T / Field], Offsets:Map[value(V) / Field], L')
          [structural]
     rule <k> addStruct-aux(S:Id, .List, _, Types:Map, Offsets:Map, L:List) 
               => #if (F:Id ==K file-scope)
                    #then (addGlobalAggregate(S, 
                         aggInfo(L, Types, Offsets))) 
                    #else (addLocalAggregate(S, 
                         aggInfo(L, Types, Offsets)))
                    #fi
          ...</k>
          <curr-function> F:Id </curr-function>
          [structural]        
          
     rule addUnion(S:Id, L:List) 
          => addUnion-aux(S:Id, L:List, .Map, .Map, L:List)
          when L:List =/=List .List
          [structural]
     rule addUnion-aux(
               S:Id
               , ListItem(typedDeclaration(T:Type, Field:Id)) L:List
               , Types:Map
               , Offsets:Map
               , L':List
          ) 
          => addUnion-aux(S, L,
               Types:Map[T / Field], Offsets:Map[0 / Field],
               L')
          [structural]
     rule <k> 
               addUnion-aux(S:Id, .List, Types:Map, Offsets:Map, L:List) 
               => #if (F ==K file-scope)
                    #then (addGlobalAggregate(S,
                         aggInfo(L, Types, Offsets))) 
                    #else (addLocalAggregate(S,
                         aggInfo(L, Types, Offsets)))
                    #fi
          ...</k>
          <curr-function> F:Id </curr-function>
          [structural]

     // TODO(chathhorn): should move this elsewhere.
     rule <k> addGlobalAggregate(X:Id, Agg:AggInfo) => . ...</k>
          <structs> M':Map => M':Map[Agg / X] </structs>
          <gstructs> M:Map => M:Map[Agg / X] </gstructs>
          [structural]
     rule <k> addLocalAggregate(X:Id, Agg:AggInfo) => . ...</k>
          <structs> M:Map => M:Map[Agg / X] </structs>
          [structural]

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
endmodule

