module C-TYPING-MISC-SYNTAX
     syntax K ::= "addStruct" "(" Id "," KList ")"
     syntax K ::= "addUnion" "(" Id "," KList ")"
endmodule

module C-TYPING-MISC
     imports C-SYNTAX
     imports C-SEMANTIC-SYNTAX
     imports C-SETTINGS
     imports C-TYPING-MISC-SYNTAX

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
                    #then (addGlobalAggregate(S:Id, 
                         aggregateInfo(L:KList, Types:Map, Offsets:Map))) 
                    #else (addLocalAggregate(S:Id, 
                         aggregateInfo(L:KList, Types:Map, Offsets:Map)))
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
          
     rule isTypeResult(t(_, T:K)) => true
          when l(getKLabel(T:K)) in setOfTypes
     rule isTypeResult(T:KResult) => true 
          when isBasicType(T:KResult)
     rule isTypeResult(K:K) => false
          when getKLabel(K:K) =/=KLabel 't
     rule isTypeResult(t(S:Set, T:K)) => false
          when (notBool l(getKLabel(T:K)) in setOfTypes)
               andBool (notBool isBasicType(t(S:Set, T:K)))

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
          
     rule isAggregateType(T:KResult)
          => isArrayType(T:KResult) orBool isStructType(T:KResult) 
          
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
          isBitfieldType(t(_, bitfieldType(_, _:Int)))
          => true 
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

