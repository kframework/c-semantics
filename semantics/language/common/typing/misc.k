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
     rule numBits(t(_, bitfieldType(_, N:Int))) => N:Int

     syntax SimpleType ::= simpleType(Type) [function]
     rule simpleType(t(_, T:SimpleType)) => T

     syntax Type ::= stripConst(Type) [function]

     rule stripConst(t(S:Set, qualifiedType(T:Type, K:K))) 
          => t((S -Set SetItem(Const)), qualifiedType(stripConst(T), K))
     rule stripConst(t(S:Set, T:SimpleType)) => t((S -Set SetItem(Const)), T)
          when getKLabel(T) =/=KLabel 'qualifiedType

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
          hasSameSignedness(T:Type, T':Type)
          => (hasSignedIntegerType(T) andBool hasSignedIntegerType(T'))
               orBool 
               (hasUnsignedIntegerType(T) andBool hasUnsignedIntegerType(T'))
     
     rule [correspondingUnsigned-int]: 
          correspondingUnsignedType(t(S:Set, int))
          => t(S, unsigned-int)
     rule [correspondingUnsigned-long-int]: 
          correspondingUnsignedType(t(S:Set, long-int))
          => t(S, unsigned-long-int)
     rule [correspondingUnsigned-long-long-int]: 
          correspondingUnsignedType(t(S:Set, long-long-int))
          => t(S, unsigned-long-long-int)
     rule hasIntegerType(T:Type) 
          => ((hasUnsignedIntegerType(T) ==K true) 
               orBool (hasSignedIntegerType(T) ==K true))
     
     rule hasUnsignedIntegerType(t(_, T:SimpleType)) => true
          when (T in unsignedIntegerTypes)
     rule hasUnsignedIntegerType(t(_, T:SimpleType)) => false
          when (T in signedIntegerTypes)

     rule hasUnsignedIntegerType(t(S:Set, T:SimpleType)) => false
          when (getKLabel(T) =/=KLabel 'bitfieldType)
               andBool ((l(getKLabel(T)) in setOfTypes) 
                    orBool isFloatType(t(S, T)))
     rule hasUnsignedIntegerType(t(_, bitfieldType(T:Type, _:Int))) => true
          when hasUnsignedIntegerType(T) ==Bool true
     rule hasUnsignedIntegerType(t(_, bitfieldType(T:Type, _:Int))) => false
          when hasUnsignedIntegerType(T) ==Bool false
     
     rule hasSignedIntegerType(t(_, T:SimpleType)) => true
          when (T in signedIntegerTypes)
     rule hasSignedIntegerType(t(_, T:SimpleType)) => false
          when (T in unsignedIntegerTypes)

     rule hasSignedIntegerType(t(_, enumType(_:Id))) => true // choice fixme
     rule hasSignedIntegerType(t(S:Set, T:SimpleType)) => false
          when (getKLabel(T) =/=KLabel 'bitfieldType)
               andBool ((l(getKLabel(T)) in setOfTypes) 
                    orBool isFloatType(t(S, T)))
     rule hasSignedIntegerType(t(_, bitfieldType(T:Type, _:Int))) => true
          when hasSignedIntegerType(T) ==Bool true
     rule hasSignedIntegerType(t(_, bitfieldType(T:Type, _:Int))) => false
          when hasSignedIntegerType(T) ==Bool false

     rule min(t(_, bitfieldType(T:Type, _:Int))) => 0
          when hasUnsignedIntegerType(T)
     rule max(t(_, bitfieldType(T:Type, N:Int))) 
          => (2 ^Int absInt(N:Int)) -Int 1
          when hasUnsignedIntegerType(T)
     
     rule min(t(_, bitfieldType(T:Type, N:Int)))
          => 0 -Int (2 ^Int absInt(N:Int -Int 1))
          when hasSignedIntegerType(T)
     rule max(t(_, bitfieldType(T:Type, N:Int)))
          => (2 ^Int absInt(N:Int -Int 1)) -Int 1
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

     syntax Bool ::= "#isCompat" "(" Type "," Type ")" [function]

     rule isTypeCompatible(T1:Type, T2:Type) 
          => #isCompat(T1, T2) ==K true
     
     rule [typeCompatible-identical]:
          #isCompat(T:Type, T:Type) => true 
     rule [typeCompatible-two-ints]:
          #isCompat(T:Type, T':Type) => true 
          when hasIntegerType(T)
               andBool hasIntegerType(T') 
     rule [typeCompatible-two-ptr]:
          #isCompat(t(_, pointerType(_)), t(_, pointerType(_))) => true 
     rule [typeCompatible-ptr-int]:
          #isCompat(t(_, pointerType(_)), T:Type) => true
          when hasIntegerType(T) 
     rule [typeCompatible-int-ptr]:
          #isCompat(T:Type, t(_, pointerType(_))) => true
          when hasIntegerType(T)
          
     rule [typeCompatible-declarations]:
          #isCompat(typedDeclaration(T:Type, _:Id), 
               typedDeclaration(T':Type, _:Id))
          => #isCompat(T, T') 

     rule [typeCompatible-array-right]:
          #isCompat(T:Type, t(S:Set, arrayType(T':Type, _:Int)))
          => #isCompat(T, t(S:Set, pointerType(T'))) 
     rule [typeCompatible-array-left]:
          #isCompat(t(S:Set, arrayType(T:Type, _:Int)), T':Type)
          => #isCompat(t(S, pointerType(T)), T') 
     
     rule [typeCompatible-incompleteArray-right]:
          #isCompat(T:Type, t(S:Set, incompleteArrayType(T':Type)))
          => #isCompat(T, t(S, pointerType(T'))) 
     rule [typeCompatible-incompleteArray-left]:
          #isCompat(t(S:Set, incompleteArrayType(T:Type)), T':Type)
          => #isCompat(t(S, pointerType(T)), T') 

     // A function declaration with no arguments is compatible with a
     // declaration with any number of arguments.
     rule [typeCompatible-function-void]:
          #isCompat(
               t(_, functionType(T:Type, Args:KList)),
               t(_, functionType(T':Type, Args':KList)))
          => #isCompat(T, T') 
          when (Args ==KList .KList) orBool (Args' ==KList .KList)
     rule [typeCompatible-function]:
          #isCompat(
               t(S:Set,  functionType(T:Type,  (TA:Type,,  L:KList))),
               t(S':Set, functionType(T':Type, (TA':Type,, L':KList))))
          => #isCompat(t(S, functionType(T, L)), 
               t(S', functionType(T', L')))
               andBool #isCompat(TA, TA') 
     rule [typeCompatible-function-nil]:
          #isCompat(t(_, functionType(T:Type, .KList)),
               t(_, functionType(T':Type, .KList)))
          => #isCompat(T, T') 
     // TODO(chathhorn): why was this here??
     // rule #isCompat(T:Type, T':Type) => true
     //      when (hasIntegerType(T) orBool isFloatType(T))
     //           andBool (hasIntegerType(T') orBool isFloatType(T')) 
               
     syntax K ::= addGlobalAggregate(Id, K)
                | addLocalAggregate(Id, K)
     
     syntax K ::= "addStruct-aux" "(" Id "," KList "," K "," Map "," Map "," KList ")"
          [strict(3)]
     syntax K ::= "addUnion-aux" "(" Id "," KList "," Map "," Map "," KList ")"

     // TODO(chathhorn): should be able to use context here (bug?).
     rule addStruct-aux(A:Id, B:KList, K:K, C:Map, D:Map, E:KList) 
          => K ~> addStruct-aux(A, B, HOLE, C, D, E) [heat]
     rule K:K ~> addStruct-aux(A:Id, B:KList, HOLE, C:Map, D:Map, E:KList)
          => addStruct-aux(A, B, K, C, D, E) [cool]

     rule addStruct(S:Id, L:KList) 
          => addStruct-aux(S:Id, L:KList,
               tv(0, cfg:largestUnsigned), .Map, .Map, L:KList)
          when L:KList =/=KList .KList
          [structural]
     rule addStruct-aux(
               S:Id
               , (typedDeclaration(T:Type, Field:Id),, L:KList)
               , V:TypedValue
               , Types:Map
               , Offsets:Map
               , L':KList
          ) 
          => addStruct-aux(S, L, V + bitSizeofType(T),
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
               , (typedDeclaration(T:Type, Field:Id),, L:KList)
               , Types:Map
               , Offsets:Map
               , L':KList
          ) 
          => addUnion-aux(S, L,
               Types:Map[T / Field], Offsets:Map[0 / Field],
               L')
          [structural]
     rule <k> 
               addUnion-aux(S:Id, .KList, Types:Map, Offsets:Map, L:KList) 
               => #if (F ==K file-scope)
                    #then (addGlobalAggregate(S,
                         aggregateInfo(L, Types, Offsets))) 
                    #else (addLocalAggregate(S,
                         aggregateInfo(L, Types, Offsets)))
                    #fi
          ...</k>
          <currentFunction> F:Id </currentFunction>
          [structural]

     rule <k> addGlobalAggregate(X:Id, K:K) => . ...</k>
          <structs> M':Map => M':Map[K / X] </structs>
          <gstructs> M:Map => M:Map[K / X] </gstructs>
          [structural]
     rule <k> addLocalAggregate(X:Id, K:K) => . ...</k>
          <structs> M:Map => M:Map[K / X] </structs>
          [structural]
          
     rule isFloatType(t(_, float)) => true 
     rule isFloatType(t(_, double)) => true 
     rule isFloatType(t(_, long-double)) => true 
     rule isFloatType(t(_, qualifiedType(T:Type, _)))
          => isFloatType(T) 
     rule isFloatType(t(_, T:SimpleType)) => false
          when (T =/=K float)
               andBool (T =/=K double)
               andBool (T =/=K long-double)
               andBool (getKLabel(T) =/=KLabel 'qualifiedType)
          
     rule [isCharType-char]: isCharType(t(_, char)) => true 
     rule [isCharType-qualified]:
          isCharType(t(_, qualifiedType(T:Type, _)))
          => isCharType(T) 
     rule [isCharType-unsigned-char]: isCharType(t(_, unsigned-char)) => true 
     rule [isCharType-signed-char]: isCharType(t(_, signed-char)) => true 
     rule [isCharType-other]: isCharType(t(_, T:SimpleType)) => false
          when (T =/=K char)
               andBool (T =/=K unsigned-char)
               andBool (T =/=K signed-char)
               andBool (getKLabel(T) =/=KLabel 'qualifiedType)
          
     rule [isWCharType-wchar]: isWCharType(t(_, T:SimpleType)) => true 
          when T ==K simpleType(cfg:wcharut)
          
     rule [isWCharType-other]: isWCharType(t(_, T:SimpleType)) => false
          when (T =/=K simpleType(cfg:wcharut))
               andBool (getKLabel(T) =/=KLabel 'qualifiedType )
          
     rule [isWCharType-qualified]:
          isWCharType(t(_, qualifiedType(T:Type, _)))
          => isWCharType(T) 
     
     rule [isPointerType-pointer]: isPointerType(t(_, pointerType(_))) => true 
     rule [isPointerType-qualified]:
          isPointerType(t(_, qualifiedType(T:Type, _)))
          => isPointerType(T) 
     rule [isPointerType-other]: isPointerType(t(_, T:SimpleType)) => false
          when (getKLabel(T) =/=KLabel 'pointerType)
               andBool (getKLabel(T) =/=KLabel 'qualifiedType)
     
     rule [isBoolType-bool]: isBoolType(t(_, bool)) => true 
     rule [isBoolType-qualifiedType]:
          isBoolType(t(_, qualifiedType(T:Type, _)))
          => isBoolType(T) 
     rule [isBoolType-other]: isBoolType(t(_, T:SimpleType)) => false
          when (T =/=K bool)
               andBool (getKLabel(T) =/=KLabel 'qualifiedType)
          
     rule [isArrayType-array]: isArrayType(t(_, arrayType(_, _:Int))) => true 
     rule [isArrayType-incompleteArray]:
          isArrayType(t(_, incompleteArrayType(_)))
          => true 
     rule [isArrayType-flexibleArray]:
          isArrayType(t(_, flexibleArrayType(_)))
          => true 
     rule [isArrayType-qualified]:
          isArrayType(t(_, qualifiedType(T:Type, _)))
          => isArrayType(T)
     rule [isArrayType-other]: isArrayType(t(_, T:SimpleType)) => false
          when (getKLabel(T) =/=KLabel 'arrayType)
               andBool (getKLabel(T) =/=KLabel 'incompleteArrayType)
               andBool (getKLabel(T) =/=KLabel 'flexibleArrayType)
               andBool (getKLabel(T) =/=KLabel 'qualifiedType)
          
     rule isVoidType(t(_, void)) => true
     rule isVoidType(t(_, K:K)) => false
          when K =/=K void

     rule isAggregateType(T:Type)
          => isArrayType(T) orBool isStructType(T) 
          
     rule [isStructType-struct]:
          isStructType(t(_, structType(_:Id))) => true 
     rule [isStructType-qualified]:
          isStructType(t(_, qualifiedType(T:Type, _)))
          => isStructType(T) 
     rule [isStructType-other]: isStructType(t(_, T:SimpleType)) => false
          when (getKLabel(T) =/=KLabel 'structType)
               andBool (getKLabel(T) =/=KLabel 'qualifiedType)
          
     rule [isUnionType-union]: isUnionType(t(_, unionType(_:Id))) => true 
     rule [isUnionType-qualified]:
          isUnionType(t(_, qualifiedType(T:Type, _)))
          => isUnionType(T) 
     rule [isUnionType-other]: isUnionType(t(_, T:SimpleType)) => false
          when (getKLabel(T) =/=KLabel 'unionType)
               andBool (getKLabel(T) =/=KLabel 'qualifiedType )

     rule [isIncompleteType-true]:
          isIncompleteType(t(_, incompleteArrayType(_)))
          => true 
     rule [isIncompleteType-true]:
          isIncompleteType(t(_, void))
          => true 
     rule [isIncompleteType-qualified]:
          isIncompleteType(t(_, qualifiedType(T:Type, _)))
          => isIncompleteType(T) 
     rule [isIncompleteType-false]: isIncompleteType(t(_, T:SimpleType)) => false
          when (getKLabel(T) =/=KLabel 'incompleteArrayType)
               andBool (getKLabel(T) =/=KLabel 'qualifiedType)
               andBool (getKLabel(T) =/=KLabel 'void)
          
     rule [isExternType-qualified]: 
          isExternType(t(_, qualifiedType(T:Type, K:K))) 
          => #if (K ==K Extern) #then (true) #else (isExternType(T)) #fi 
     rule [isExternType-false]: isExternType(t(_, T:SimpleType)) => false
          when getKLabel(T) =/=KLabel 'qualifiedType 
          
     rule [isStaticType-qualified]: 
          isStaticType(t(_, qualifiedType(T:Type, K:K))) 
          => #if (K ==K Static) #then (true) #else (isStaticType(T)) #fi
     rule [isStaticType-false]: isStaticType(t(_, T:SimpleType)) => false
          when getKLabel(T) =/=KLabel 'qualifiedType 
          
     rule [isConstType-qualified]: 
          isConstType(t(S:Set, qualifiedType(T:Type, _)))
          => isConstType(T)
          when notBool (Const in S)
     rule [isConstType-false]: 
          isConstType(t(S:Set, T:SimpleType)) => false
          when (getKLabel(T) =/=KLabel 'qualifiedType)
               andBool (notBool Const in S)
     rule [isConstType-true]: 
          isConstType(t(SetItem(Const) _, _)) => true
          
     rule [isBitfieldType-true]:
          isBitfieldType(t(_, bitfieldType(_, _:Int))) => true 
     rule [isBitfieldType-false]: isBitfieldType(t(_, T:SimpleType)) => false
          when getKLabel(T) =/=KLabel 'bitfieldType
          
     rule [isFunctionType-true]:
          isFunctionType(t(_, functionType(_, _:KList)))
          => true 
     rule [isFunctionType-qualified]:
          isFunctionType(t(_, qualifiedType(T:Type, _)))
          => isFunctionType(T) 
     rule [isFunctionType-false]: isFunctionType(t(_, T:SimpleType)) => false
          when (getKLabel(T) =/=KLabel 'functionType)
               andBool (getKLabel(T) =/=KLabel 'qualifiedType)
          
     rule [isFunctionPointerType-fp]:
          isFunctionPointerType(t(_, pointerType(t(_,
               functionType(_, _:KList)))))
          => true 
     rule [isFunctionPointerType-qualified]:
          isFunctionPointerType(t(_, qualifiedType(T:Type, _)))
          => isFunctionPointerType(T) 
     rule [isFunctionPointerType-qualified-pointer]: 
          isFunctionPointerType(t(_, pointerType(t(_,
               qualifiedType(T:Type, _))))) 
          => isFunctionPointerType(t(.Set, pointerType(T))) 
     rule [isFunctionPointerType-notPointer]:
          isFunctionPointerType(t(_, T:SimpleType))
          => false
          when (getKLabel(T) =/=KLabel 'pointerType)
               andBool (getKLabel(T) =/=KLabel 'qualifiedType)
          
     rule [isFunctionPointerType-notFunction]:
          isFunctionPointerType(t(_, pointerType(t(_, T:SimpleType))))
          => false
          when (getKLabel(T) =/=KLabel 'functionType)
               andBool (getKLabel(T) =/=KLabel 'qualifiedType)
          
     // /*@ \source[n1570]{\para{6.2.5}{18}}
     // Integer and floating types are collectively called arithmetic types.
     // Each arithmetic type belongs to one type domain: the real type domain
     // comprises the real types, the complex type domain comprises the complex
     // types. 
     // */
     rule isArithmeticType(T:Type)
          => hasIntegerType(T) orBool isFloatType(T)

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

     // These are the only "real" type qualifiers.
     syntax Set ::= "typeQualifiers" [function]
     rule typeQualifiers =>
          SetItem(Const)
          SetItem(Restrict)
          SetItem(Volatile)
          SetItem(Atomic)

     rule unqualifyType(t(_:Set, qualifiedType(T:Type, _))) => T
     rule unqualifyType(t(_:Set, T:SimpleType)) => t(.Set, T)
          when getKLabel(T) =/=KLabel 'qualifiedType
          
     // TODO(chathhorn): clearly this doesn't do exactly what it claims to do.
     rule removeStorageSpecifiers(t(_, qualifiedType(T:Type, _)))
          => T
     rule removeStorageSpecifiers(t(S:Set, T:SimpleType)) => t(S, T)
          when getKLabel(T) =/=KLabel 'qualifiedType
          
     rule getModifiers(t(S:Set, _)) => S
endmodule

