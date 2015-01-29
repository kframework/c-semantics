module C-TYPING-PREDICATES
     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX

     imports COMPAT-SYNTAX

     // Equality modulo provenance, storage specifiers, and struct/union
     // completeness. This is actually a looser notion of type equality than
     // "areCompatible()".
     // TODO(chathhorn): doesn't handle functions very gracefully.
     rule T:Type ==Type T':Type => #typesEq(T, T')
     rule T:Type =/=Type T':Type => notBool #typesEq(T, T')

     syntax Bool ::= #typesEq(Type, Type) [function]
     rule #typesEq(T:Type, T) => true
     rule #typesEq(T:Type, T':Type) => true
          requires sameQualifiers(getModifiers(T), getModifiers(T'))
               andBool (simpleType(T) ==K simpleType(T'))
     rule #typesEq(
               typedDeclaration(T:Type, X:CId),
               typedDeclaration(T':Type, X:CId))
          => #typesEq(T, T')
     rule #typesEq(
               t(Mods:Set, pointerType(T:Type)),
               t(Mods':Set, pointerType(T':Type)))
          => #typesEq(T, T')
          requires sameQualifiers(Mods, Mods')
     rule #typesEq(
               t(Mods:Set, arrayType(T:Type, Len:Int)),
               t(Mods':Set, arrayType(T':Type, Len)))
          => #typesEq(T, T')
          requires sameQualifiers(Mods, Mods')
     rule #typesEq(
               t(Mods:Set, incompleteArrayType(T:Type)),
               t(Mods':Set, incompleteArrayType(T':Type)))
          => #typesEq(T, T')
          requires sameQualifiers(Mods, Mods')
     rule #typesEq(
               t(Mods:Set, flexibleArrayType(T:Type)),
               t(Mods':Set, flexibleArrayType(T':Type)))
          => #typesEq(T, T')
          requires sameQualifiers(Mods, Mods')
     rule #typesEq(
               t(Mods:Set, variableLengthArrayType(T:Type, _)),
               t(Mods':Set, variableLengthArrayType(T':Type, _)))
          => #typesEq(T, T')
          requires sameQualifiers(Mods, Mods')
     rule #typesEq(
               t(Mods:Set, structType(X:CId,  _)),
               t(Mods':Set, structType(X:CId, _)))
          => true
          requires sameQualifiers(Mods, Mods')
     rule #typesEq(
               t(Mods:Set, structType(X:CId, _)),
               t(Mods':Set, incompleteStructType(X:CId)))
          => true
          requires sameQualifiers(Mods, Mods')
     rule #typesEq(
               t(Mods:Set, incompleteStructType(X:CId)),
               t(Mods':Set, structType(X:CId, _)))
          => true
          requires sameQualifiers(Mods, Mods')
     rule #typesEq(
               t(Mods:Set, unionType(X:CId, _)),
               t(Mods':Set, unionType(X:CId, _)))
          => true
          requires sameQualifiers(Mods, Mods')
     rule #typesEq(
               t(Mods:Set, unionType(X:CId, _)),
               t(Mods':Set, incompleteUnionType(X:CId)))
          => true
          requires sameQualifiers(Mods, Mods')
     rule #typesEq(
               t(Mods:Set, incompleteUnionType(X:CId)),
               t(Mods':Set, unionType(X:CId, _)))
          => true
          requires sameQualifiers(Mods, Mods')
     rule #typesEq(_, _) => false [owise]

     rule isBasicType(t(_, T:SimpleType)) => true
          requires T in basicTypes
     rule isBasicType(t(_, enumType(_))) => true
     rule isBasicType(_) => false [owise]

     syntax Set ::= "basicTypes" [function]
     rule basicTypes =>
          unsignedIntegerTypes
          signedIntegerTypes
          floatTypes
          SetItem(void)
          SetItem(no-type)

     syntax Set ::= "floatTypes" [function]
     rule floatTypes =>
          SetItem(float)
          SetItem(double)
          SetItem(long-double)

     syntax Set ::= "unsignedIntegerTypes" [function]
     rule unsignedIntegerTypes =>
          SetItem(bool)
          SetItem(unsigned-char)
          SetItem(unsigned-short-int)
          SetItem(unsigned-int)
          SetItem(unsigned-long-int)
          SetItem(unsigned-long-long-int)

     syntax Set ::= "signedIntegerTypes" [function]
     rule signedIntegerTypes =>
          SetItem(char)
          SetItem(signed-char)
          SetItem(short-int)
          SetItem(int)
          SetItem(long-int)
          SetItem(long-long-int)

     syntax Set ::= "charTypes" [function]
     rule charTypes =>
          SetItem(char)
          SetItem(signed-char)
          SetItem(unsigned-char)

     rule hasSameSignedness(T:Type, T':Type)
          => (hasSignedIntegerType(T) andBool hasSignedIntegerType(T'))
               orBool
               (hasUnsignedIntegerType(T) andBool hasUnsignedIntegerType(T'))

     rule hasIntegerType(T:Type)
          => hasUnsignedIntegerType(T) orBool hasSignedIntegerType(T)

     rule hasUnsignedIntegerType(t(_, bitfieldType(T:Type, _)))
          => hasUnsignedIntegerType(T)
     rule hasUnsignedIntegerType(t(_, T:SimpleType)) => true
          requires T in unsignedIntegerTypes
     rule hasUnsignedIntegerType(typedDeclaration(T:Type, _))
          => hasUnsignedIntegerType(T)
     rule hasUnsignedIntegerType(_) => false [owise]

     rule hasSignedIntegerType(t(_, T:SimpleType)) => true
          requires T in signedIntegerTypes
     rule hasSignedIntegerType(t(_, enumType(_))) => true
     rule hasSignedIntegerType(t(_, bitfieldType(T:Type, _)))
          => hasSignedIntegerType(T)
     rule hasSignedIntegerType(typedDeclaration(T:Type, _))
          => hasSignedIntegerType(T)
     rule hasSignedIntegerType(_) => false [owise]

     rule hasFloatType(t(_, T:SimpleType)) => true
          requires T in floatTypes
     rule hasFloatType(typedDeclaration(T:Type, _)) => hasFloatType(T)
     rule hasFloatType(_) => false [owise]

     rule hasCharType(t(_, T:SimpleType)) => true
          requires T in charTypes
     rule hasCharType(typedDeclaration(T:Type, _)) => hasCharType(T)
     rule hasCharType(_) => false [owise]

     rule isUCharType(t(_, unsigned-char)) => true
     rule isUCharType(typedDeclaration(T:Type, _)) => isUCharType(T)
     rule isUCharType(_) => false [owise]

     rule isWCharType(t(_, T:SimpleType)) => true
          requires T ==K cfg:wcharut
     rule isWCharType(_) => false [owise]

     rule isPointerType(t(_, pointerType(_))) => true
     rule isPointerType(typedDeclaration(T:Type, _)) => isPointerType(T)
     rule isPointerType(_) => false [owise]

     rule isBoolType(t(_, bool)) => true
     rule isBoolType(typedDeclaration(T:Type, _)) => isBoolType(T)
     rule isBoolType(_) => false [owise]

     rule isArrayType(t(_, arrayType(_, _))) => true
     rule isArrayType(t(_, incompleteArrayType(_))) => true
     rule isArrayType(t(_, flexibleArrayType(_))) => true
     rule isArrayType(t(_, variableLengthArrayType(_, _))) => true
     rule isArrayType(typedDeclaration(T:Type, _)) => isArrayType(T)
     rule isArrayType(_) => false [owise]

     rule isFlexibleArrayType(t(_, flexibleArrayType(_))) => true
     rule isFlexibleArrayType(typedDeclaration(T:Type, _))
          => isFlexibleArrayType(T)
     rule isFlexibleArrayType(_) => false [owise]

     rule isVoidType(t(_, void)) => true
     rule isVoidType(typedDeclaration(T:Type, _)) => isVoidType(T)
     rule isVoidType(_) => false [owise]

     rule isNoType(t(_, no-type)) => true
     rule isNoType(typedDeclaration(T:Type, _)) => isNoType(T)
     rule isNoType(_) => false [owise]

     rule isAggregateType(T:Type)
          => isArrayType(T) orBool isStructType(T)

     rule isStructType(t(_, structType(_, _))) => true
     rule isStructType(t(_, incompleteStructType(_))) => true
     rule isStructType(typedDeclaration(T:Type, _)) => isStructType(T)
     rule isStructType(_) => false [owise]

     rule isUnionType(t(_, unionType(_, _))) => true
     rule isUnionType(t(_, incompleteUnionType(_))) => true
     rule isUnionType(typedDeclaration(T:Type, _)) => isUnionType(T)
     rule isUnionType(_) => false [owise]

     rule isCompleteType(T:Type)
          => notBool (isIncompleteArrayType(T)
               orBool isIncompleteStructType(T)
               orBool isIncompleteUnionType(T)
               orBool isVoidType(T))

     rule isIncompleteArrayType(t(_, incompleteArrayType(_))) => true
     rule isIncompleteArrayType(t(_, flexibleArrayType(_))) => true
     rule isIncompleteArrayType(typedDeclaration(T:Type, _))
          => isIncompleteArrayType(T)
     rule isIncompleteArrayType(_) => false [owise]

     rule isIncompleteStructType(t(_, incompleteStructType(_))) => true
     rule isIncompleteStructType(typedDeclaration(T:Type, _))
          => isIncompleteStructType(T)
     rule isIncompleteStructType(_) => false [owise]

     rule isIncompleteUnionType(t(_, incompleteUnionType(_))) => true
     rule isIncompleteUnionType(typedDeclaration(T:Type, _))
          => isIncompleteUnionType(T)
     rule isIncompleteUnionType(_) => false [owise]

     rule isBitfieldType(t(_, bitfieldType(_, _))) => true
     rule isBitfieldType(typedDeclaration(T:Type, _)) => isBitfieldType(T)
     rule isBitfieldType(_) => false [owise]

     rule isFunctionType(t(_, functionType(_, _))) => true
     rule isFunctionType(typedDeclaration(T:Type, _)) => isFunctionType(T)
     rule isFunctionType(_) => false [owise]

     rule isOldStyleFunctionType(T:Type)
          => isFunctionType(T) andBool (oldStyle in getModifiers(T))

     rule isFunctionPointerType(t(_, pointerType(t(_, functionType(_, _)))))
          => true
     rule isFunctionPointerType(typedDeclaration(T:Type, _))
          => isFunctionPointerType(T)
     rule isFunctionPointerType(_) => false [owise]

     rule isTypedDeclaration(typedDeclaration(_, _)) => true
     rule isTypedDeclaration(_) => false [owise]

     // /*@ \source[n1570]{\para{6.2.5}{18}}
     // Integer and floating types are collectively called arithmetic types.
     // Each arithmetic type belongs to one type domain: the real type domain
     // comprises the real types, the complex type domain comprises the complex
     // types.
     // */
     rule hasArithmeticType(T:Type)
          => hasIntegerType(T) orBool hasFloatType(T)

     rule isExternType(T:Type) => (Extern in getStorageSpecifiers(T))
     rule isStaticType(T:Type) => (Static in getStorageSpecifiers(T))
     rule isRegisterType(T:Type) => (Register in getStorageSpecifiers(T))

     rule isConstType(T:Type) => (Const in getQualifiers(T))
     rule isVolatileType(T:Type) => (Volatile in getQualifiers(T))

     rule isRestrictType(t(SetItem(Restrict) _, _)) => true
     rule isRestrictType(_) => false [owise]

     rule isNullPointerConstant(tv(0, T:Type)) => true
          requires hasIntegerType(T)
               andBool fromConstantExpr(T)
     rule isNullPointerConstant(tv(NullPointer, T:Type)) => true
          requires isPointerType(T)
               andBool (simpleType(innerType(T)) ==K void)
               andBool fromConstantExpr(T)
     rule isNullPointerConstant(_) => false [owise]

     // TODO(chathhorn): arithmetic and address constants
     rule fromConstantExpr(T:Type) => true
          requires (hasIntegerType(T) andBool IntegerConstant in getModifiers(T))
     rule fromConstantExpr(_) => false [owise]

endmodule
