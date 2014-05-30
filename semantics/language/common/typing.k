require "typing/canonicalization.k"
require "typing/compatibility.k"
require "typing/expr.k"
require "typing/interpretation.k"
require "typing/misc.k"
require "typing/predicates.k"
require "typing/strictness.k"

module C-TYPING-SYNTAX
     syntax KItem ::= typeof(K)
     syntax CId ::= typedef(CId)
     syntax CId ::= unnamed(Int, String)
     syntax CId ::= vararg(Int)

     syntax SimpleType ::= simpleType(Type) [function]

     // TODO(chathhorn): move?
     // Offsets and field names for structs and unions.
     syntax FieldInfo ::= fieldInfo(List, Map, Map)

     // Represents a type before canonicalization.  as in "int *x", first arg
     // is "Int", second arg is "PointerType(JustBase)"
     syntax KItem ::= DeclType(K, K) [avoid, strict(1)] 

     syntax Bool ::= areCompatible(Type, Type) [function]
     syntax Type ::= compositeType(Type, Type) [function]
     
     syntax Bool ::= hasArithmeticType(Type) [function]
     syntax Bool ::= hasCharType(Type) [function]
     syntax Bool ::= isUCharType(Type) [function]
     syntax Bool ::= isWCharType(Type) [function]
     syntax Bool ::= isPointerType(Type) [function]
     syntax Bool ::= isArrayType(Type) [function]
     syntax Bool ::= isFlexibleArrayType(Type) [function]
     syntax Bool ::= isBoolType(Type) [function]
     syntax Bool ::= isStructType(Type) [function]
     syntax Bool ::= isUnionType(Type) [function]
     syntax Bool ::= isAggregateType(Type) [function]
     syntax Bool ::= isFunctionType(Type) [function]
     syntax Bool ::= isOldStyleFunctionType(Type) [function]
     syntax Bool ::= isFunctionPointerType(Type) [function]
     syntax Bool ::= isBitfieldType(Type) [function]
     syntax Bool ::= isConstType(Type) [function]
     syntax Bool ::= isVolatileType(Type) [function]
     syntax Bool ::= isInitializerType(Type) [function]
     syntax Bool ::= isCompleteType(Type) [function]
     syntax Bool ::= isIncompleteArrayType(Type) [function]
     syntax Bool ::= isIncompleteStructType(Type) [function]
     syntax Bool ::= isIncompleteUnionType(Type) [function]
     syntax Bool ::= isVoidType(Type) [function]
     syntax Bool ::= isNoType(Type) [function]
     syntax Bool ::= isTypedDeclaration(Type) [function]

     // Storage class specifiers.
     syntax Bool ::= isExternType(Type) [function]
     syntax Bool ::= isStaticType(Type) [function]
     syntax Bool ::= isRegisterType(Type) [function]

     syntax Set ::= "typeQualifiers" [function]
     syntax Set ::= "storageSpecifiers" [function]

     syntax CSize ::= Int
     syntax CValue ::= CSize
     
     // Composite types
     syntax SimpleType ::= enumType(CId)
          [klabel('enumType)]
     syntax SimpleType ::= bitfieldType(Type, CSize)
          [klabel('bitfieldType)]
     syntax SimpleType ::= functionType(Type, List)
          [klabel('functionType)]
     syntax SimpleType ::= pointerType(Type)
          [klabel('pointerType)]

     syntax SimpleType ::= arrayType(Type, CSize) 
          [klabel('arrayType)]
     syntax SimpleType ::= incompleteArrayType(Type) 
          [klabel('incompleteArrayType)]
     syntax SimpleType ::= flexibleArrayType(Type)
          [klabel('flexibleArrayType)]

     syntax SimpleType ::= structType(CId, Int, FieldInfo)
          [klabel('structType)]
     syntax SimpleType ::= incompleteStructType(CId)
          [klabel('incompleteStructType)]

     syntax SimpleType ::= unionType(CId, Int, FieldInfo)
          [klabel('unionType)]
     syntax SimpleType ::= incompleteUnionType(CId)
          [klabel('incompleteUnionType)]

     // Writing to an lvalue with this qualifier ignores qualifiers on the
     // underlying object (const and volatile) and disables checking for
     // unsequenced reads/writes.
     syntax Storage ::= "Initializer"

     // Basic types
     syntax SimpleType ::= "char" [function]
     syntax SimpleType ::= "void" | "bool" | "short-int" | "int" 
                         | "long-int" | "long-long-int"
     syntax SimpleType ::= "float" | "double" | "long-double"
     syntax SimpleType ::= "signed-char" | "unsigned-char"
     syntax SimpleType ::= "unsigned-short-int" | "unsigned-int" 
                         | "unsigned-long-int" | "unsigned-long-long-int"
     syntax SimpleType ::= "no-type"

     // These aren't real types, but are values that can appear in type
     // contexts.
     syntax SimpleType ::= typedefType(CId, Type)
     syntax Type ::= "variadic"

     syntax Bool ::= isBasicType(K) [function]

     syntax List ::= getParams(Type) [function]
     syntax Type ::= setParams(Type, List) [function]
     syntax Type ::= getReturn(Type) [function]

     syntax Bool ::= hasSameSignedness(Type, Type) [function]
     syntax Type ::= correspondingUnsignedType(Type) [function] 
     syntax Type ::= correspondingSignedType(Type) [function] 
     syntax Bool ::= hasIntegerType(Type) [function]
     syntax Bool ::= hasUnsignedIntegerType(Type) [function]
     syntax Bool ::= hasSignedIntegerType(Type) [function]
     syntax Bool ::= hasFloatType(Type) [function]

     syntax Int ::= min(Type) [function]
     syntax Int ::= max(Type) [function]
     syntax Bool ::= inRange(CValue, Type) [function]

     syntax Modifier ::= Storage | CVSpecifier | Provenance
     // Pointers from an array need to be checked that they don't go out of
     // bounds of that array, even if that array happens to be part of a larger
     // object (i.e., surrounded by valid addresses).
     syntax Provenance ::= fromArray(Int, Int)
     // Used to tag union members so the rest of the bytes in the union can be
     // marked as undefined upon write.
     syntax Modifier ::= fromUnion(SymLoc, CId, FieldInfo) [klabel('fromUnion)]
     // Tag for old-style function defs.
     syntax Modifier ::= "oldStyle"

     // Returns both type qualifiers, storage class specifiers, and any the
     // other information stored in the modifiers list (e.g., fromUnion,
     // fromArray, oldStyle).
     syntax Set ::= getModifiers(Type) [function]

     syntax Set ::= getQualifiers(Type) [function]
     syntax Set ::= getStorageSpecifiers(Type) [function]
     syntax Set ::= getProvenance(Type) [function]

     syntax Type ::= stripStorageSpecifiers(Type) [function]
     syntax Type ::= stripQualifiers(Type) [function]

     syntax Type ::= addStorage(Storage, Type) [function]
     syntax Type ::= addQualifier(CVSpecifier, Type) [function]
     syntax Type ::= addQualifiers(Set, Type) [function]

     syntax Type ::= typedDeclaration(Type, CId) 
          [klabel('typedDeclaration), latex(\terminal{typedDecl}\!({#1},{#2}\!))] 

     syntax KItem ::= simplifyTruth(K) [function]
     syntax Type ::= innerType(Type) [function]

     syntax Type ::= completeTag(CId, FieldInfo, Type) [function]
                   | completeTags(Map, Type) [function]
     syntax KItem ::= completeTags(K) [strict]

     syntax List ::= completeTagsInList(Map, List) [function]
     syntax Map ::= completeTagsInMap(Map, Map) [function]

     syntax Bool ::= hasUnionMarker(Type) [function]
     syntax Set ::= stripUnionMarker(Set) [function]

     syntax Bool ::= isFromArray(Type) [function]

     syntax Bool ::= isNullPointerConstant(TypedValue) [function]
     syntax Bool ::= fromConstantExpr(Type) [function]

     syntax List ::= idsFromParams(List) [function]

endmodule

module C-TYPING
     imports C-TYPING-CANONICALIZATION
     imports C-TYPING-COMPATIBILITY
     imports C-TYPING-EXPR
     imports C-TYPING-INTERPRETATION
     imports C-TYPING-MISC
     imports C-TYPING-PREDICATES
     imports C-TYPING-STRICTNESS
endmodule
