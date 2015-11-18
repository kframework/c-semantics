require "typing/compatibility.k"
require "typing/misc.k"
require "typing/predicates.k"

module C-TYPING-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports MAP

     syntax CId ::= typedef(CId)
     syntax CId ::= unnamed(Int, String)
     syntax CId ::= vararg(Int)

     syntax Bool ::= Type "==Type" Type [function]
     syntax Bool ::= Type "=/=Type" Type [function]

     syntax SimpleType ::= simpleType(Type) [function]

     // TODO(chathhorn): move?
     // Offsets and field names for structs and unions.
     syntax FieldInfo ::= fieldInfo(List, Int, Map, Map)

     syntax Bool ::= isCompletePointerType(Type) [function]
     syntax Bool ::= isCompleteType(Type) [function]
     syntax Bool ::= isConstType(Type) [function]
     syntax Bool ::= isFlexibleArrayType(Type) [function]
     syntax Bool ::= isFunctionPointerType(Type) [function]
     syntax Bool ::= isIncompleteStructType(Type) [function]
     syntax Bool ::= isIncompleteUnionType(Type) [function]
     syntax Bool ::= isOldStyleFunctionType(Type) [function]
     syntax Bool ::= isTypedDeclaration(Type) [function]
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

     // Basic types
     syntax SimpleCharType ::= "char" [function]
     syntax SimpleSignedType ::= "short-int" | "int"
                               | "long-int" | "long-long-int" 
                               | SimpleSignedCharType
     syntax SimpleFloatType ::= "float" | "double" | "long-double"
     syntax SimpleSignedCharType ::= "signed-char"
     syntax SimpleUnsignedCharType ::= "unsigned-char"
     syntax SimpleCharType ::= SimpleSignedCharType | SimpleUnsignedCharType
     syntax SimpleUnsignedType ::= SimpleBoolType | "unsigned-short-int" 
                                 | "unsigned-int" | "unsigned-long-int" 
                                 | "unsigned-long-long-int" 
                                 | SimpleUnsignedCharType
     syntax SimpleBoolType ::= "bool"
     syntax SimpleVoidType ::= "void"
     syntax SimpleNoType ::= "no-type"
     syntax SimpleType ::= SimpleNoType | SimpleVoidType | SimpleCharType 
                         | SimpleFloatType | SimpleUnsignedType 
                         | SimpleSignedType

     // Composite types
     syntax SimpleEnumType ::= enumType(CId)
     syntax SimpleBitfieldType ::= bitfieldType(Type, Int)
     syntax SimpleFunctionType ::= functionType(Type, List)
     syntax SimplePointerType ::= pointerType(Type)

     syntax SimpleFixedArrayType ::= arrayType(Type, Int)
     syntax SimpleIncompleteArrayType ::= incompleteArrayType(Type)
     syntax SimpleIncompleteArrayType ::= flexibleArrayType(Type)
     syntax SimpleVariableArrayType ::= variableLengthArrayType(Type, K)

     syntax SimpleStructType ::= structType(StructId)
     syntax SimpleUnionType ::= unionType(StructId)
     syntax StructId ::= global(CId, String)
                       | local(CId, String, Int)

     syntax SimpleType ::= SimpleFixedArrayType
                         | SimpleEnumType
                         | SimplePointerType
                         | SimpleFixedArrayType
                         | SimpleVariableArrayType
                         | SimpleIncompleteArrayType
                         | SimpleStructType
                         | SimpleUnionType
                         | SimpleBitfieldType
                         | SimpleFunctionType

     syntax SimpleBitfieldType ::= SimpleSignedBitfieldType | SimpleUnsignedBitfieldType
     syntax SimpleSignedBitfieldType ::= bitfieldType(SignedIntegerType, Int)
     syntax SimpleUnsignedBitfieldType ::= bitfieldType(UnsignedIntegerType, Int)
 
     syntax FieldInfo ::= getFieldInfo(StructId) [function]
     syntax FieldInfo ::= getFieldInfo(Type) [function]
     syntax CId ::= getTag(StructId) [function]
     syntax FieldInfo ::= "#incomplete"

     // These aren't real types, but are values that can appear in type
     // contexts.
     syntax SimpleType ::= typedefType(CId, Type)
     syntax Type ::= "variadic"

     syntax Type ::= BasicType | PointerType | AggregateOrUnionType 
                   | StructOrUnionType | ArrayOrFunctionType
     syntax AggregateOrUnionType ::= AggregateType | UnionType
     syntax AggregateType ::= ArrayType | StructType
     syntax StructOrUnionType ::= StructType | UnionType
     syntax ArrayOrFunctionType ::= ArrayType | FunctionType
     syntax BasicType ::= ArithmeticType | VoidType | NoType
     syntax ArithmeticType ::= IntegerType | FloatType
     syntax IntegerType ::= UnsignedIntegerType | SignedIntegerType | CharType | BitfieldType
     syntax SignedIntegerType ::= SCharType | SignedBitfieldType
     syntax UnsignedIntegerType ::= UCharType | BoolType | UnsignedBitfieldType
     syntax CharType ::= UCharType | SCharType
     syntax BitfieldType ::= UnsignedBitfieldType | SignedBitfieldType
     syntax ArrayType ::= FixedLengthArrayType | IncompleteArrayType
                        | VariableLengthArrayType
     syntax PointerOrArrayType ::= PointerType | ArrayType

     syntax FunctionType
     syntax IncompleteArrayType
     syntax SignedBitfieldType
     syntax StructType
     syntax UnionType
     syntax UnsignedBitfieldType

     syntax UnsignedIntegerType ::= t(Set, SimpleUnsignedType)
     syntax UnsignedIntegerType ::= typedDeclaration(UnsignedIntegerType, CId)
     syntax SignedIntegerType ::= t(Set, SimpleSignedType)
     syntax SignedIntegerType ::= typedDeclaration(SignedIntegerType, CId)
     syntax FloatType ::= t(Set, SimpleFloatType)
     syntax FloatType ::= typedDeclaration(FloatType, CId)
     syntax UCharType ::= t(Set, SimpleUnsignedCharType)
     syntax UCharType ::= typedDeclaration(UCharType, CId)
     syntax SCharType ::= t(Set, SimpleSignedCharType)
     syntax SCharType ::= typedDeclaration(SCharType, CId)
     syntax PointerType ::= t(Set, SimplePointerType)
     syntax PointerType ::= typedDeclaration(PointerType, CId)
     syntax BoolType ::= t(Set, SimpleBoolType)
     syntax BoolType ::= typedDeclaration(BoolType, CId)
     syntax FixedLengthArrayType ::= t(Set, SimpleFixedArrayType)
     syntax FixedLengthArrayType ::= typedDeclaration(FixedLengthArrayType, CId)
     syntax VariableLengthArrayType ::= t(Set, SimpleVariableArrayType)
     syntax VariableLengthArrayType ::= typedDeclaration(VariableLengthArrayType, CId)
     syntax VoidType ::= t(Set, SimpleVoidType)
     syntax VoidType ::= typedDeclaration(VoidType, CId)
     syntax NoType ::= t(Set, SimpleNoType)
     syntax NoType ::= typedDeclaration(NoType, CId)
     syntax StructType ::= t(Set, SimpleStructType)
     syntax StructType ::= typedDeclaration(StructType, CId)
     syntax UnionType ::= t(Set, SimpleUnionType)
     syntax UnionType ::= typedDeclaration(UnionType, CId)
     syntax IncompleteArrayType ::= t(Set, SimpleIncompleteArrayType)
     syntax IncompleteArrayType ::= typedDeclaration(IncompleteArrayType, CId)
     syntax SignedBitfieldType ::= t(Set, SimpleSignedBitfieldType)
     syntax SignedBitfieldType ::= typedDeclaration(SignedBitfieldType, CId)
     syntax UnsignedBitfieldType ::= t(Set, SimpleUnsignedBitfieldType)
     syntax UnsignedBitfieldType ::= typedDeclaration(UnsignedBitfieldType, CId)
     syntax FunctionType ::= t(Set, SimpleFunctionType)
     syntax FunctionType ::= typedDeclaration(FunctionType, CId)

     syntax List ::= getParams(Type) [function]
     syntax Type ::= setParams(Type, List) [function]
     syntax Type ::= getReturn(Type) [function]

     syntax Bool ::= hasSameSignedness(Type, Type) [function]
     syntax Type ::= correspondingUnsignedType(Type) [function]
     syntax Type ::= correspondingSignedType(Type) [function]

     syntax Int ::= min(Type) [function]
     syntax Int ::= max(Type) [function]
     syntax Bool ::= inRange(CValue, Type) [function]

     syntax Modifier ::= Storage | CVSpecifier
     syntax Modifier ::= "noModifier"

     // Returns both type qualifiers, storage class specifiers, and any the
     // other information stored in the modifiers list (e.g., oldStyle).
     syntax Set ::= getModifiers(Type) [function]
     // Tag for old-style function defs.
     syntax Modifier ::= "oldStyle"
     // For function array parameters with a static-qualified size.
     syntax Modifier ::= arrayStatic(Int)
     syntax Modifier ::= atomic(Type)
     syntax Modifier ::= alignas(Int)

     syntax Modifier ::= readFrom(SymLoc, Int)

     // Special restrict modifier tagged with a block num.
     syntax Modifier ::= RestrictBlock(Scope)

     syntax Modifier ::= "IntegerConstant"

     syntax Set ::= getStorageSpecifiers(Type) [function]
     syntax Set ::= getFunctionSpecifiers(Type) [function]
     // Gets function and storage specifiers.
     syntax Set ::= getSpecifiers(Type) [function]
     syntax Set ::= getQualifiers(Type) [function]
     syntax Set ::= getConstants(Type) [function]

     syntax Type ::= stripStorageSpecifiers(Type) [function]
     syntax Type ::= stripFunctionSpecifiers(Type) [function]
     // Strips function and storage specifiers.
     syntax Type ::= stripSpecifiers(Type) [function]
     syntax Type ::= stripQualifiers(Type) [function]
     syntax Type ::= stripConstants(Type) [function]
     syntax RValue ::= stripConstants(RValue) [function, klabel(stripConstants2)]
     syntax Type ::= stripAlignas(Type) [function]

     syntax Type ::= addQualifier(CVSpecifier, Type) [function]
     syntax Type ::= addQualifiers(Set, Type) [function]
     syntax Type ::= addStorage(Storage, Type) [function]
     syntax Type ::= addModifiers(Set, Type) [function]
     syntax Type ::= addModifier(Modifier, Type) [function]

     syntax Type ::= typedDeclaration(Type, CId)
          [latex(\terminal{typedDecl}\!({#1},{#2}\!))]

     syntax Type ::= innerType(Type) [function]

     syntax Bool ::= isNullPointerConstant(RValue) [function]
     syntax Bool ::= fromConstantExpr(Type) [function]

     syntax Bool ::= hasReadFrom(Type) [function]
     syntax Modifier ::= getReadFrom(Type) [function]
     syntax SymLoc ::= getReadFromLoc(Type) [function]
     syntax Int ::= getReadFromLen(Type) [function]
     syntax Type ::= stripReadFrom(Type) [function]

     syntax List ::= idsFromParams(List) [function]

     syntax Type ::= tagRestrict(Scope, Type) [function]
     syntax Scope ::= getRestrictBlock(Type) [function]

     syntax Int ::= arrayLength(Type) [function]

     syntax Bool ::= hasAlignas(Type) [function]
     syntax Bool ::= hasAlignasMod(Set) [function]

     // Returns the "biggest" type at that offset -- i.e., for a struct, union,
     // or array, it'll return the struct/union/array type and not the type of
     // its first member. Returns no-type when nothing seems to be aligned at
     // that offset.
     syntax Type ::= getTypeAtOffset(Type, Int) [function]

     syntax Bool ::= isTruthValue(RValue) [function]

     syntax KItem ::= stabilizeVLA(Type)
endmodule

module C-TYPING
     imports C-TYPING-COMPATIBILITY
     imports C-TYPING-MISC
     imports C-TYPING-PREDICATES
endmodule
