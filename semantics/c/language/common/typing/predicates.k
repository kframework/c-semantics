module C-TYPING-PREDICATES
     imports C-TYPING-SYNTAX
     imports BOOL
     imports K-EQUAL
     imports COMPAT-SYNTAX
     imports SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX

     rule hasSameSignedness(signedIntegerUType #as T::UType, signedIntegerUType #as T'::UType) => true
     rule hasSameSignedness(unsignedIntegerUType #as T::UType, unsignedIntegerUType #as T'::UType) => true
     rule hasSameSignedness(_, _) => false [owise]

     rule isWCharType(t(_, _, T::SimpleType)) => true
          requires T ==K cfg:wcharut
     rule isWCharType(_) => false [owise]

     rule isFlexibleArrayType(t(_, _, flexibleArrayType(_))) => true
     rule isFlexibleArrayType(_) => false [owise]

     rule isVariablyModifiedType(t(... st: _:SimpleFixedArrayType) #as T::Type)
          => isVariablyModifiedType(innerType(T))
     rule isVariablyModifiedType(t(... st: _:SimpleIncompleteArrayType) #as T::Type)
          => isVariablyModifiedType(innerType(T))
     rule isVariablyModifiedType(t(... st: pointerType(_)) #as T::Type)
          => isVariablyModifiedType(innerType(T))
     rule isVariablyModifiedType(t(... st: functionType(_, ListItem(T:UType) _))) => true
          requires isVariablyModifiedType(type(T))
     rule isVariablyModifiedType(t(... st: functionType(T::UType, .List)))
          => isVariablyModifiedType(type(T))
     rule isVariablyModifiedType(t(... st: functionType(_, (ListItem(T:UType) => .List) _)))
          requires notBool isVariablyModifiedType(type(T))
     rule isVariablyModifiedType(t(... st: functionType(_, (ListItem(variadic) => .List) _)))
     rule isVariablyModifiedType(t(... st: _:SimpleVariableArrayType)) => true
     rule isVariablyModifiedType(_) => false [owise]

     rule isCompleteType(t(... st: _:SimpleIncompleteArrayType)) => false
     rule isCompleteType(t(... st: enumType(_)) #as T::Type) => notBool isIncompleteEnumType(T)
     rule isCompleteType(t(... st: structType(_)) #as T::Type) => notBool isIncompleteStructType(T)
     rule isCompleteType(t(... st: unionType(_)) #as T::Type) => notBool isIncompleteUnionType(T)
     rule isCompleteType(t(... st: void)) => false
     rule isCompleteType(t(... st: no-type)) => false
     rule isCompleteType(_) => true [owise]

     rule isCompletePointerType(t(_, _, pointerType(T::Type)))
          => isCompleteType(T)
     rule isCompletePointerType(_) => false [owise]

     rule isIncompleteEnumType(t(_, _, enumType(S::TagId)))
          => getTagInfo(S) ==K #incomplete
     rule isIncompleteEnumType(_) => false [owise]

     rule isIncompleteStructType(t(_, _, structType(S::TagId)))
          => getTagInfo(S) ==K #incomplete
     rule isIncompleteStructType(_) => false [owise]

     rule isIncompleteUnionType(t(_, _, unionType(S::TagId)))
          => getTagInfo(S) ==K #incomplete
     rule isIncompleteUnionType(_) => false [owise]

     rule isOldStyleFunctionType(T::Type)
          => isFunctionType(T) andBool (oldStyle in getModifiers(T))

     rule isFunctionPointerType(t(_, _, pointerType(t(_, _, functionType(_, _)))))
          => true
     rule isFunctionPointerType(_) => false [owise]

     rule isExternType(T::Type) => Extern() in getStorageSpecifiers(T)
     rule isStaticType(T::Type) => Static() in getStorageSpecifiers(T)
     rule isRegisterType(T::Type) => Register() in getStorageSpecifiers(T)

     rule isConstType(T::Type) => Const() inQuals getQualifiers(T)
     rule isVolatileType(T::Type) => Volatile() inQuals getQualifiers(T)
     rule isRestrictType(T::Type) => Restrict() inQuals getQualifiers(T)

     rule fromConstantExpr(T:Type) => fromConstantExpr(utype(T))
     rule fromConstantExpr(V:RValue) => fromConstantExpr(utype(V))

     // TODO(chathhorn): arithmetic and address constants
     rule fromConstantExpr(integerUType #as T::UType) => true
          requires IntegerConstant in getModifiers(T)
     rule fromConstantExpr(ut(... st: pointerType(_)) #as T::UType) => true
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

     rule hasReadFrom(ut(SetItem(K:KItem) Mods:Set, _)) => true
          requires isReadFrom(K)
     rule hasReadFrom(ut(.Set, _)) => false
     rule hasReadFrom(ut((SetItem(_) => .Set) _, _)) [owise]

     syntax Bool ::= isReadFrom(K) [function]
     rule isReadFrom(readFrom(_, _)) => true
     rule isReadFrom(_) => false [owise]

     rule isTruthValue(tv(V::CValue, ut(_, T::SimpleUType)))
          => isSimpleIntType(T) andBool (V ==K 0 orBool V ==K 1)

     rule isFlexibleType(dynamicType(T::Type)) => isFlexibleType(T)
     rule isFlexibleType(t(... st: structType(_)) #as T::Type) => isFlexibleStruct(getFields(T))
     rule isFlexibleType(t(... st: unionType(_)) #as T::Type) => isFlexibleUnion(getFields(T))
     rule isFlexibleType(_) => false [owise]

     syntax Bool ::= isFlexibleStruct(FieldInfo) [function]
     rule isFlexibleStruct(fieldInfo(_:List ListItem(typedDeclaration(T::Type, _)), _, _, _, _, _)) => true
          requires isFlexibleArrayType(T)
     rule isFlexibleStruct(_) => false [owise]

     syntax Bool ::= isFlexibleUnion(FieldInfo) [function]
     rule isFlexibleUnion(fieldInfo(_:List ListItem(typedDeclaration(T::Type, _)), _, _, _, _, _)) => true
          requires isFlexibleType(T)
     rule isFlexibleUnion(fieldInfo(_:List (ListItem(typedDeclaration(T::Type, _)) => .List), _, _, _, _, _))
          requires notBool isFlexibleType(T)
     rule isFlexibleUnion(_) => false [owise]

    rule isVoidType(t(... st: void)) => true
    rule isVoidType(_) => false [owise]
    rule isVariableLengthArrayType(t(... st: _:SimpleVariableArrayType)) => true
    rule isVariableLengthArrayType(_) => false [owise]
    rule isUnionType(t(... st: unionType(_))) => true
    rule isUnionType(_) => false [owise]
    rule isStructOrUnionType(structOrUnionType) => true
    rule isStructOrUnionType(_) => false [owise]
    rule isAggregateOrUnionType(aggregateOrUnionType) => true
    rule isAggregateOrUnionType(_) => false [owise]
    rule isPointerType(t(... st: pointerType(_))) => true
    rule isPointerType(_) => false [owise]
    rule isPointerUType(ut(... st: pointerType(_))) => true
    rule isPointerUType(_) => false [owise]
    rule isNoType(t(... st: no-type)) => true
    rule isNoType(_) => false [owise]
    rule isIntegerUType(integerUType) => true
    rule isIntegerUType(_) => false [owise]
    rule isIntegerType(integerType) => true
    rule isIntegerType(_) => false [owise]
    rule isSignedIntegerUType(signedIntegerUType) => true
    rule isSignedIntegerUType(_) => false [owise]
    rule isFunctionType(t(... st: functionType(...))) => true
    rule isFunctionType(_) => false [owise]
    rule isFloatUType(ut(... st: _:SimpleFloatType)) => true
    rule isFloatUType(_) => false [owise]
    rule isFloatType(t(... st: _:SimpleFloatType)) => true
    rule isFloatType(_) => false [owise]
    rule isCharUType(charUType) => true
    rule isCharUType(_) => false [owise]
    rule isCharType(charType) => true
    rule isCharType(_) => false [owise]
    rule isBoolUType(ut(... st: bool)) => true
    rule isBoolUType(_) => false [owise]
    rule isBoolType(t(... st: bool)) => true
    rule isBoolType(_) => false [owise]
    rule isBitfieldType(t(... st: bitfieldType(...))) => true
    rule isBitfieldType(_) => false [owise]
    rule isBasicType(T::Type) => isArithmeticType(T) orBool isVoidType(T) orBool isNoType(T)
    rule isArrayOrFunctionType(arrayOrFunctionType) => true
    rule isArrayOrFunctionType(_) => false [owise]
    rule isArrayOrFunctionUType(arrayOrFunctionUType) => true
    rule isArrayOrFunctionUType(_) => false [owise]
    rule isArrayType(t(... st: _:SimpleArrayType)) => true
    rule isArrayType(_) => false [owise]
    rule isIncompleteArrayType(t(... st: _:SimpleIncompleteArrayType)) => true
    rule isIncompleteArrayType(_) => false [owise]
    rule isArithmeticType(arithmeticType) => true
    rule isArithmeticType(_) => false [owise]
    rule isUCharType(t(... st: unsignedCharType)) => true
    rule isUCharType(_) => false [owise]

endmodule
