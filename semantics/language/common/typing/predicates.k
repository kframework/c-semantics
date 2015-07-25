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
               t(Mods:Set, structType(X:StructId)),
               t(Mods':Set, structType(X':StructId)))
          => true
          requires sameQualifiers(Mods, Mods')
          andBool getTag(X) ==K getTag(X')
     rule #typesEq(
               t(Mods:Set, unionType(X:StructId)),
               t(Mods':Set, unionType(X':StructId)))
          => true
          requires sameQualifiers(Mods, Mods')
          andBool getTag(X) ==K getTag(X')
     rule #typesEq(_, _) => false [owise]

     rule hasSameSignedness(T:Type, T':Type)
          => (isSignedIntegerType(T) andBool isSignedIntegerType(T'))
               orBool
               (isUnsignedIntegerType(T) andBool isUnsignedIntegerType(T'))

     rule isUnsignedIntegerType(t(_, _:SimpleUnsignedType)) => true
     rule isUnsignedIntegerType(t(S:Set, enumType(_))) => isUnsignedIntegerType(t(S, cfg:enumAlias))
     rule isUnsignedIntegerType(typedDeclaration(_:UnsignedIntegerType, _)) => true
     rule isUnsignedIntegerType(_) => false [owise]

     rule isSignedIntegerType(t(_, _:SimpleSignedType)) => true
     rule isSignedIntegerType(t(S:Set, enumType(_))) => isSignedIntegerType(t(S, cfg:enumAlias))
     rule isSignedIntegerType(typedDeclaration(_:SignedIntegerType, _)) => true
     rule isSignedIntegerType(_) => false [owise]

     rule isFloatType(t(_, _:SimpleFloatType)) => true
     rule isFloatType(typedDeclaration(_:FloatType, _)) => true
     rule isFloatType(_) => false [owise]

     rule isCharType(t(_, _:SimpleCharType)) => true
     rule isCharType(typedDeclaration(_:CharType, _)) => true
     rule isCharType(_) => false [owise]

     rule isUCharType(t(_, unsigned-char)) => true
     rule isUCharType(typedDeclaration(_:UCharType, _)) => true
     rule isUCharType(_) => false [owise]

     rule isSCharType(t(_, signed-char)) => true
     rule isSCharType(typedDeclaration(_:SCharType, _)) => true
     rule isSCharType(_) => false [owise]
 
     rule isWCharType(t(_, T:SimpleType)) => true
          requires T ==K cfg:wcharut
     rule isWCharType(_) => false [owise]

     rule isPointerType(t(_, pointerType(_))) => true
     rule isPointerType(typedDeclaration(_:PointerType, _)) => true
     rule isPointerType(_) => false [owise]

     rule isBoolType(t(_, bool)) => true
     rule isBoolType(typedDeclaration(_:BoolType, _)) => true
     rule isBoolType(_) => false [owise]

     rule isFixedLengthArrayType(t(_, arrayType(_, _))) => true
     rule isFixedLengthArrayType(typedDeclaration(_:FixedLengthArrayType, _)) => true
     rule isFixedLengthArrayType(_) => false [owise]

     rule isFlexibleArrayType(t(_, flexibleArrayType(_))) => true
     rule isFlexibleArrayType(typedDeclaration(T:Type, _))
          => isFlexibleArrayType(T)
     rule isFlexibleArrayType(_) => false [owise]

     rule isVariableLengthArrayType(t(_, variableLengthArrayType(_, _))) => true
     rule isVariableLengthArrayType(typedDeclaration(_:VariableLengthArrayType, _)) => true
     rule isVariableLengthArrayType(_) => false [owise]

     rule isVariablyModifiedType(t(_, arrayType(T:Type, _)))
          => isVariablyModifiedType(T)
     rule isVariablyModifiedType(t(_, pointerType(T:Type)))
          => isVariablyModifiedType(T)
     rule isVariablyModifiedType(typedDeclaration(T:Type, _))
          => isVariablyModifiedType(T)
     rule isVariablyModifiedType(_:VariableLengthArrayType) => true
     rule isVariablyModifiedType(_) => false [owise]

     rule isVoidType(t(_, void)) => true
     rule isVoidType(typedDeclaration(_:VoidType, _)) => true
     rule isVoidType(_) => false [owise]

     rule isNoType(t(_, no-type)) => true
     rule isNoType(typedDeclaration(_:NoType, _)) => true

     rule isStructType(t(_, structType(_))) => true
     rule isStructType(typedDeclaration(_:StructType, _)) => true
     rule isStructType(_) => false [owise]

     rule isUnionType(t(_, unionType(_))) => true
     rule isUnionType(typedDeclaration(_:UnionType, _)) => true
     rule isUnionType(_) => false [owise]

     rule isCompleteType(T:Type)
          => notBool (isIncompleteArrayType(T)
               orBool isIncompleteStructType(T)
               orBool isIncompleteUnionType(T)
               orBool isVoidType(T))
     rule isCompletePointerType(t(_, pointerType(T:Type))) => isCompleteType(T)
     rule isCompletePointerType(_) => false [owise]

     rule isIncompleteArrayType(t(_, incompleteArrayType(_))) => true
     rule isIncompleteArrayType(t(_, flexibleArrayType(_))) => true
     rule isIncompleteArrayType(typedDeclaration(T:Type, _))
          => isIncompleteArrayType(T)
     rule isIncompleteArrayType(_) => false [owise]

     rule isIncompleteStructType(t(_, structType(S:StructId))) => getFieldInfo(S) ==K #incomplete
     rule isIncompleteStructType(typedDeclaration(T:Type, _))
          => isIncompleteStructType(T)
     rule isIncompleteStructType(_) => false [owise]

     rule isIncompleteUnionType(t(_, unionType(S:StructId))) => getFieldInfo(S) ==K #incomplete
     rule isIncompleteUnionType(typedDeclaration(T:Type, _))
          => isIncompleteUnionType(T)
     rule isIncompleteUnionType(_) => false [owise]

     rule isSignedBitfieldType(t(_, bitfieldType(_:SignedIntegerType, _))) => true
     rule isSignedBitfieldType(typedDeclaration(_:SignedBitfieldType, _)) => true
     rule isSignedBitfieldType(_) => false [owise]

     rule isUnsignedBitfieldType(t(_, bitfieldType(_:UnsignedIntegerType, _))) => true
     rule isUnsignedBitfieldType(typedDeclaration(_:UnsignedBitfieldType, _)) => true
     rule isUnsignedBitfieldType(_) => false [owise]

     rule isFunctionType(t(_, functionType(_, _))) => true
     rule isFunctionType(typedDeclaration(_:FunctionType, _)) => true
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
     // types. */

     rule isExternType(T:Type) => (Extern in getStorageSpecifiers(T))
     rule isStaticType(T:Type) => (Static in getStorageSpecifiers(T))
     rule isRegisterType(T:Type) => (Register in getStorageSpecifiers(T))

     rule isConstType(T:Type) => (Const in getQualifiers(T))
     rule isVolatileType(T:Type) => (Volatile in getQualifiers(T))

     rule isRestrictType(t(SetItem(Restrict) _, _)) => true
     rule isRestrictType(_) => false [owise]

     rule isNullPointerConstant(tv(0, T:IntegerType)) => true
          requires fromConstantExpr(T)
     rule isNullPointerConstant(tv(NullPointer, T:PointerType)) => true
          requires (simpleType(innerType(T)) ==K void)
               andBool fromConstantExpr(T)
     rule isNullPointerConstant(_) => false [owise]

     // TODO(chathhorn): arithmetic and address constants
     rule fromConstantExpr(T:IntegerType) => true
          requires IntegerConstant in getModifiers(T)
     rule fromConstantExpr(_) => false [owise]

     rule hasAlignas(t(Mods:Set, _)) => hasAlignasMod(Mods)

     rule hasAlignasMod(SetItem(alignas(_)) Mods:Set) => true
     rule hasAlignasMod(_) => false [owise]

     rule hasReadFrom(t(Mods:Set, _)) => some(Mods, #klabel(`isReadFrom`))

     syntax Bool ::= isReadFrom(K) [function]
     rule isReadFrom(readFrom(_, _)) => true
     rule isReadFrom(_) => false [owise]

     rule isTruthValue(tv(V::CValue, t(_, T:SimpleType)))
          => T ==K int andBool (V ==K 0 orBool V ==K 1)
endmodule
