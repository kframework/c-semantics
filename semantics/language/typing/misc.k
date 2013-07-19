module C-TYPING-MISC-SYNTAX
     syntax K ::= "addStruct" "(" Id "," KList ")"
     syntax K ::= "addUnion" "(" Id "," KList ")"
endmodule

module C-TYPING-MISC
     imports C-TYPING-MISC-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-DECLARATION-SYNTAX
     imports C11-SETTINGS-SYNTAX
     imports COMPAT-SYNTAX

     //TODO(chathhorn): a lot of junk dumped here.

     rule isNotTruthValue(tv(V:K, t(_, T:K))) 
          => T:K =/=K int orBool ( V:K =/=K 0 andBool V:K =/=K 1 )
          [structural]

     rule simplifyTruth(K:K) => K:K != tv(0, t(.Set, int))
     
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
     
     rule numBits(t(S:Set, T:K)) 
          => numBytes(t(S:Set, T:K)) *Int cfg:bitsPerByte
          when getKLabel(T:K) =/=KLabel 'bitfieldType
          [structural]
     rule numBits(t(_, bitfieldType(_, N:Int))) => N:Int

     syntax SimpleType ::= simpleType(Type) [function]
     rule simpleType(t(_, T:K)) => T:K

     syntax Type ::= stripConst(Type) [function]
     rule stripConst(t((SetItem(Const) => .Set) _, _))
     rule stripConst(t(S:Set, T:K)) => t(S:Set, T:K)
          when notBool Const in S:Set

     rule allowWrite(lval(N:SymLoc, T:Type)) => lv(N, stripConst(T))
          [structural, anywhere]

     rule isBasicType('t(_,, K:K)) => #if (
          (K:K ==K bool)
          orBool (K:K ==K void)
          orBool (K:K ==K char)
          orBool (K:K ==K short-int)
          orBool (K:K ==K int)
          orBool (K:K ==K long-int)
          orBool (K:K ==K long-long-int)
          orBool (K:K ==K float)
          orBool (K:K ==K double)
          orBool (K:K ==K long-double)
          orBool (K:K ==K signed-char)
          orBool (K:K ==K unsigned-char)
          orBool (K:K ==K unsigned-short-int)
          orBool (K:K ==K unsigned-int)
          orBool (K:K ==K unsigned-long-int)
          orBool (K:K ==K unsigned-long-long-int)
          orBool (K:K ==K no-type)
          orBool (getKLabel(K:K) ==KLabel 'enumType)
          ) #then true #else false #fi

     rule setOfTypes => 
          SetItem(l('arrayType))
          SetItem(l('bitfieldType))
          SetItem(l('functionType))
          SetItem(l('pointerType))
          SetItem(l('structType))
          SetItem(l('unionType))
          SetItem(l('qualifiedType))

     rule unsignedIntegerTypes => 
          SetItem(bool)
          SetItem(unsigned-char)
          SetItem(unsigned-short-int)
          SetItem(unsigned-int)
          SetItem(unsigned-long-int)
          SetItem(unsigned-long-long-int)

     rule signedIntegerTypes => 
          SetItem(char)
          SetItem(signed-char)
          SetItem(short-int)
          SetItem(int)
          SetItem(long-int)
          SetItem(long-long-int)

     rule [hasSameSignedness]: 
          hasSameSignedness(T:KResult, T':KResult)
          => (hasSignedIntegerType(T:KResult)
                    andBool hasSignedIntegerType(T':KResult))
               orBool (hasUnsignedIntegerType(T:KResult)
                    andBool hasUnsignedIntegerType(T':KResult))
     
     rule [correspondingUnsigned-int]: 
          correspondingUnsignedType(t(S:Set, int))
          => t(S:Set, unsigned-int)
     rule [correspondingUnsigned-long-int]: 
          correspondingUnsignedType(t(S:Set, long-int))
          => t(S:Set, unsigned-long-int)
     rule [correspondingUnsigned-long-long-int]: 
          correspondingUnsignedType(t(S:Set, long-long-int))
          => t(S:Set, unsigned-long-long-int)
     rule hasIntegerType(T:Type) 
          => ((hasUnsignedIntegerType(T) ==K true) 
               orBool (hasSignedIntegerType(T) ==K true))
          [structural]
     
     rule hasUnsignedIntegerType(t(_, T:K)) => true
          when (T in unsignedIntegerTypes)
          [structural]
     rule hasUnsignedIntegerType(t(_, T:K)) => false
          when (T in signedIntegerTypes)
          [structural]

     rule hasUnsignedIntegerType(t(S:Set, T:K)) => false
          when (getKLabel(T:K) =/=KLabel 'bitfieldType)
               andBool ((l(getKLabel(T:K)) in setOfTypes) 
                    orBool isFloatType(t(S:Set, T:K)))
          [structural]
     rule hasUnsignedIntegerType(t(_, bitfieldType(T:Type, _:Int))) => true
          when hasUnsignedIntegerType(T) ==Bool true
          [structural]
     rule hasUnsignedIntegerType(t(_, bitfieldType(T:Type, _:Int))) => false
          when hasUnsignedIntegerType(T) ==Bool false
          [structural]
     
     rule hasSignedIntegerType(t(_, T:K)) => true
          when (T in signedIntegerTypes)
          [structural]
     rule hasSignedIntegerType(t(_, T:K)) => false
          when (T in unsignedIntegerTypes)
          [structural]

     rule hasSignedIntegerType(t(_, enumType(_:Id))) => true // choice fixme
     rule hasSignedIntegerType(t(S:Set, T:K)) => false
          when (getKLabel(T:K) =/=KLabel 'bitfieldType)
               andBool ((l(getKLabel(T:K)) in setOfTypes) 
                    orBool isFloatType(t(S:Set, T:K)))
          [structural]
     rule hasSignedIntegerType(t(_, bitfieldType(T:Type, _:Int))) => true
          when hasSignedIntegerType(T) ==Bool true
          [structural]
     rule hasSignedIntegerType(t(_, bitfieldType(T:Type, _:Int))) => false
          when hasSignedIntegerType(T) ==Bool false
          [structural]

     rule min(t(_, bitfieldType(T:Type, _:Int))) => 0
          when hasUnsignedIntegerType(T)
          [structural]
     rule max(t(_, bitfieldType(T:Type, N:Int))) 
          => (2 ^Int absInt(N:Int)) -Int 1
          when hasUnsignedIntegerType(T)
          [structural]
     
     rule min(t(_, bitfieldType(T:Type, N:Int)))
          => 0 -Int (2 ^Int absInt(N:Int -Int 1))
          when hasSignedIntegerType(T)
          [structural]
     rule max(t(_, bitfieldType(T:Type, N:Int)))
          => (2 ^Int absInt(N:Int -Int 1)) -Int 1
          when hasSignedIntegerType(T)
          [structural]

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
     
     /*@ \fromStandard{\source[n1570]{\para{6.2.7}{1}}}{
     Two types have compatible type if their types are the same. Additional
     rules for determining whether two types are compatible are described in
     6.7.2 for type specifiers, in 6.7.3 for type qualifiers, and in 6.7.6 for
     declarators.  Moreover, two structure, union, or enumerated types declared
     in separate translation units are compatible if their tags and members
     satisfy the following requirements: If one is declared with a tag, the
     other shall be declared with the same tag. If both are completed anywhere
     within their respective translation units, then the following additional
     requirements apply: there shall be a one-to-one correspondence between
     their members such that each pair of corresponding members are declared
     with compatible types; if one member of the pair is declared with an
     alignment specifier, the other is declared with an equivalent alignment
     specifier; and if one member of the pair is declared with a name, the
     other is declared with the same name. For two structures, corresponding
     members shall be declared in the same order. For two structures or unions,
     corresponding bit-fields shall have the same widths. For two enumerations,
     corresponding members shall have the same values.
     
     \source[n1570]{\para{6.7.3}{10}}
     For two qualified types to be compatible, both shall have the identically
     qualified version of a compatible type; the order of type qualifiers
     within a list of specifiers or qualifiers does not affect the specified
     type.
     }*/
     
     rule [typeCompatible-identical]:
          isTypeCompatible(T:KResult, T:KResult) => true 
          [structural]
     rule [typeCompatible-two-ints]:
          isTypeCompatible(T:KResult, T':KResult) => true 
          when hasIntegerType(T:KResult)
               andBool hasIntegerType(T':KResult) 
          [structural]
     rule [typeCompatible-two-ptr]:
          isTypeCompatible(t(_, pointerType(_)), t(_, pointerType(_))) => true 
          [structural]
     rule [typeCompatible-ptr-int]:
          isTypeCompatible(t(_, pointerType(_)), T:KResult) => true
          when hasIntegerType(T:KResult) 
          [structural]
     rule [typeCompatible-int-ptr]:
          isTypeCompatible(T:KResult, t(_, pointerType(_))) => true
          when hasIntegerType(T:KResult)
          [structural]
          
     rule [typeCompatible-declarations]:
          isTypeCompatible(typedDeclaration(T:KResult, _:Id), 
               typedDeclaration(T':KResult, _:Id))
          => isTypeCompatible(T:KResult, T':KResult) 
          [structural]
     rule [typeCompatible-prototypes]:
          isTypeCompatible(t(_, prototype(T:KResult)), t(_, prototype(T':KResult))) 
          => isTypeCompatible(T:KResult, T':KResult) 
          [structural]

     rule [typeCompatible-array-right]:
          isTypeCompatible(T:KResult, t(S:Set, arrayType(T':KResult, _:Int)))
          => isTypeCompatible(T:KResult, t(S:Set, pointerType(T':KResult))) 
          [structural]
     rule [typeCompatible-array-left]:
          isTypeCompatible(t(S:Set, arrayType(T:KResult, _:Int)), T':KResult)
          => isTypeCompatible(t(S:Set, pointerType(T:KResult)), T':KResult) 
          [structural]
     
     rule [typeCompatible-incompleteArray-right]:
          isTypeCompatible(T:KResult, t(S:Set, incompleteArrayType(T':KResult)))
          => isTypeCompatible(T:KResult, t(S:Set, pointerType(T':KResult))) 
          [structural]
     rule [typeCompatible-incompleteArray-left]:
          isTypeCompatible(t(S:Set, incompleteArrayType(T:KResult)), T':KResult)
          => isTypeCompatible(t(S:Set, pointerType(T:KResult)), T':KResult) 
          [structural]

     rule [typeCompatible-function-void-left]:
          isTypeCompatible(t(_, functionType(T1:KResult, 
               typedDeclaration(t(_, void), _:Id))),
               t(_, functionType(T2:KResult, .KList)))
          => isTypeCompatible(T1:KResult, T2:KResult) 
          [structural]
     rule [typeCompatible-function-void-right]:
          isTypeCompatible(t(_, functionType(T1:KResult, .KList)),
               t(_, functionType(T2:KResult, 
               typedDeclaration(t(_, void), _:Id))))
          => isTypeCompatible(T1:KResult, T2:KResult) 
          [structural]
     rule [typeCompatible-function]:
          isTypeCompatible(t(S:Set, functionType(T1:KResult, 
               (T':KResult,, L:KList))),
               t(S':Set, functionType(T2:KResult, (T'':KResult,, L':KList))))
          => isTypeCompatible(t(S:Set, functionType(T1:KResult, L:KList)),
               t(S':Set, functionType(T2:KResult, L':KList)))
               andBool isTypeCompatible(T':KResult, T'':KResult) 
          [structural]
     rule [typeCompatible-incompleteArray-nil]:
          isTypeCompatible(t(_, functionType(T1:KResult, .KList)),
               t(_, functionType(T2:KResult, .KList)))
          => isTypeCompatible(T1:KResult, T2:KResult) 
          [structural]
     rule isTypeCompatible(T:KResult, T':KResult) => true
          when (hasIntegerType(T:KResult) orBool isFloatType(T:KResult))
               andBool (hasIntegerType(T':KResult) orBool isFloatType(T':KResult)) 
          [structural]
               
     syntax K ::= "addGlobalAggregate" "(" Id "," K ")"
     syntax K ::= "addLocalAggregate" "(" Id "," K ")"
     
     syntax K ::= "addStruct-aux" "(" Id "," KList "," K "," Map "," Map "," KList ")"
          [strict(3)]
     syntax K ::= "addUnion-aux" "(" Id "," KList "," Map "," Map "," KList ")"

     // TODO(chathhorn): why the hell was this necessary? this has got to be a
     // BUG.
     rule addStruct-aux(A:Id, B:KList, K:K, C:Map, D:Map, E:KList) 
          => K ~> addStruct-aux(A, B, HOLE, C, D, E) [heat]
     rule K:KResult ~> addStruct-aux(A:Id, B:KList, HOLE, C:Map, D:Map, E:KList)
          => addStruct-aux(A, B, K, C, D, E) [cool]

     rule addStruct(S:Id, L:KList) 
          => addStruct-aux(S:Id, L:KList,
               tv(0, cfg:largestUnsigned), .Map, .Map, L:KList)
          when L:KList =/=KList .KList
          [structural]
     rule addStruct-aux(
               S:Id
               , (typedDeclaration(T:KResult, Field:Id),, L:KList)
               , V:KResult
               , Types:Map
               , Offsets:Map
               , L':KList
          ) 
          => addStruct-aux(S, L, V + bitSizeofType(T:KResult),
               Types:Map[T / Field], Offsets:Map[value(V) / Field], L')
          [structural]
     rule <k> 
               addStruct-aux(S:Id, .KList, _, Types:Map, Offsets:Map, L:KList) 
               => #if (F:Id ==K file-scope) 
                    #then (addGlobalAggregate(S, 
                         aggregateInfo(L, Types, Offsets))) 
                    #else (addLocalAggregate(S, 
                         aggregateInfo(L, Types, Offsets)))
                    #fi
          ...</k>
          <currentFunction> F:Id </currentFunction>
          [structural]        
          
     rule addUnion(S:Id, L:KList) 
          => addUnion-aux(S:Id, L:KList, .Map, .Map, L:KList)
          when L:KList =/=KList .KList
          [structural]
     rule addUnion-aux(
               S:Id
               , (typedDeclaration(T:KResult, Field:Id),, L:KList)
               , Types:Map
               , Offsets:Map
               , L':KList
          ) 
          => addUnion-aux(S:Id, L,
               Types:Map[T:KResult / Field:Id], Offsets:Map[0 / Field:Id],
               L':KList)
          [structural]
     rule <k> 
               addUnion-aux(S:Id, .KList, Types:Map, Offsets:Map, L:KList) 
               => #if (F:Id ==K file-scope)
                    #then (addGlobalAggregate(S:Id,
                         aggregateInfo(L, Types:Map, Offsets:Map))) 
                    #else (addLocalAggregate(S:Id,
                         aggregateInfo(L, Types:Map, Offsets:Map)))
                    #fi
          ...</k>
          <currentFunction> F:Id </currentFunction>
          [structural]

     rule <k> addGlobalAggregate(X:Id, K:K) => . ...</k>
          <structs> M':Map => M':Map[K:K / X:Id] </structs>
          <gstructs> M:Map => M:Map[K:K / X:Id] </gstructs>
          [structural]
     rule <k> addLocalAggregate(X:Id, K:K) => . ...</k>
          <structs> M:Map => M:Map[K:K / X:Id] </structs>
          [structural]
          
     rule isFloatType(t(_, float)) => true 
     rule isFloatType(t(_, double)) => true 
     rule isFloatType(t(_, long-double)) => true 
     rule isFloatType(t(_, T:K)) => false
          when (T:K =/=K float)
               andBool (T:K =/=K double)
               andBool (T:K =/=K long-double)
               andBool (getKLabel(T:K) =/=KLabel 'qualifiedType)
          
     rule [isCharType-char]: isCharType(t(_, char)) => true 
     rule [isCharType-qualified]:
          isCharType(t(_, qualifiedType(T:KResult, _)))
          => isCharType(T:KResult) 
     rule [isCharType-unsigned-char]: isCharType(t(_, unsigned-char)) => true 
     rule [isCharType-signed-char]: isCharType(t(_, signed-char)) => true 
     rule [isCharType-other]: isCharType(t(_, T:K)) => false
          when (T:K =/=K char)
               andBool (T:K =/=K unsigned-char)
               andBool (T:K =/=K signed-char)
               andBool (getKLabel(T:K) =/=KLabel 'qualifiedType)
          
     rule [isWCharType-wchar]: isWCharType(t(_, T:K)) => true 
          when T:K ==K simpleType(cfg:wcharut)
          
     rule [isWCharType-other]: isWCharType(t(_, T:K)) => false
          when (T:K =/=K simpleType(cfg:wcharut))
               andBool (getKLabel(T:K) =/=KLabel 'qualifiedType )
          
     rule [isWCharType-qualified]:
          isWCharType(t(_, qualifiedType(T:KResult, _)))
          => isWCharType(T:KResult) 
     
     rule [isPointerType-pointer]: isPointerType(t(_, pointerType(_))) => true 
     rule [isPointerType-qualified]:
          isPointerType(t(_, qualifiedType(T:KResult, _)))
          => isPointerType(T:KResult) 
     rule [isPointerType-other]: isPointerType(t(_, T:K)) => false
          when (getKLabel(T:K) =/=KLabel 'pointerType)
               andBool (getKLabel(T:K) =/=KLabel 'qualifiedType)
          
     
     rule [isBoolType-bool]: isBoolType(t(_, bool)) => true 
     rule [isBoolType-qualifiedType]:
          isBoolType(t(_, qualifiedType(T:KResult, _)))
          => isBoolType(T:KResult) 
     rule [isBoolType-other]: isBoolType(t(_, T:K)) => false
          when (T:K =/=K bool)
               andBool (getKLabel(T:K) =/=KLabel 'qualifiedType)
          
     rule [isArrayType-array]: isArrayType(t(_, arrayType(_, _:Int))) => true 
     rule [isArrayType-incompleteArray]:
          isArrayType(t(_, incompleteArrayType(_)))
          => true 
     rule [isArrayType-flexibleArray]:
          isArrayType(t(_, flexibleArrayType(_)))
          => true 
     rule [isArrayType-qualified]:
          isArrayType(t(_, qualifiedType(T:KResult, _)))
          => isArrayType(T:KResult) 
     rule [isArrayType-other]: isArrayType(t(_, T:K)) => false
          when (getKLabel(T:K) =/=KLabel 'arrayType)
               andBool (getKLabel(T:K) =/=KLabel 'incompleteArrayType)
               andBool (getKLabel(T:K) =/=KLabel 'flexibleArrayType)
               andBool (getKLabel(T:K) =/=KLabel 'qualifiedType)
          
     rule isAggregateType(T:Type)
          => isArrayType(T) orBool isStructType(T) 
          
     rule [isStructType-struct]:
          isStructType(t(_, structType(_:Id))) => true 
     rule [isStructType-qualified]:
          isStructType(t(_, qualifiedType(T:KResult, _)))
          => isStructType(T:KResult) 
     rule [isStructType-other]: isStructType(t(_, T:K)) => false
          when (getKLabel(T:K) =/=KLabel 'structType)
               andBool (getKLabel(T:K) =/=KLabel 'qualifiedType )
          
     rule [isUnionType-union]: isUnionType(t(_, unionType(_:Id))) => true 
     rule [isUnionType-qualified]:
          isUnionType(t(_, qualifiedType(T:KResult, _)))
          => isUnionType(T:KResult) 
     rule [isUnionType-other]: isUnionType(t(_, T:K)) => false
          when (getKLabel(T:K) =/=KLabel 'unionType)
               andBool (getKLabel(T:K) =/=KLabel 'qualifiedType )

     rule [isIncompleteType-true]:
          isIncompleteType(t(_, incompleteArrayType(_)))
          => true 
     rule [isIncompleteType-qualified]:
          isIncompleteType(t(_, qualifiedType(T:KResult, _)))
          => isIncompleteType(T:KResult) 
     rule [isIncompleteType-false]: isIncompleteType(t(_, T:K)) => false
          when (getKLabel(T:K) =/=KLabel 'incompleteArrayType)
               andBool (getKLabel(T:K) =/=KLabel 'qualifiedType )
          
     rule [isExternType-qualified]: 
          isExternType(t(_, qualifiedType(T:KResult, K:K))) 
          => #if (K:K ==K Extern) #then (true) #else (isExternType(T:KResult)) #fi 
          
     rule [isExternType-false]: isExternType(t(_, T:K)) => false
          when getKLabel(T:K) =/=KLabel 'qualifiedType 
          
     rule [isStaticType-qualified]: 
          isStaticType(t(_, qualifiedType(T:KResult, K:K))) 
          => #if (K:K ==K Static) #then (true) #else (isStaticType(T:KResult)) #fi
          
     rule [isStaticType-false]: isStaticType(t(_, T:K)) => false
          when getKLabel(T:K) =/=KLabel 'qualifiedType 
          
     rule [isConstType-qualified]: 
          isConstType(t(_, qualifiedType(T:KResult, _:K)))
          => isConstType(T:KResult)
          
     rule [isConstType-false]: 
          isConstType(t(S:Set, T:K)) => false
          when (getKLabel(T:K) =/=KLabel 'qualifiedType )
               andBool (notBool Const in S:Set)
          
     rule [isConstType-true]: 
          isConstType(t(SetItem(Const) _, _:K)) => true
          
     rule [isBitfieldType-true]:
          isBitfieldType(t(_, bitfieldType(_, _:Int))) => true 
     rule [isBitfieldType-false]: isBitfieldType(t(_, T:K)) => false
          when getKLabel(T:K) =/=KLabel 'bitfieldType
          
     rule [isFunctionType-true]:
          isFunctionType(t(_, functionType(_, _:KList)))
          => true 
     rule [isFunctionType-prototype]:
          isFunctionType(t(_, prototype(T:KResult)))
          => isFunctionType(T:KResult) 
     rule [isFunctionType-qualified]:
          isFunctionType(t(_, qualifiedType(T:KResult, _)))
          => isFunctionType(T:KResult) 
     rule [isFunctionType-false]: isFunctionType(t(_, T:K)) => false
          when (getKLabel(T:K) =/=KLabel 'functionType)
               andBool (getKLabel(T:K) =/=KLabel 'qualifiedType)
               andBool (getKLabel(T:K) =/=KLabel 'prototype)
          
     rule [isFunctionPointerType-fp]:
          isFunctionPointerType(t(_, pointerType(t(_,
               functionType(_, _:KList)))))
          => true 
     rule [isFunctionPointerType-qualified]:
          isFunctionPointerType(t(_, qualifiedType(T:KResult, _)))
          => isFunctionPointerType(T:KResult) 
     rule [isFunctionPointerType-qualified-pointer]: 
          isFunctionPointerType(t(_, pointerType(t(_,
               qualifiedType(T:KResult, _))))) 
          => isFunctionPointerType(t(.Set, pointerType(T))) 
     rule [isFunctionPointerType-notPointer]:
          isFunctionPointerType(t(_, T:K))
          => false
          when (getKLabel(T:K) =/=KLabel 'pointerType)
               andBool (getKLabel(T:K) =/=KLabel 'qualifiedType)
          
     rule [isFunctionPointerType-notFunction]:
          isFunctionPointerType(t(_, pointerType(t(_, T:K))))
          => false
          when (getKLabel(T:K) =/=KLabel 'functionType)
               andBool (getKLabel(T:K) =/=KLabel 'qualifiedType)
          
     // /*@ \source[n1570]{\para{6.2.5}{18}}
     // Integer and floating types are collectively called arithmetic types.
     // Each arithmetic type belongs to one type domain: the real type domain
     // comprises the real types, the complex type domain comprises the complex
     // types. 
     // */
     rule isArithmeticType(T:KResult)
          => hasIntegerType(T:KResult) orBool isFloatType(T:KResult)

     rule unqualifyType(t(_:Set, qualifiedType(T:KResult, _))) => T:KResult 
     rule unqualifyType(t(_:Set, T:K)) => t(.Set, T:K)
          when getKLabel(T:K) =/=KLabel 'qualifiedType 
          
     rule removeStorageSpecifiers(t(_:Set, qualifiedType(T:KResult, _)))
          => T:KResult 
     rule removeStorageSpecifiers(t(S:Set, T:K)) => t(S:Set, T:K)
          when getKLabel(T:K) =/=KLabel 'qualifiedType
          
     rule getModifiers(t(S:Set, _)) => S:Set
endmodule

