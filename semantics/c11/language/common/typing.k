module C-TYPING-SORTS
     syntax EffectiveType ::= Type
     syntax Type ::= FunctionType
     syntax FunctionType
     syntax UType
     syntax DType
     syntax SimpleType
     syntax SimpleUType
     syntax FieldInfo
     syntax TagInfo
     syntax Variadic
endmodule

module C-TYPING-SYNTAX
     imports C-TYPING-SORTS

     imports BASIC-K
     imports MEMORY-SYNTAX
     imports STRING-SYNTAX
     imports MAP

     syntax CValue ::= Int // defined in C-DYNAMIC-SYNTAX
     syntax Qualifier // defined in C-SYNTAX
     syntax Storage // defined in C-SYNTAX

     syntax Type ::= t(Quals, Set, SimpleType) // possibly-qualified type
     syntax UType ::= ut(Set, SimpleUType)     // unqualified type
     syntax DType ::= typedDeclaration(Type, CId)

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
     syntax EnumInfo ::= enumAlias(SimpleType)
     syntax TagInfo ::= FieldInfo | EnumInfo
     syntax SimpleType ::= getEnumAlias(TagId) [function]
     syntax List ::= getFields(FieldInfo) [function]
     syntax Map  ::= getFieldsTypes(FieldInfo) [function]
     syntax Map  ::= getFieldsOffsets(FieldInfo) [function]
     syntax Int  ::= getOffsetForField(CId, Type, FieldInfo) [function]
     syntax Type ::= getTypeForField(CId, List) [function]

     syntax Bool ::= isCompletePointerType(Type) [function]
     syntax Bool ::= isCompleteType(Type) [function]
     syntax Bool ::= isConstType(Type) [function]
     syntax Bool ::= isFlexibleArrayType(Type) [function]
     syntax Bool ::= isFunctionPointerType(Type) [function]
     syntax Bool ::= isIncompleteEnumType(Type) [function]
     syntax Bool ::= isIncompleteStructType(Type) [function]
     syntax Bool ::= isIncompleteUnionType(Type) [function]
     syntax Bool ::= isOldStyleFunctionType(Type) [function]
     syntax Bool ::= isVariablyModifiedType(Type) [function]
     syntax Bool ::= isVolatileType(Type) [function]
     syntax Bool ::= isWCharType(Type) [function]

     // Storage class specifiers.
     syntax Bool ::= isExternType(Type) [function]
     syntax Bool ::= isStaticType(Type) [function]
     syntax Bool ::= isRegisterType(Type) [function]

     // Type qualifiers.
     syntax Bool ::= isRestrictType(Type) [function]

     syntax Set ::= "typeQualifiers" [function]
     syntax Set ::= "storageSpecifiers" [function]
     syntax Set ::= "functionSpecifiers" [function]

     // Basic types
     syntax SimpleBitfieldType ::= SimpleSignedBitfieldType | SimpleUnsignedBitfieldType
                                 | bitfieldType(SimpleType, Int)
     syntax SimpleSignedBitfieldType ::= bitfieldType(SimpleSignedType, Int)
     syntax SimpleUnsignedBitfieldType ::= bitfieldType(SimpleUnsignedType, Int)

     syntax SimpleSignedType ::= "short-int" | SimpleSignedIntType
                               | "long-int" | "long-long-int"
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
     syntax FieldInfo ::= getFieldInfo(Type) [function]
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
                    | ArrayOrFunctionUType
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
     syntax PointerOrArrayType ::= PointerType | ArrayType

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
     syntax Bool ::= inRange(CValue, UType) [function]

     syntax Modifier ::= "noModifier"

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

     syntax Bool ::= sameAlignas(Set, Set) [function]
     syntax Int ::= getAlignasMod(Set) [function]

     syntax Modifier ::= readFrom(SymLoc, Int)
     // Lock an offset into a type to a certain type, for the purposes of
     // setting active union variants for getTypesAtOffset. Note that we
     // propagate these locks up through aggregates (which is the reason for
     // the offset) because we need copies of the type information for fields
     // stored in the global <tags> cell.
     syntax Modifier ::= lock(Int, Type)

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
     syntax Type ::= addStorage(Storage, Type) [function]

     syntax Type ::= addModifiers(Set, Type) [function]
     syntax Type ::= addModifier(Modifier, Type) [function]

     syntax UType ::= addModifiers(Set, UType) [function]
     syntax UType ::= addModifier(Modifier, UType) [function]

     syntax Type ::= innerType(Type) [function]
     syntax Type ::= innerType(UType) [function]

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

     // Returns all types at an offset -- i.e., for a struct, union, or array,
     // it'll return the struct/union/array type in addition to the type or
     // types of its members. It only returns the type of the active variant of
     // a union, if there is one. Otherwise, it returns the types of all
     // variants.
     syntax List ::= getTypesAtOffset(Type, Int) [function]

     syntax Bool ::= isTruthValue(RValue) [function]

     syntax KItem ::= stabilizeVLA(Type)

     syntax Bool ::= isStructOrUnionKLabel(K) [function, klabelPredicate]

     // Turns old-style param list into the empty list so that arguments will
     // be promoted on call.
     syntax Type ::= toPrototype(Type) [function]

     syntax Type ::= unlock(Int, Type) [function]
     syntax Type ::= unlockAll(Type) [function]

     // A flexible type is a struct with a flexible array member or a union
     // with a member that has a flexible type.
     syntax Bool ::= isFlexibleType(Type) [function]

     // Locks the type of the flexible array member to a fixed array.
     syntax Type ::= lockFlexibleStruct(Type, Int) [function]

     // moved from BITSIZE because type compatibility depends on it quite indirectly
     syntax Int ::= numBytes(SimpleType) [function]

     syntax Int ::= typePrecision(UType) [function]
     syntax Int ::= typeExponent(UType) [function]
     syntax Float ::= Int2CFloat(UType, Int) [function]
     syntax Float ::= roundCFloat(UType, Float) [function]
     syntax Float ::= zeroCFloat(UType) [function]
     syntax Int ::= "maxFloatPrecision" [function]
     syntax Int ::= "maxFloatExponent" [function]

     syntax Bool ::= anonInDecls(List) [function]
     // Search - anonymous fields
     syntax ProvInfo ::= provInfo(CId, Bool, FieldInfo)
     syntax List  ::= searchAnons(CId, Bool, FieldInfo, Int, List, List) [function]

     syntax UType ::= arrayToPtrType(Type) [function]

     syntax String ::= showType(Type) [function]
     syntax String ::= showDType(DType) [function]
endmodule
