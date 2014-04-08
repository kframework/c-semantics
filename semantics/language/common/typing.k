require "typing/canonicalization.k"
require "typing/expr.k"
require "typing/interpretation.k"
require "typing/misc.k"
require "typing/predicates.k"
require "typing/strictness.k"

module C-TYPING-SYNTAX
     syntax K ::= typeof(K)
     syntax Id ::= typedef(Id)
     syntax Id ::= unnamed(Int, String)

     syntax K ::= allowWrite(K) [strict]
     syntax Type ::= stripConst(Type) [function]
     
     // TODO(chathhorn): move?
     // Offsets and field names for structs and unions.
     syntax FieldInfo ::= fieldInfo(List, Map, Map)

     // represents a type before canonicalization.  as in "int *x", first arg
     // is "Int", second arg is "PointerType(JustBase)"
     syntax K ::= DeclType(K, K) [avoid, strict(1)] 
     syntax Set ::= "setOfTypes" [function]

     syntax Bool ::= isTypeCompatible(Type, Type) [function]
     
     syntax Bool ::= isCharType(Type) [function]
     syntax Bool ::= isWCharType(Type) [function]
     syntax Bool ::= isPointerType(Type) [function]
     syntax Bool ::= isArrayType(Type) [function]
     syntax Bool ::= isBoolType(Type) [function]
     syntax Bool ::= isStructType(Type) [function]
     syntax Bool ::= isUnionType(Type) [function]
     syntax Bool ::= isAggregateType(Type) [function]
     syntax Bool ::= isFunctionType(Type) [function]
     syntax Bool ::= isFunctionPointerType(Type) [function]
     syntax Bool ::= isBitfieldType(Type) [function]
     syntax Bool ::= isExternType(Type) [function]
     syntax Bool ::= isStaticType(Type) [function]
     syntax Bool ::= isConstType(Type) [function]
     syntax Bool ::= isCompleteType(Type) [function]
     syntax Bool ::= isIncompleteArrayType(Type) [function]
     syntax Bool ::= isIncompleteStructType(Type) [function]
     syntax Bool ::= isIncompleteUnionType(Type) [function]
     syntax Bool ::= isArithmeticType(Type) [function]
     syntax Bool ::= isFloatType(Type) [function]
     syntax Bool ::= isVoidType(Type) [function]

     syntax CSize ::= Int
     syntax CValue ::= CSize
     
     // Composite types
     syntax SimpleType ::= enumType(Id)
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

     syntax SimpleType ::= structType(Id, Int, FieldInfo)
          [klabel('structType)]
     syntax SimpleType ::= incompleteStructType(Id)
          [klabel('incompleteStructType)]

     syntax SimpleType ::= unionType(Id, Int, FieldInfo)
          [klabel('unionType)]
     syntax SimpleType ::= incompleteUnionType(Id)
          [klabel('incompleteUnionType)]

     syntax TypeQuality ::= Storage | CVSpecifier
     syntax SimpleType ::= qualifiedType(Type, TypeQuality)
          [klabel('qualifiedType)]

     // Basic types
     syntax SimpleType ::= "void" | "bool" | "char" | "short-int" | "int" 
                         | "long-int" | "long-long-int"
     syntax SimpleType ::= "float" | "double" | "long-double"
     syntax SimpleType ::= "signed-char" | "unsigned-char"
     syntax SimpleType ::= "unsigned-short-int" | "unsigned-int" 
                         | "unsigned-long-int" | "unsigned-long-long-int"
     syntax SimpleType ::= "no-type"

     // These aren't real types, but are values that can appear in type
     // contexts.
     syntax SimpleType ::= typedefType(Id, Type)
     syntax SimpleType ::= "variadic"

     syntax Bool ::= isBasicType(K) [function]

     syntax Set ::= getQualities(Type) [function]
     syntax Set ::= getQualifiers(Type) [function]
     // takes a type, but sometimes things like maps give K
     syntax KResult ::= unqualifyType(K) [function]
     
     syntax Bool ::= hasSameSignedness(Type, Type) [function]
     syntax Type ::= correspondingUnsignedType(Type) [function] 
     syntax Set ::= "unsignedIntegerTypes" [function]
     syntax Set ::= "signedIntegerTypes" [function]
     syntax Bool ::= hasIntegerType(Type) [function]
     syntax Bool ::= hasUnsignedIntegerType(Type) [function]
     syntax Bool ::= hasSignedIntegerType(Type) [function]

     syntax Int ::= min(Type) [function]
     syntax Int ::= max(Type) [function]

     syntax Set ::= getModifiers(K) [function]

     syntax Type ::= typedDeclaration(Type, Id) 
          [klabel('typedDeclaration), latex(\terminal{typedDecl}\!({#1},{#2}\!))] 

     syntax Int ::= numBits(Type) [function]

     syntax K ::= simplifyTruth(K) [function]
     syntax Type ::= innerType(Type) [function]

     syntax Type ::= completeTag(Id, FieldInfo, Type) [function]
                   | completeTags(Map, Type) [function]
     syntax K ::= completeTags(Type)

     syntax List ::= completeTagsInList(Map, List) [function]
     syntax Map ::= completeTagsInMap(Map, Map) [function]

     // Used to tag union members so the rest of the bytes in the union can be
     // marked as undefined upon write.
     syntax K ::= fromUnion(SymLoc, Id, FieldInfo)

endmodule

module C-TYPING
     imports C-TYPING-CANONICALIZATION
     imports C-TYPING-EXPR
     imports C-TYPING-INTERPRETATION
     imports C-TYPING-MISC
     imports C-TYPING-PREDICATES
     imports C-TYPING-STRICTNESS
endmodule
