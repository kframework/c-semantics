module C-TYPING-PREDICATES
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports COMPAT-SYNTAX

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
     rule hasUnsignedIntegerType(t(_, bitfieldType(T:Type, _))) => true
          when hasUnsignedIntegerType(T) ==Bool true
     rule hasUnsignedIntegerType(t(_, bitfieldType(T:Type, _))) => false
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
     rule hasSignedIntegerType(t(_, bitfieldType(T:Type, _))) => true
          when hasSignedIntegerType(T) ==Bool true
     rule hasSignedIntegerType(t(_, bitfieldType(T:Type, _))) => false
          when hasSignedIntegerType(T) ==Bool false

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
          => #isCompat(unqualifyType(T1), unqualifyType(T2)) ==K true

     // TODO(chathhorn): fill in for structs.
     rule #isCompat(t(_, structType(_)), t(_, structType(_))) => true

     // TODO(chathhorn): are enums compatible with e.g. ints?
     rule #isCompat(t(_, enumType(_)), t(_, enumType(_))) => true

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
          #isCompat(T:Type, t(S:Set, arrayType(T':Type, _)))
          => #isCompat(T, t(S:Set, pointerType(T'))) 
     rule [typeCompatible-array-left]:
          #isCompat(t(S:Set, arrayType(T:Type, _)), T':Type)
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
               t(_, functionType(T:Type, Args:List)),
               t(_, functionType(T':Type, Args':List)))
          => #isCompat(T, T') 
          when (Args ==List .List) orBool (Args' ==List .List)
     rule [typeCompatible-function]:
          #isCompat(
               t(S:Set,  functionType(T:Type,  ListItem(TA:Type) L:List)),
               t(S':Set, functionType(T':Type, ListItem(TA':Type) L':List)))
          => #isCompat(
               t(S, functionType(T, L)), 
               t(S', functionType(T', L')))
               andBool #isCompat(TA, TA') 
     rule [typeCompatible-function-nil]:
          #isCompat(
               t(_, functionType(T:Type, .List)),
               t(_, functionType(T':Type, .List)))
          => #isCompat(T, T') 
          
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
          
     syntax SimpleType ::= simpleType(Type) [function]
     rule simpleType(t(_, T:SimpleType)) => T

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
          
     rule [isArrayType-array]: isArrayType(t(_, arrayType(_, _))) => true 
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

     // Incomplete structs and unions?
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
          isBitfieldType(t(_, bitfieldType(_, _))) => true 
     rule [isBitfieldType-false]: isBitfieldType(t(_, T:SimpleType)) => false
          when getKLabel(T) =/=KLabel 'bitfieldType
          
     rule [isFunctionType-true]:
          isFunctionType(t(_, functionType(_, _:List)))
          => true 
     rule [isFunctionType-qualified]:
          isFunctionType(t(_, qualifiedType(T:Type, _)))
          => isFunctionType(T) 
     rule [isFunctionType-false]: isFunctionType(t(_, T:SimpleType)) => false
          when (getKLabel(T) =/=KLabel 'functionType)
               andBool (getKLabel(T) =/=KLabel 'qualifiedType)
          
     rule [isFunctionPointerType-fp]:
          isFunctionPointerType(t(_, pointerType(t(_,
               functionType(_, _:List)))))
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
               
endmodule
