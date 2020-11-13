module C-TYPING-SORTS
     syntax EffectiveType ::= Type
     syntax Type
     syntax CId
     syntax UType
     syntax DType
     syntax ParamDecl

     syntax SimpleType
     syntax SimpleUType
     syntax FieldInfo
     syntax TagInfo
     syntax Variadic
endmodule

module C-TYPING-MACROS-SYNTAX
     imports BASIC-K
     syntax SimpleIntegerType ::= "signedCharType" | "unsignedCharType"
     syntax SimpleSignedCharType ::= "signed-char"
     syntax SimpleUnsignedCharType ::= "unsigned-char"
     syntax SimpleCharType ::= "char"
     syntax SimpleIntegerType ::= SimpleCharType
                                | SimpleSignedType
                                | SimpleUnsignedType
     syntax SimpleUnsignedType ::= SimpleUnsignedCharType
     syntax SimpleSignedType ::= SimpleSignedCharType
endmodule

module C-TYPING-SYNTAX
     imports C-TYPING-SORTS

     imports MEMORY-SYNTAX
     imports STRING-SYNTAX
     imports MAP

     imports C-TYPING-MACROS

     syntax Qualifier // defined in C-SYNTAX
     syntax StorageClassSpecifier // defined in C-SYNTAX
     syntax Location  // defined in C-TRANSLATION-INIT

     syntax Type ::= t(q: Quals, m: Set, st: SimpleType) // possibly-qualified type
     syntax UType ::= ut(m: Set, st: SimpleUType)     // unqualified type
     syntax DType ::= typedDeclaration(Type, CId)
     syntax ParamDecl ::= Type | DType

     syntax Type ::= type(K) [function]
     syntax UType ::= utype(K) [function]

     // --------------

     syntax CId ::= typedef(CId) [klabel(typedef1)]
     syntax CId ::= vararg(Int)

     syntax Bool ::= Type "==Type" Type [function, klabel(equalType)]
     syntax Bool ::= Type "=/=Type" Type [function, klabel(notEqualType)]

     syntax Bool ::= UType "==Type" UType [function, klabel(equalUType)]
     syntax Bool ::= UType "=/=Type" UType [function, klabel(notEqualUType)]

     syntax SimpleType ::= simpleType(Type) [function]

     // TODO(chathhorn): move?
     // Offsets and field names for structs and unions.
     syntax FieldInfo ::= fieldInfo(List, Int, Map, Map, Set)
     syntax EnumInfo ::= enumInfo(enumAlias: SimpleIntegerType, ctMap: Map)
     syntax TagInfo ::= FieldInfo | EnumInfo
     syntax SimpleIntegerType ::= getEnumAlias(TagId) [function]
     syntax FieldInfo ::= getFields(Type) [function]
     syntax FieldInfo ::= getFields(UType) [function]
     syntax FieldInfo ::= getFlatFields(Type) [function]
     syntax List ::= getFieldNames(Type) [function]
     syntax List ::= getFieldTypes(Type) [function]
     syntax Int  ::= getFieldOffset(CId, Type) [function]
     syntax Type ::= getFieldType(CId, Type) [function]
     syntax Type ::= getActiveVariant(Type) [function]
     syntax Type ::= setActiveVariant(Type, Type) [function]
     syntax CId ::= getActiveVariantId(Type) [function]
     syntax Type ::= setActiveVariantId(CId, Type) [function]
     syntax EffectiveType ::= mergeVariants(EffectiveType, EffectiveType) [function]
     syntax Type ::= clearActiveVariant(Type) [function]
     syntax Int  ::= floorBitOffset(Int, Type) [function]
     syntax Int  ::= ceilBitOffset(Int, Type) [function]
     syntax CId ::= getFieldAtOffset(Int, Type) [function]
     syntax Type ::= getFieldTypeAtOffset(Int, Type) [function]
     syntax Type ::= setFieldType(CId, Type, Type) [function]
     syntax Type ::= setFieldTypeAtOffset(Int, Type, Type) [function]
     syntax Int ::= lastFieldByteOffset(Type) [function]
     syntax Type ::= resizeFlexibleType(Type, CId, Int) [function]
     syntax CId ::= getUnnamed(CId, Type) [function]
     syntax CId ::= getFirstField(Type) [function]

     // These include anonymous structs/unions when looking up fields.
     syntax List ::= findFieldNames(Type) [function]
     syntax Int  ::= findFieldOffset(CId, Type) [function]
     syntax Type ::= findFieldType(CId, Type) [function]
     syntax List ::= findUnnamedBitfields(Type) [function]

     syntax Bool ::= isCompletePointerType(Type) [function]
                   | isCompleteType(Type) [function]
                   | isConstType(Type) [function]
                   | isFlexibleArrayType(Type) [function]
                   | isFunctionPointerType(Type) [function]
                   | isIncompleteEnumType(Type) [function]
                   | isIncompleteStructType(Type) [function]
                   | isIncompleteUnionType(Type) [function]
                   | isOldStyleFunctionType(Type) [function]
                   | isVariablyModifiedType(Type) [function]
                   | isVolatileType(Type) [function]
                   | isWCharType(Type) [function]

     // Storage class specifiers.
     syntax Bool ::= isExternType(Type) [function]
                   | isStaticType(Type) [function]
                   | isRegisterType(Type) [function]
     // Type qualifiers.
                   | isRestrictType(Type) [function]

     syntax Set ::= "typeQualifiers" [function]
                  | "storageSpecifiers" [function]
                  | "functionSpecifiers" [function]

     // Basic types
     syntax SimpleBitfieldType ::= bitfieldType(SimpleType, Int)

     syntax SimpleSignedType ::= "short-int" | SimpleIntType
                               | "long-int" | "long-long-int" | "oversized-int"
     syntax SimpleFloatType ::= "float" | "double" | "long-double" | "oversized-float"
     syntax SimpleIntType ::= "int" | SimpleSignedIntType
     syntax SimpleSignedIntType ::= "signed-int"
     syntax SimpleUnsignedType ::= SimpleBoolType | "unsigned-short-int"
                                 | SimpleUnsignedIntType | "unsigned-long-int"
                                 | "unsigned-long-long-int"
                                 | "unsigned-oversized-int"
     syntax SimpleUnsignedIntType ::= "unsigned-int"
     syntax SimpleBoolType ::= "bool"
     syntax SimpleVoidType ::= "void"
     syntax SimpleNoType ::= "no-type"
     syntax BitfieldFieldType ::= SignedBitfieldFieldType | UnsignedBitfieldFieldType
     syntax SignedBitfieldFieldType ::= SimpleSignedIntType
     syntax UnsignedBitfieldFieldType ::= SimpleUnsignedIntType | SimpleBoolType
     syntax SimpleIntegerType ::= SimpleBitfieldType
                                | BitfieldFieldType

     syntax SimpleBasicType ::= SimpleNoType | SimpleVoidType
                              | SimpleFloatType | SimpleIntegerType
     syntax SimpleNonArrayType ::= SimpleBasicType

     // Composite types
     syntax SimpleFunctionType ::= functionType(UType, List)
     syntax SimplePointerType ::= pointerType(Type)

     syntax SimpleFixedArrayType ::= arrayType(Type, Int)
     syntax SimpleIncompleteArrayType ::= incompleteArrayType(Type)
     syntax SimpleIncompleteArrayType ::= flexibleArrayType(Type)
     syntax SimpleVariableArrayType ::= unspecifiedArrayType(Type)
     syntax SimpleVariableArrayType ::= variableLengthArrayType(Type, K)

     syntax SimpleFixedArrayUType ::= arrayUType(UType, Int)
     syntax SimpleIncompleteArrayUType ::= incompleteArrayUType(UType)
     syntax SimpleIncompleteArrayUType ::= flexibleArrayUType(UType)
     syntax SimpleVariableArrayUType ::= unspecifiedArrayUType(UType)
     syntax SimpleVariableArrayUType ::= variableLengthArrayUType(UType, K)

     syntax SimpleEnumType ::= enumType(TagId)
     syntax SimpleStructType ::= structType(TagId)
     syntax SimpleUnionType ::= unionType(TagId)

     syntax TagId ::= tag(CId, String, BlockRef)
     syntax BlockRef ::= Int | "global"

     syntax SimpleType ::= SimpleArrayType
                         | SimpleNonArrayType
     syntax SimpleUType ::= SimpleArrayUType
                          | SimpleNonArrayType

     syntax SimpleNonArrayType ::= SimpleEnumType
                                 | SimplePointerType
                                 | SimpleStructType
                                 | SimpleUnionType
                                 | SimpleFunctionType

     syntax SimpleArrayType ::= SimpleFixedArrayType | SimpleVariableArrayType | SimpleIncompleteArrayType
     syntax SimpleArrayUType ::= SimpleFixedArrayUType
                               | SimpleVariableArrayUType
                               | SimpleIncompleteArrayUType

     syntax FieldInfo ::= getFieldInfo(TagId) [function]
     syntax TagInfo ::= getTagInfo(TagId) [function]
     syntax CId ::= getTag(TagId) [function]
     syntax TagInfo ::= "#incomplete"

     // These aren't real types, but are values that can appear in type
     // contexts.
     syntax SimpleNonArrayType ::= SimpleTypedefType

     syntax SimpleTypedefType ::= typedefType(CId, Type)
     syntax Variadic ::= "variadic"
     syntax DType ::= Variadic

     syntax UType ::= "structOrUnionUType"
                   | "arrayOrFunctionUType"
                   | "aggregateOrUnionUType"
                   | "pointerOrArrayUType"
                   | "integerUType"
                   | "signedIntegerUType"
                   | "unsignedIntegerUType"
                   | "charUType"
                   | "arithmeticUType"
     syntax Type ::= "structOrUnionType"
                   | "arrayOrFunctionType"
                   | "aggregateOrUnionType"
                   | "pointerOrArrayType"
                   | "integerType"
                   | "signedIntegerType"
                   | "unsignedIntegerType"
                   | "charType"
                   | "arithmeticType"

     rule structOrUnionUType => ut(_, structType(_) #Or unionType(_)) [macro, unboundVariables(_)]
     rule arrayOrFunctionUType => ut(_, arrayUType(_, _) #Or incompleteArrayUType(_) #Or flexibleArrayUType(_) #Or unspecifiedArrayUType(_) #Or variableLengthArrayUType(_, _) #Or functionType(_, _)) [macro, unboundVariables(_)]
     rule aggregateOrUnionUType => ut(_, arrayUType(_, _) #Or incompleteArrayUType(_) #Or flexibleArrayUType(_) #Or unspecifiedArrayUType(_) #Or variableLengthArrayUType(_, _) #Or structType(_) #Or unionType(_)) [macro, unboundVariables(_)]
     rule pointerOrArrayUType => ut(_, arrayUType(_, _) #Or incompleteArrayUType(_) #Or flexibleArrayUType(_) #Or unspecifiedArrayUType(_) #Or variableLengthArrayUType(_, _) #Or pointerType(_)) [macro, unboundVariables(_)]
     rule integerUType => unsignedIntegerUType #Or signedIntegerUType #Or ut(_, enumType(_)) [macro, unboundVariables(_)]
     rule signedIntegerUType => ut(_, short-int #Or int #Or signed-int #Or long-int #Or long-long-int #Or oversized-int #Or signedCharType #Or bitfieldType(short-int #Or int #Or signed-int #Or long-int #Or long-long-int #Or oversized-int #Or signedCharType, _)) [macro, unboundVariables(_)]
     rule unsignedIntegerUType => ut(_, bool #Or unsigned-short-int #Or unsigned-int #Or unsigned-long-int #Or unsigned-long-long-int #Or unsigned-oversized-int #Or unsignedCharType #Or bitfieldType(bool #Or unsigned-short-int #Or unsigned-int #Or unsigned-long-int #Or unsigned-long-long-int #Or unsigned-oversized-int #Or unsignedCharType, _)) [macro, unboundVariables(_)]
     rule charUType => ut(_, signedCharType #Or unsignedCharType) [macro, unboundVariables(_)]
     rule arithmeticUType => integerUType #Or ut(_, float #Or double #Or long-double #Or oversized-float) [macro, unboundVariables(_)]

     rule structOrUnionType => t(_, _, structType(_) #Or unionType(_)) [macro, unboundVariables(_)]
     rule arrayOrFunctionType => t(_, _, arrayType(_, _) #Or incompleteArrayType(_) #Or flexibleArrayType(_) #Or unspecifiedArrayType(_) #Or variableLengthArrayType(_, _) #Or functionType(_, _)) [macro, unboundVariables(_)]
     rule aggregateOrUnionType => t(_, _, arrayType(_, _) #Or incompleteArrayType(_) #Or flexibleArrayType(_) #Or unspecifiedArrayType(_) #Or variableLengthArrayType(_, _) #Or structType(_) #Or unionType(_)) [macro, unboundVariables(_)]
     rule pointerOrArrayType => t(_, _, arrayType(_, _) #Or incompleteArrayType(_) #Or flexibleArrayType(_) #Or unspecifiedArrayType(_) #Or variableLengthArrayType(_, _) #Or pointerType(_)) [macro, unboundVariables(_)]
     rule integerType => unsignedIntegerType #Or signedIntegerType #Or t(_, _, enumType(_)) [macro, unboundVariables(_)]
     rule signedIntegerType => t(_, _, short-int #Or int #Or signed-int #Or long-int #Or long-long-int #Or oversized-int #Or signedCharType #Or bitfieldType(short-int #Or int #Or signed-int #Or long-int #Or long-long-int #Or oversized-int #Or signedCharType, _)) [macro, unboundVariables(_)]
     rule unsignedIntegerType => t(_, _, bool #Or unsigned-short-int #Or unsigned-int #Or unsigned-long-int #Or unsigned-long-long-int #Or unsigned-oversized-int #Or unsignedCharType #Or bitfieldType(bool #Or unsigned-short-int #Or unsigned-int #Or unsigned-long-int #Or unsigned-long-long-int #Or unsigned-oversized-int #Or unsignedCharType, _)) [macro, unboundVariables(_)]
     rule charType => t(_, _, signedCharType #Or unsignedCharType) [macro, unboundVariables(_)]
     rule arithmeticType => integerType #Or t(_, _, float #Or double #Or long-double #Or oversized-float) [macro, unboundVariables(_)]

     syntax Bool ::= isVoidType(Type) [function]
                   | isVariableLengthArrayType(Type) [function]
                   | isUnionType(Type) [function]
                   | isStructOrUnionType(Type) [function]
                   | isAggregateOrUnionType(Type) [function]
                   | isPointerType(Type) [function]
                   | isPointerUType(UType) [function]
                   | isNoType(EffectiveType) [function]
                   | isIntegerUType(UType) [function]
                   | isIntegerType(Type) [function]
                   | isFunctionType(Type) [function]
                   | isFloatUType(UType) [function]
                   | isFloatType(Type) [function]
                   | isCharUType(UType) [function]
                   | isCharType(Type) [function]
                   | isBoolUType(UType) [function]
                   | isBoolType(Type) [function]
                   | isBitfieldType(Type) [function]
                   | isBasicType(Type) [function]
                   | isArrayOrFunctionType(Type) [function]
                   | isArrayOrFunctionUType(UType) [function]
                   | isArrayType(Type) [function]
                   | isIncompleteArrayType(Type) [function]
                   | isArithmeticType(Type) [function]
                   | isSignedIntegerUType(UType) [function]
                   | isUCharType(Type) [function]

     syntax List ::= getParams(Type) [function]
     syntax Type ::= setParams(Type, List) [function]

     syntax Bool ::= hasSameSignedness(UType, UType) [function]
     syntax UType ::= correspondingUnsignedType(UType) [function]
     syntax UType ::= correspondingSignedType(UType) [function]

     syntax Int ::= imin(SimpleIntegerType) [function]
     syntax Int ::= imax(SimpleIntegerType) [function]
     syntax Int ::= min(UType) [function]
     syntax Int ::= max(UType) [function]
     syntax Float ::= fmax(UType) [function]
     syntax Float ::= fmin(UType) [function]
     syntax Bool ::= intInRange(Int, UType) [function]
     syntax Bool ::= withinRange(Int, SimpleIntegerType) [function]
     syntax Bool ::= floatInRange(Float, UType) [function]

     syntax Modifier ::= Packed()

     // Returns both type qualifiers, storage class specifiers, and any the
     // other information stored in the modifiers list (e.g., oldStyle).
     syntax Set ::= getModifiers(Type) [function]
     syntax Set ::= getModifiers(UType) [function]
     // Tag for old-style function defs.
     syntax Modifier ::= "oldStyle"
     // For function array parameters with a static-qualified size.
     syntax Modifier ::= arrayStatic(Int)
     syntax Modifier ::= atomic(Type)
     syntax Modifier ::= alignas(Int)
     syntax Modifier ::= FieldInfo

     syntax Bool ::= sameAlignas(Set, Set) [function]
     syntax Int ::= getAlignasMod(Set) [function]

     syntax Modifier ::= readFrom(SymLoc, Int)

     // Special restrict modifier tagged with a block num.
     syntax Modifier ::= RestrictBlock(Scope)

     syntax Modifier ::= "IntegerConstant"

     syntax Set ::= getStorageSpecifiers(Type) [function]
     syntax Set ::= getFunctionSpecifiers(Type) [function]
     // Gets function and storage specifiers.
     syntax Quals ::= getQualifiers(Type) [function]
     syntax Set ::= getSpecifiers(Type) [function]
     syntax Set ::= getConstants(UType) [function]

     syntax Type ::= stripStorageSpecifiers(Type) [function]
     syntax Type ::= stripFunctionSpecifiers(Type) [function]
     // Strips function and storage specifiers.
     syntax Type ::= stripSpecifiers(Type) [function]
     syntax UType ::= stripSpecifiers(UType) [function]
     syntax Type ::= stripQualifiers(Type) [function]

     syntax Type ::= stripConstants(Type) [function]
     syntax UType ::= stripConstants(UType) [function]
     syntax RValue ::= stripConstants(RValue) [function]

     syntax Type ::= addQualifier(Qualifier, Type) [function]
     syntax Type ::= addQualifiers(Quals, Type) [function]
     syntax Type ::= addStorage(StorageClassSpecifier, Type) [function]

     syntax Type ::= addModifiers(Set, Type) [function]
     syntax Type ::= addModifier(Modifier, Type) [function]

     syntax UType ::= addModifiers(Set, UType) [function]
     syntax UType ::= addModifier(Modifier, UType) [function]

     syntax Type ::= innerType(Type) [function]
     syntax Type ::= innerType(UType) [function]

     // Offset of element in bits.
     syntax Type ::= setElementType(Int, Type, Type) [function]
     syntax Type ::= getElementType(Int, Type) [function]

     syntax Bool ::= fromConstantExpr(UType) [function]
     syntax Bool ::= fromConstantExpr(Type) [function]
     syntax Bool ::= fromConstantExpr(RValue) [function]
     syntax Bool ::= fromConstantExpr(Location) [function]

     syntax Bool ::= isNull(RValue) [function]
     syntax Bool ::= isNullPointerConstant(RValue) [function]
     syntax Bool ::= isNullPointerConstant(Location) [function]

     syntax Bool ::= hasReadFrom(UType) [function]
     syntax SymLoc ::= getReadFromLoc(UType) [function]
     syntax Int ::= getReadFromLen(UType) [function]
     syntax UType ::= updateReadFrom(UType, SymLoc) [function]
     syntax UType ::= updateReadFrom(UType, SymLoc, Int) [function, klabel(updateReadFrom3)]

     syntax List ::= idsFromParams(List) [function]

     syntax Type ::= tagRestrict(Scope, Type) [function]
     syntax Bool ::= hasRestrict(Type) [function]
     syntax Scope ::= getRestrictBlock(Type) [function]

     syntax Int ::= arrayLength(Type) [function]

     syntax Bool ::= isTruthValue(RValue) [function]

     syntax KItem ::= stabilizeVLA(Type)

     // Turns old-style param list into the empty list so that arguments will
     // be promoted on call.
     syntax Type ::= toPrototype(Type) [function]

     // A flexible type is a struct with a flexible array member or a union
     // with a member that has a flexible type.
     syntax Bool ::= isFlexibleType(EffectiveType) [function]

     // moved from BITSIZE because type compatibility depends on it quite indirectly
     syntax Int ::= numBytesArithmetic(SimpleUType) [function]

     syntax Int ::= typePrecision(UType) [function]
     syntax Int ::= typeExponent(UType) [function]
     syntax Float ::= Int2CFloat(UType, Int) [function]
     syntax Float ::= roundCFloat(UType, Float) [function]
     syntax Float ::= zeroCFloat(UType) [function]
     syntax Int ::= "maxFloatPrecision" [function]
     syntax Int ::= "maxFloatExponent" [function]

     // Turn array and function types into pointers.
     syntax Type ::= adjustParam(Type) [function]
     syntax Type ::= arrayToPtrType(Type) [function]

     syntax String ::= showType(Type) [function]
     syntax String ::= showUType(UType) [function]
     syntax String ::= showDType(DType) [function]
     syntax String ::= showEffectiveType(EffectiveType) [function]

     // Effective type of malloced regions.
     syntax DynamicType ::= dynamicType(Type)
     syntax KResult ::= DynamicType
     syntax EffectiveType ::= DynamicType

     syntax Bool ::= allComplete(List) [function]
     syntax FieldInfo ::= makeStructFieldInfo(Bool, List) [function]
     syntax FieldInfo ::= makeUnionFieldInfo(Bool, List) [function]

     // Used to tag lvalues with their last-access type for checking and
     // updating the effective types of accesses.
     syntax Provenance ::= objectType(EffectiveType)

     // Unqualify, array-to-pointer, and function-to-pointer conversion.
     syntax UType ::= rvalType(Type) [function]

endmodule
