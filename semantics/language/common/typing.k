require "typing/canonicalization.k"
require "typing/compatibility.k"
require "typing/expr.k"
require "typing/interpretation.k"
require "typing/misc.k"
require "typing/predicates.k"
require "typing/strictness.k"

module C-TYPING-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX

     syntax KItem ::= typeof(K)
     syntax CId ::= typedef(CId)
     syntax CId ::= unnamed(Int, String)
     syntax CId ::= vararg(Int)

     syntax Bool ::= Type "==Type" Type [function]
     syntax Bool ::= Type "=/=Type" Type [function]

     syntax SimpleType ::= simpleType(Type) [function]

     // TODO(chathhorn): move?
     // Offsets and field names for structs and unions.
     syntax FieldInfo ::= fieldInfo(List, Map, Map)

     // Represents a type before canonicalization.  as in "int *x", first arg
     // is "Int", second arg is "PointerType(JustBase)"
     syntax KItem ::= DeclType(K, K) [avoid, strict(1)]

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

     // Type qualifiers.
     syntax Bool ::= isRestrictType(Type) [function]

     syntax Set ::= "typeQualifiers" [function]
     syntax Set ::= "storageSpecifiers" [function]

     syntax CSize ::= Int
     syntax CValue ::= CSize

     // Composite types
     syntax SimpleType ::= enumType(CId)
     syntax SimpleType ::= bitfieldType(Type, CSize)
     syntax SimpleType ::= functionType(Type, List)
     syntax SimpleType ::= pointerType(Type)

     syntax SimpleType ::= arrayType(Type, CSize)
     syntax SimpleType ::= incompleteArrayType(Type)
     syntax SimpleType ::= flexibleArrayType(Type)
     syntax SimpleType ::= variableLengthArrayType(Type, K)

     syntax SimpleType ::= structType(CId, Int, FieldInfo)
     syntax SimpleType ::= incompleteStructType(CId)

     syntax SimpleType ::= unionType(CId, Int, FieldInfo)
     syntax SimpleType ::= incompleteUnionType(CId)

     // Basic types
     // TODO(chathhorn): probably should create subsorts for
     // Unsigned/SignedIntTYpe, etc.
     syntax SimpleType ::= BaseType
     syntax BaseType ::= "char" [function]
     syntax BaseType ::= "void" | "bool" | "short-int" | "int"
                        | "long-int" | "long-long-int"
     syntax BaseType ::= "float" | "double" | "long-double"
     syntax BaseType ::= "signed-char" | "unsigned-char"
     syntax BaseType ::= "unsigned-short-int" | "unsigned-int"
                        | "unsigned-long-int" | "unsigned-long-long-int"
     syntax BaseType ::= "no-type"

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

     syntax Modifier ::= Storage | CVSpecifier

     // Returns both type qualifiers, storage class specifiers, and any the
     // other information stored in the modifiers list (e.g., oldStyle).
     syntax Set ::= getModifiers(Type) [function]
     // Tag for old-style function defs.
     syntax Modifier ::= "oldStyle"
     // For function array parameters with a static-qualified size.
     syntax Modifier ::= arrayStatic(CSize) [klabel('arrayStatic)]
     syntax Modifier ::= atomic(Type) [klabel('atomic)]
     syntax Modifier ::= alignas(Int) [klabel('alignas)]

     // Special restrict modifier tagged with a block num.
     syntax Modifier ::= RestrictBlock(RestrictTag)
     syntax RestrictTag ::= Int | CId | "global"

     syntax Set ::= getStorageSpecifiers(Type) [function]
     syntax Set ::= getFunctionSpecifiers(Type) [function]
     // Gets function and storage specifiers.
     syntax Set ::= getSpecifiers(Type) [function]
     syntax Set ::= getQualifiers(Type) [function]

     syntax Type ::= stripStorageSpecifiers(Type) [function]
     syntax Type ::= stripFunctionSpecifiers(Type) [function]
     // Strips function and storage specifiers.
     syntax Type ::= stripSpecifiers(Type) [function]
     syntax Type ::= stripQualifiers(Type) [function]

     syntax Type ::= addQualifier(CVSpecifier, Type) [function]
     syntax Type ::= addQualifiers(Set, Type) [function]
     syntax Type ::= addStorage(Storage, Type) [function]
     syntax Type ::= addModifiers(Set, Type) [function]

     syntax Type ::= typedDeclaration(Type, CId)
          [latex(\terminal{typedDecl}\!({#1},{#2}\!))]

     syntax KItem ::= simplifyTruth(K) [function]
     syntax Type ::= innerType(Type) [function]

     syntax Type ::= completeTag(CId, FieldInfo, Type) [function]
                   | completeTags(Map, Type) [function]
     syntax KItem ::= #completeTags(K) [strict]

     syntax List ::= completeTagsInList(Map, List) [function]
     syntax Map ::= completeTagsInMap(Map, Map) [function]

     syntax Bool ::= isNullPointerConstant(TypedValue) [function]
     syntax Bool ::= fromConstantExpr(Type) [function]

     syntax List ::= idsFromParams(List) [function]

     syntax Type ::= tagRestrict(RestrictTag, Type) [function]
     syntax RestrictTag ::= getRestrictBlock(Type) [function]

     syntax Int ::= arrayLength(Type) [function]

     //need this to solve array type anywhere rule
     syntax Type ::= canonicalizeArrayType(Type) [function]
     syntax List ::= canonicalizeArrayTypeInList(List) [function]
     syntax Map ::= canonicalizeArrayTypeInMap(Map) [function]

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
