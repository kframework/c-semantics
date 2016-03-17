module C-TYPING-PREDICATES
     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX

     imports COMPAT-SYNTAX

     // TODO(chathhorn): doesn't handle functions very gracefully.
     rule T:Type ==Type T':Type => typesEq(T, T')
     rule T:Type =/=Type T':Type => notBool typesEq(T, T')

     rule T:UType ==Type T':UType => typesEq(type(T), type(T'))
     rule T:UType =/=Type T':UType => notBool typesEq(type(T), type(T'))

     syntax Bool ::= typesEq(Type, Type) [function]
     rule typesEq(T:Type, T) => true
     rule typesEq(T:Type, T':Type) => typesEq(simpleType(T), simpleType(T'))
          requires getQualifiers(T) ==K getQualifiers(T')
     rule typesEq(_:Type, _) => false [owise]

     syntax Bool ::= typesEq(SimpleType, SimpleType) [function]
     rule typesEq(T:SimpleType, T) => true
     rule typesEq(pointerType(T::Type), pointerType(T'::Type))
          => typesEq(T, T')
     rule typesEq(arrayType(T::Type, Len::Int), arrayType(T'::Type, Len))
          => typesEq(T, T')
     rule typesEq(incompleteArrayType(T::Type), incompleteArrayType(T':Type))
          => typesEq(T, T')
     rule typesEq(flexibleArrayType(T::Type), flexibleArrayType(T':Type))
          => typesEq(T, T')
     rule typesEq(unspecifiedArrayType(T::Type), unspecifiedArrayType(T':Type))
          => typesEq(T, T')
     rule typesEq(variableLengthArrayType(T::Type, K:K), variableLengthArrayType(T':Type, K':K))
          => typesEq(T, T')
     rule typesEq(structType(X::StructId), structType(X'::StructId))
          => getTag(X) ==K getTag(X')
     rule typesEq(unionType(X::StructId), unionType(X'::StructId))
          => getTag(X) ==K getTag(X')
     rule typesEq(_:SimpleType, _) => false [owise]

     rule hasSameSignedness(T:SignedIntegerUType, T':SignedIntegerUType) => true
     rule hasSameSignedness(T:UnsignedIntegerUType, T':UnsignedIntegerUType) => true
     rule hasSameSignedness(_, _) => false [owise]

     rule isWCharType(t(_, _, T::SimpleType)) => true
          requires T ==K cfg:wcharut
     rule isWCharType(_) => false [owise]

     rule isFlexibleArrayType(t(_, _, flexibleArrayType(_))) => true
     rule isFlexibleArrayType(_) => false [owise]

     rule isVariablyModifiedType(T:FixedLengthArrayType)
          => isVariablyModifiedType(innerType(T))
     rule isVariablyModifiedType(T:IncompleteArrayType)
          => isVariablyModifiedType(innerType(T))
     rule isVariablyModifiedType(T:PointerType)
          => isVariablyModifiedType(innerType(T))
     rule isVariablyModifiedType(t(_, _, functionType(T::UType, Params:List)))
          => isVariablyModifiedType(type(T)) orBool some(Params, #klabel(`isVariablyModifiedType`))
     rule isVariablyModifiedType(_:VariableLengthArrayType) => true
     rule isVariablyModifiedType(_) => false [owise]

     rule isCompleteType(_:IncompleteArrayType) => false
     rule isCompleteType(T:StructType) => notBool isIncompleteStructType(T)
     rule isCompleteType(T:UnionType) => notBool isIncompleteUnionType(T)
     rule isCompleteType(_:VoidType) => false
     rule isCompleteType(_) => true [owise]

     rule isCompletePointerType(t(_, _, pointerType(T::Type)))
          => isCompleteType(T)
     rule isCompletePointerType(_) => false [owise]

     rule isIncompleteStructType(t(_, _, structType(S::StructId)))
          => getFieldInfo(S) ==K #incomplete
     rule isIncompleteStructType(_) => false [owise]

     rule isIncompleteUnionType(t(_, _, unionType(S:StructId)))
          => getFieldInfo(S) ==K #incomplete
     rule isIncompleteUnionType(_) => false [owise]

     rule isOldStyleFunctionType(T::Type)
          => isFunctionType(T) andBool (oldStyle in getModifiers(T))

     rule isFunctionPointerType(t(_, _, pointerType(t(_, _, functionType(_, _)))))
          => true
     rule isFunctionPointerType(_) => false [owise]

     rule isExternType(T::Type) => Extern in getStorageSpecifiers(T)
     rule isStaticType(T::Type) => Static in getStorageSpecifiers(T)
     rule isRegisterType(T::Type) => Register in getStorageSpecifiers(T)

     rule isConstType(T::Type) => Const inQuals getQualifiers(T)
     rule isVolatileType(T::Type) => Volatile inQuals getQualifiers(T)
     rule isRestrictType(T::Type) => Restrict inQuals getQualifiers(T)

     rule fromConstantExpr(T:Type) => fromConstantExpr(utype(T))
     rule fromConstantExpr(V:RValue) => fromConstantExpr(utype(V))

     // TODO(chathhorn): arithmetic and address constants
     rule fromConstantExpr(T:IntegerUType) => true
          requires IntegerConstant in getModifiers(T)
     rule fromConstantExpr(T:PointerUType) => true
          requires IntegerConstant in getModifiers(T)
     rule fromConstantExpr(_:UType) => false [owise]

     rule isNull(tv(0, _)) => true
     rule isNull(tv(NullPointer, _)) => true
     rule isNull(_) => false [owise]

     rule isNullPointerConstant(tv(0, T::UType)) => true
          requires fromConstantExpr(T)
               andBool isIntegerType(type(T))
     rule isNullPointerConstant(tv(NullPointer, T::UType)) => true
          requires isPointerType(type(T))
               andBool (simpleType(innerType(type(T))) ==K void)
               andBool fromConstantExpr(T)
     rule isNullPointerConstant(_) => false [owise]

     rule hasAlignas(t(_, Mods:Set, _)) => hasAlignasMod(Mods)

     rule hasAlignasMod(SetItem(alignas(_)) Mods:Set) => true
     rule hasAlignasMod(_) => false [owise]

     rule hasReadFrom(ut(Mods:Set, _)) => some(Mods, #klabel(`isReadFrom`))

     syntax Bool ::= isReadFrom(K) [function]
     rule isReadFrom(readFrom(_, _)) => true
     rule isReadFrom(_) => false [owise]

     rule isTruthValue(tv(V::CValue, ut(_, T::SimpleUType)))
          => T ==K int andBool (V ==K 0 orBool V ==K 1)
endmodule
