module C-TYPING-PREDICATES
     imports C-TYPING-SYNTAX
     imports BOOL
     imports K-EQUAL
     imports COMPAT-SYNTAX
     imports SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX

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
     rule isCompleteType(T:EnumType) => notBool isIncompleteEnumType(T)
     rule isCompleteType(T:StructType) => notBool isIncompleteStructType(T)
     rule isCompleteType(T:UnionType) => notBool isIncompleteUnionType(T)
     rule isCompleteType(_:VoidType) => false
     rule isCompleteType(_:NoType) => false
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

     rule hasReadFrom(ut(Mods:Set, _)) => some(Mods, #klabel(`isReadFrom`))

     syntax Bool ::= isReadFrom(K) [function]
     rule isReadFrom(readFrom(_, _)) => true
     rule isReadFrom(_) => false [owise]

     rule isTruthValue(tv(V::CValue, ut(_, T::SimpleUType)))
          => T ==K int andBool (V ==K 0 orBool V ==K 1)

     rule isFlexibleType(dynamicType(T::Type)) => isFlexibleType(T)
     rule isFlexibleType(T:StructType) => isFlexibleStruct(getFields(T))
     rule isFlexibleType(T:UnionType) => isFlexibleUnion(getFields(T))
     rule isFlexibleType(_) => false [owise]

     syntax Bool ::= isFlexibleStruct(FieldInfo) [function]
     rule isFlexibleStruct(fieldInfo(_:List ListItem(typedDeclaration(T::Type, _)), _, _, _, _)) => true
          requires isFlexibleArrayType(T)
     rule isFlexibleStruct(_) => false [owise]

     syntax Bool ::= isFlexibleUnion(FieldInfo) [function]
     rule isFlexibleUnion(fieldInfo(_:List ListItem(typedDeclaration(T::Type, _)), _, _, _, _)) => true
          requires isFlexibleType(T)
     rule isFlexibleUnion(fieldInfo(_:List (ListItem(typedDeclaration(T::Type, _)) => .List), _, _, _, _))
          requires notBool isFlexibleType(T)
     rule isFlexibleUnion(_) => false [owise]

endmodule
