module C-TYPING-SORTS
     syntax EffectiveType ::= Type
     syntax Type ::= FunctionType
     syntax CId
     syntax FunctionType
     syntax UType
     syntax DType
     syntax ParamDecl

     syntax SimpleType
     syntax SimpleUType
     syntax FieldInfo
     syntax TagInfo
     syntax Variadic
     syntax StructOrUnionType
endmodule

module C-TYPING-SYNTAX
     imports C-TYPING-SORTS

     imports BASIC-K
     imports MEMORY-SYNTAX
     imports STRING-SYNTAX
     imports MAP

     syntax Qualifier // defined in C-SYNTAX
     syntax StorageClassSpecifier // defined in C-SYNTAX

     syntax Type ::= t(Quals, Set, SimpleType) // possibly-qualified type
     syntax UType ::= ut(Set, SimpleUType)     // unqualified type
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
     syntax EnumInfo ::= enumInfo(enumAlias: SimpleBasicType, ctMap: Map)
     syntax TagInfo ::= FieldInfo | EnumInfo
     syntax SimpleBasicType ::= getEnumAlias(TagId) [function]
     syntax FieldInfo ::= getFields(StructOrUnionType) [function]
     syntax FieldInfo ::= getFields(StructOrUnionUType) [function]
     syntax FieldInfo ::= getFlatFields(StructOrUnionType) [function]
     syntax List ::= getFieldNames(Type) [function]
     syntax List ::= getFieldTypes(StructOrUnionType) [function]
     syntax Int  ::= getFieldOffset(CId, StructOrUnionType) [function]
     syntax Type ::= getFieldType(CId, StructOrUnionType) [function]
     syntax Type ::= getActiveVariant(UnionType) [function]
     syntax UnionType ::= setActiveVariant(Type, UnionType) [function]
     syntax CId ::= getActiveVariantId(UnionType) [function]
     syntax UnionType ::= setActiveVariantId(CId, UnionType) [function]
     syntax EffectiveType ::= mergeVariants(EffectiveType, EffectiveType) [function]
     syntax Type ::= clearActiveVariant(Type) [function]
     syntax Int  ::= floorBitOffset(Int, Type) [function]
     syntax Int  ::= ceilBitOffset(Int, Type) [function]
     syntax CId ::= getFieldAtOffset(Int, StructOrUnionType) [function]
     syntax Type ::= getFieldTypeAtOffset(Int, StructOrUnionType) [function]
     syntax StructOrUnionType ::= setFieldType(CId, Type, StructOrUnionType) [function]
     syntax StructOrUnionType ::= setFieldTypeAtOffset(Int, Type, StructOrUnionType) [function]
     syntax Int ::= lastFieldByteOffset(StructType) [function]
     syntax StructOrUnionType ::= resizeFlexibleType(StructOrUnionType, CId, Int) [function]
     syntax CId ::= getUnnamed(CId, StructOrUnionType) [function]
     syntax CId ::= getFirstField(StructOrUnionType) [function]

     // These include anonymous structs/unions when looking up fields.
     syntax List ::= findFieldNames(Type) [function]
     syntax Int  ::= findFieldOffset(CId, StructOrUnionType) [function]
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
     syntax SimpleBitfieldType ::= SimpleSignedBitfieldType | SimpleUnsignedBitfieldType
                                 | bitfieldType(SimpleType, Int)
     syntax SimpleSignedBitfieldType ::= bitfieldType(SimpleSignedType, Int)
     syntax SimpleUnsignedBitfieldType ::= bitfieldType(SimpleUnsignedType, Int)

     syntax SimpleSignedType ::= "short-int" | SimpleSignedIntType
                               | "long-int" | "long-long-int" | "oversized-int"
                               | SimpleSignedCharType
                               | SimpleSignedBitfieldType
     syntax SimpleFloatType ::= "float" | "double" | "long-double"
     syntax SimpleSignedCharType ::= "signed-char"
     syntax SimpleSignedIntType ::= "int"
     syntax SimpleUnsignedCharType ::= "unsigned-char"
     syntax SimpleCharType ::= "char"
     syntax SimpleUnsignedType ::= SimpleBoolType | "unsigned-short-int"
                                 | SimpleUnsignedIntType | "unsigned-long-int"
                                 | "unsigned-long-long-int"
                                 | "unsigned-oversized-int"
                                 | SimpleUnsignedCharType
                                 | SimpleUnsignedBitfieldType
     syntax SimpleUnsignedIntType ::= "unsigned-int"
     syntax SimpleBoolType ::= "bool"
     syntax SimpleVoidType ::= "void"
     syntax SimpleNoType ::= "no-type"
     syntax BitfieldFieldType ::= SignedBitfieldFieldType | UnsignedBitfieldFieldType
     syntax SignedBitfieldFieldType ::= SimpleSignedIntType
     syntax UnsignedBitfieldFieldType ::= SimpleUnsignedIntType | SimpleBoolType
     syntax SimpleIntegerType ::= SimpleSignedType | SimpleUnsignedType
                                | SimpleBitfieldType
                                | BitfieldFieldType
                                | SimpleCharType

     syntax SimpleBasicType ::= SimpleNoType | SimpleVoidType
                              | SimpleFloatType | SimpleIntegerType
     syntax SimpleType ::= SimpleBasicType
     syntax SimpleUType ::= SimpleBasicType

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
                         | SimpleEnumType
                         | SimplePointerType
                         | SimpleStructType
                         | SimpleUnionType
                         | SimpleFunctionType
     syntax SimpleUType ::= SimpleArrayUType
                          | SimpleEnumType
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
     syntax SimpleType ::= SimpleTypedefType
     syntax SimpleUType ::= SimpleTypedefType

     syntax SimpleTypedefType ::= typedefType(CId, Type)
     syntax Variadic ::= "variadic"
     syntax DType ::= Variadic

     syntax Type ::= BasicType | PointerType | AggregateOrUnionType
                   | StructOrUnionType | ArrayOrFunctionType
     syntax UType ::= PointerUType
                    | StructOrUnionUType | ArrayOrFunctionUType
                    | IntegerUType
                    | FloatUType

     syntax AggregateOrUnionType ::= AggregateType | UnionType
     syntax AggregateType ::= ArrayType | StructType
     syntax StructOrUnionType ::= StructType | UnionType
     syntax ArrayOrFunctionType ::= ArrayType | FunctionType
     syntax BasicType ::= ArithmeticType | VoidType | NoType
     syntax ArithmeticType ::= IntegerType | FloatType
     syntax IntegerType ::= UnsignedIntegerType | SignedIntegerType | CharType
                          | BitfieldType | EnumType
     syntax SignedIntegerType ::= SCharType | SignedBitfieldType
     syntax UnsignedIntegerType ::= UCharType | BoolType | UnsignedBitfieldType
     syntax CharType ::= UCharType | SCharType
     syntax BitfieldType ::= UnsignedBitfieldType | SignedBitfieldType
                           | t(Quals, Set, SimpleBitfieldType)
     syntax ArrayType ::= FixedLengthArrayType | IncompleteArrayType
                        | VariableLengthArrayType
                        | t(Quals, Set, SimpleArrayType)
     syntax PointerOrArrayType ::= PointerType | ArrayType

     syntax StructOrUnionUType ::= StructUType | UnionUType
     syntax ArrayOrFunctionUType ::= FunctionUType
                                   | FixedLengthArrayUType | IncompleteArrayUType
                                   | VariableLengthArrayUType
     syntax CharUType ::= SCharUType | UCharUType
     syntax IntegerUType ::= UnsignedIntegerUType | SignedIntegerUType | BitfieldUType | CharUType
     syntax SignedIntegerUType ::= SCharUType | SignedBitfieldUType
     syntax UnsignedIntegerUType ::= UCharUType | BoolUType | UnsignedBitfieldUType
     syntax BitfieldUType ::= SignedBitfieldUType | UnsignedBitfieldUType
                            | ut(Set, SimpleBitfieldType)

     syntax UnsignedIntegerType ::= t(Quals, Set, SimpleUnsignedType)
     syntax SignedIntegerType ::= t(Quals, Set, SimpleSignedType)
     syntax FloatType ::= t(Quals, Set, SimpleFloatType)
     syntax UCharType ::= t(Quals, Set, SimpleUnsignedCharType)
     syntax SCharType ::= t(Quals, Set, SimpleSignedCharType)
     syntax PointerType ::= t(Quals, Set, SimplePointerType)
     syntax BoolType ::= t(Quals, Set, SimpleBoolType)
     syntax FixedLengthArrayType ::= t(Quals, Set, SimpleFixedArrayType)
     syntax VariableLengthArrayType ::= t(Quals, Set, SimpleVariableArrayType)
     syntax VoidType ::= t(Quals, Set, SimpleVoidType)
     syntax NoType ::= t(Quals, Set, SimpleNoType)
     syntax EnumType ::= t(Quals, Set, SimpleEnumType)
     syntax StructType ::= t(Quals, Set, SimpleStructType)
     syntax UnionType ::= t(Quals, Set, SimpleUnionType)
     syntax IncompleteArrayType ::= t(Quals, Set, SimpleIncompleteArrayType)
     syntax SignedBitfieldType ::= t(Quals, Set, SimpleSignedBitfieldType)
     syntax UnsignedBitfieldType ::= t(Quals, Set, SimpleUnsignedBitfieldType)
     syntax FunctionType ::= t(Quals, Set, SimpleFunctionType)

     syntax UnsignedIntegerUType ::= ut(Set, SimpleUnsignedType)
     syntax SignedIntegerUType ::= ut(Set, SimpleSignedType)
     syntax FloatUType ::= ut(Set, SimpleFloatType)
     syntax UCharUType ::= ut(Set, SimpleUnsignedCharType)
     syntax SCharUType ::= ut(Set, SimpleSignedCharType)
     syntax PointerUType ::= ut(Set, SimplePointerType)
     syntax BoolUType ::= ut(Set, SimpleBoolType)
     syntax FixedLengthArrayUType ::= ut(Set, SimpleFixedArrayUType)
     syntax VariableLengthArrayUType ::= ut(Set, SimpleVariableArrayUType)
     syntax StructUType ::= ut(Set, SimpleStructType)
     syntax UnionUType ::= ut(Set, SimpleUnionType)
     syntax IncompleteArrayUType ::= ut(Set, SimpleIncompleteArrayUType)
     syntax SignedBitfieldUType ::= ut(Set, SimpleSignedBitfieldType)
     syntax UnsignedBitfieldUType ::= ut(Set, SimpleUnsignedBitfieldType)
     syntax FunctionUType ::= ut(Set, SimpleFunctionType)

     syntax List ::= getParams(Type) [function]
     syntax Type ::= setParams(Type, List) [function]

     syntax Bool ::= hasSameSignedness(UType, UType) [function]
     syntax UType ::= correspondingUnsignedType(UType) [function]
     syntax UType ::= correspondingSignedType(UType) [function]

     syntax Int ::= min(UType) [function]
     syntax Int ::= max(UType) [function]
     syntax Float ::= fmax(UType) [function]
     syntax Float ::= fmin(UType) [function]
     syntax Bool ::= intInRange(Int, IntegerUType) [function]
     syntax Bool ::= floatInRange(Float, FloatUType) [function]

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
     syntax ArrayType ::= setElementType(Int, Type, ArrayType) [function]
     syntax Type ::= getElementType(Int, ArrayType) [function]

     syntax Bool ::= fromConstantExpr(UType) [function]
     syntax Bool ::= fromConstantExpr(Type) [function]
     syntax Bool ::= fromConstantExpr(RValue) [function]

     syntax Bool ::= isNull(RValue) [function]
     syntax Bool ::= isNullPointerConstant(RValue) [function]

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

     syntax Bool ::= isStructOrUnionKLabel(K) [function, klabelPredicate]

     // Turns old-style param list into the empty list so that arguments will
     // be promoted on call.
     syntax Type ::= toPrototype(Type) [function]

     // A flexible type is a struct with a flexible array member or a union
     // with a member that has a flexible type.
     syntax Bool ::= isFlexibleType(EffectiveType) [function]

     // moved from BITSIZE because type compatibility depends on it quite indirectly
     syntax Int ::= numBytes(SimpleType) [function]

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

endmodule
