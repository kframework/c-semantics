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
               t(Mods:Set, structType(X:CId, _, _)),
               t(Mods':Set, structType(X:CId, _, _)))
          => true
          requires sameQualifiers(Mods, Mods')
     rule #typesEq(
               t(Mods:Set, structType(X:CId, _, _)),
               t(Mods':Set, incompleteStructType(X:CId)))
          => true
          requires sameQualifiers(Mods, Mods')
     rule #typesEq(
               t(Mods:Set, incompleteStructType(X:CId)),
               t(Mods':Set, structType(X:CId, _, _)))
          => true
          requires sameQualifiers(Mods, Mods')
     rule #typesEq(
               t(Mods:Set, unionType(X:CId, _, _)),
               t(Mods':Set, unionType(X:CId, _, _)))
          => true
          requires sameQualifiers(Mods, Mods')
     rule #typesEq(
               t(Mods:Set, unionType(X:CId, _, _)),
               t(Mods':Set, incompleteUnionType(X:CId)))
          => true
          requires sameQualifiers(Mods, Mods')
     rule #typesEq(
               t(Mods:Set, incompleteUnionType(X:CId)),
               t(Mods':Set, unionType(X:CId, _, _)))
          => true
          requires sameQualifiers(Mods, Mods')
     rule #typesEq(_, _) => false [owise]

     rule isBasicType(T:Type) => #isBasic(T)

     syntax Bool ::= #isBasic(Type) [function]

     rule #isBasic(t(_, T:SimpleType)) => true
          requires T in basicTypes
     rule #isBasic(t(_, enumType(_))) => true
     rule #isBasic(_) => false [owise]

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

     rule hasUnsignedIntegerType(T:Type) => #hasUnsignedInteger(T)
     rule hasSignedIntegerType(T:Type) => #hasSignedInteger(T)

     syntax Bool ::= #hasUnsignedInteger(Type) [function]
                   | #hasSignedInteger(Type) [function]

     rule #hasUnsignedInteger(t(_, bitfieldType(T:Type, _)))
          => #hasUnsignedInteger(T)
     rule #hasUnsignedInteger(t(_, T:SimpleType)) => true
          requires T in unsignedIntegerTypes
     rule #hasUnsignedInteger(typedDeclaration(T:Type, _))
          => #hasUnsignedInteger(T)
     rule #hasUnsignedInteger(_) => false [owise]

     rule #hasSignedInteger(t(_, T:SimpleType)) => true
          requires T in signedIntegerTypes
     rule #hasSignedInteger(t(_, enumType(_))) => true
     rule #hasSignedInteger(t(_, bitfieldType(T:Type, _)))
          => #hasSignedInteger(T)
     rule #hasSignedInteger(typedDeclaration(T:Type, _))
          => #hasSignedInteger(T)
     rule #hasSignedInteger(_) => false [owise]

     rule hasFloatType(T:Type) => #hasFloat(T)
     rule hasCharType(T:Type) => #hasChar(T)
     rule isUCharType(T:Type) => #isUChar(T)
     rule isWCharType(t(_, T:SimpleType)) => true
          requires T ==K simpleType(cfg:wcharut) 
     rule isWCharType(_) => false [owise]
     rule isPointerType(T:Type) => #isPointer(T)
     rule isBoolType(T:Type) => #isBoolT(T)
     rule isArrayType(T:Type) => #isArray(T)
     rule isFlexibleArrayType(T:Type) => #isFlexibleArray(T)
     rule isVoidType(T:Type) => #isVoid(T)
     rule isNoType(T:Type) => #isNoT(T)

     rule isAggregateType(T:Type)
          => isArrayType(T) orBool isStructType(T)
     rule isStructType(T:Type) => #isStruct(T)
     rule isUnionType(T:Type) => #isUnion(T)

     rule isCompleteType(T:Type)
          => notBool (isIncompleteArrayType(T)
               orBool isIncompleteStructType(T)
               orBool isIncompleteUnionType(T)
               orBool isVoidType(T))

     rule isIncompleteArrayType(T:Type) => #isIncompleteArray(T)
     rule isIncompleteStructType(T:Type) => #isIncompleteStruct(T)
     rule isIncompleteUnionType(T:Type) => #isIncompleteUnion(T)

     rule isBitfieldType(T:Type) => #isBitfield(T)
     rule isFunctionType(T:Type) =>  #isFunction(T)
     rule isOldStyleFunctionType(T:Type)
          => isFunctionType(T) andBool (oldStyle in getModifiers(T))
     rule isFunctionPointerType(T:Type) => #isFunctionPointer(T)

     rule isTypedDeclaration(typedDeclaration(_, _)) => true
     rule isTypedDeclaration(T:Type) => false [owise]

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
     rule isRestrictType(T:Type) => true
          requires #isRestrict(T)
     rule isRestrictType(T:Type) => false [owise]

     syntax Bool ::= #hasFloat(Type) [function]
                   | #hasChar(Type) [function]
                   | #isUChar(Type) [function]
                   | #isPointer(Type) [function]
                   | #isBoolT(Type) [function]
                   | #isArray(Type) [function]
                   | #isFlexibleArray(Type) [function]
                   | #isVoid(Type) [function]
                   | #isNoT(Type) [function]
                   | #isStruct(Type) [function]
                   | #isUnion(Type) [function]
                   | #isIncompleteArray(Type)  [function]
                   | #isIncompleteStruct(Type) [function]
                   | #isIncompleteUnion(Type)  [function]
                   | #isBitfield(Type) [function]
                   | #isFunction(Type) [function]
                   | #isFunctionPointer(Type) [function]
                   | #isRestrict(Type) [function]

     rule #hasFloat(t(_, T:SimpleType)) => true
          requires T in floatTypes
     rule #hasFloat(typedDeclaration(T:Type, _)) => #hasFloat(T)
     rule #hasFloat(_) => false [owise]

     rule #hasChar(t(_, T:SimpleType)) => true
          requires T in charTypes
     rule #hasChar(typedDeclaration(T:Type, _)) => #hasChar(T)
     rule #hasChar(_) => false [owise]

     rule #isUChar(t(_, unsigned-char)) => true
     rule #isUChar(typedDeclaration(T:Type, _)) => #isUChar(T)

     rule #isPointer(t(_, pointerType(_))) => true
     rule #isPointer(typedDeclaration(T:Type, _)) => #isPointer(T)
     rule #isPointer(_) => false [owise]

     rule #isBoolT(t(_, bool)) => true
     rule #isBoolT(typedDeclaration(T:Type, _)) => #isBoolT(T)
     rule #isBoolT(_) => false [owise]

     rule #isArray(t(_, arrayType(_, _))) => true
     rule #isArray(t(_, incompleteArrayType(_))) => true
     rule #isArray(t(_, flexibleArrayType(_))) => true
     rule #isArray(t(_, variableLengthArrayType(_, _))) => true
     rule #isArray(typedDeclaration(T:Type, _)) => #isArray(T)
     rule #isArray(_) => false [owise]

     rule #isFlexibleArray(t(_, flexibleArrayType(_))) => true
     rule #isFlexibleArray(typedDeclaration(T:Type, _)) => #isFlexibleArray(T)
     rule #isFlexibleArray(_) => false [owise]

     rule #isVoid(t(_, void)) => true
     rule #isVoid(typedDeclaration(T:Type, _)) => #isVoid(T)
     rule #isVoid(_) => false [owise]

     rule #isNoT(t(_, no-type)) => true
     rule #isNoT(typedDeclaration(T:Type, _)) => #isNoT(T)
     rule #isNoT(_) => false [owise]

     rule #isStruct(t(_, structType(_, _, _))) => true
     rule #isStruct(t(_, incompleteStructType(_))) => true
     rule #isStruct(typedDeclaration(T:Type, _)) => #isStruct(T)
     rule #isStruct(_) => false [owise]

     rule #isUnion(t(_, unionType(_, _, _))) => true
     rule #isUnion(t(_, incompleteUnionType(_))) => true
     rule #isUnion(typedDeclaration(T:Type, _)) => #isUnion(T)
     rule #isUnion(_) => false [owise]

     rule #isIncompleteArray(t(_, incompleteArrayType(_))) => true
     rule #isIncompleteArray(t(_, flexibleArrayType(_))) => true
     rule #isIncompleteArray(typedDeclaration(T:Type, _))
          => #isIncompleteArray(T)
     rule #isIncompleteArray(_) => false [owise]

     rule #isIncompleteStruct(t(_, incompleteStructType(_))) => true
     rule #isIncompleteStruct(typedDeclaration(T:Type, _))
          => #isIncompleteStruct(T)
     rule #isIncompleteStruct(_) => false [owise]

     rule #isIncompleteUnion(t(_, incompleteUnionType(_))) => true
     rule #isIncompleteUnion(typedDeclaration(T:Type, _))
          => #isIncompleteUnion(T)
     rule #isIncompleteUnion(_) => false [owise]

     rule #isBitfield(t(_, bitfieldType(_, _))) => true
     rule #isBitfield(typedDeclaration(T:Type, _)) => #isBitfield(T)
     rule #isBitfield(_) => false [owise]

     rule #isFunction(t(_, functionType(_, _))) => true
     rule #isFunction(typedDeclaration(T:Type, _)) => #isFunction(T)
     rule #isFunction(_) => false [owise]

     rule #isFunctionPointer(t(_, pointerType(t(_, functionType(_, _)))))
          => true
     rule #isFunctionPointer(typedDeclaration(T:Type, _))
          => #isFunctionPointer(T)
     rule #isFunctionPointer(_) => false [owise]

     rule #isRestrict(t(SetItem(Restrict) _, _)) => true
     rule #isRestrict(_) => false [owise]

     rule isNullPointerConstant(TV:TypedValue) => true
          requires #isNPC(TV)
     rule isNullPointerConstant(TV:TypedValue) => false [owise]

     syntax Bool ::= "#isNPC" "(" TypedValue ")" [function]
     rule #isNPC(tv(0, T:Type)) => true
          requires hasIntegerType(T)
               andBool fromConstantExpr(T)
     rule #isNPC(tv(NullPointer, T:Type)) => true
          requires isPointerType(T)
               andBool (simpleType(innerType(T)) ==K void)
               andBool fromConstantExpr(T)
     rule #isNPC(_) => false [owise]

     // TODO(chathhorn)
     rule fromConstantExpr(_) => true

endmodule
