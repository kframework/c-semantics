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
          requires notBool (isTypedDeclaration(T) orBool isTypedDeclaration(T'))
               andBool sameQualifiers(getModifiers(T), getModifiers(T'))
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
               t(Mods:Set, unspecifiedArrayType(T:Type)),
               t(Mods':Set, unspecifiedArrayType(T':Type)))
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

     rule isWCharType(t(_, T:SimpleType)) => true
          requires T ==K cfg:wcharut
     rule isWCharType(_) => false [owise]

     rule isFlexibleArrayType(t(_, flexibleArrayType(_))) => true
     rule isFlexibleArrayType(typedDeclaration(T:Type, _))
          => isFlexibleArrayType(T)
     rule isFlexibleArrayType(_) => false [owise]

     rule isVariablyModifiedType(T:FixedLengthArrayType)
          => isVariablyModifiedType(innerType(T))
     rule isVariablyModifiedType(T:IncompleteArrayType)
          => isVariablyModifiedType(innerType(T))
     rule isVariablyModifiedType(T:PointerType)
          => isVariablyModifiedType(innerType(T))
     rule isVariablyModifiedType(t(_, functionType(T:Type, Params:List)))
          => isVariablyModifiedType(T) orBool some(Params, #klabel(`isVariablyModifiedType`))
     rule isVariablyModifiedType(typedDeclaration(T:Type, _))
          => isVariablyModifiedType(T)
     rule isVariablyModifiedType(_:VariableLengthArrayType) => true
     rule isVariablyModifiedType(_) => false [owise]

     rule isCompleteType(T:Type)
          => notBool (isIncompleteArrayType(T)
               orBool isIncompleteStructType(T)
               orBool isIncompleteUnionType(T)
               orBool isVoidType(T))
     rule isCompletePointerType(t(_, pointerType(T:Type))) => isCompleteType(T)
     rule isCompletePointerType(_) => false [owise]

     rule isIncompleteStructType(t(_, structType(S:StructId))) => getFieldInfo(S) ==K #incomplete
     rule isIncompleteStructType(typedDeclaration(T:Type, _))
          => isIncompleteStructType(T)
     rule isIncompleteStructType(_) => false [owise]

     rule isIncompleteUnionType(t(_, unionType(S:StructId))) => getFieldInfo(S) ==K #incomplete
     rule isIncompleteUnionType(typedDeclaration(T:Type, _))
          => isIncompleteUnionType(T)
     rule isIncompleteUnionType(_) => false [owise]

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
               andBool IntegerConstant in getModifiers(T)
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
