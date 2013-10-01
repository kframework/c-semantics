require "typing/canonicalization.k"
require "typing/declaration.k"
require "typing/interpretation.k"
require "typing/misc.k"
require "typing/strictness.k"
require "typing/expression.k"

module C-TYPING-SYNTAX
     syntax K ::= "typeof" "(" K ")"
     syntax Id ::= "typedef" "(" Id ")"
     syntax Id ::= "unnamed" "(" Int ")"

     syntax K ::= "allowWrite" "(" K ")" [strict]

     // represents a type before canonicalization.  as in "int *x", first arg
     // is "Int", second arg is "PointerType(JustBase)"
     syntax K ::= "DeclType" "(" K "," K ")" [avoid, strict(1)] 
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
     syntax Bool ::= isIncompleteType(Type) [function]
     syntax Bool ::= isArithmeticType(Type) [function]
     syntax Bool ::= isFloatType(Type) [function]
     
     // Composite types
     syntax SimpleType ::= "enumType" "(" Id ")" 
          [klabel('enumType)]
     syntax SimpleType ::= "arrayType" "(" Type "," Int ")" 
          [klabel('arrayType)]
     syntax SimpleType ::= "incompleteArrayType" "(" Type ")" 
          [klabel('incompleteArrayType)]
     syntax SimpleType ::= "flexibleArrayType" "(" Type ")" 
          [klabel('flexibleArrayType)]
     syntax SimpleType ::= "bitfieldType" "(" Type "," Int ")" 
          [klabel('bitfieldType)]
     syntax SimpleType ::= "functionType" "(" Type "," KList ")" 
          [klabel('functionType)]
     syntax SimpleType ::= "pointerType" "(" Type ")" 
          [klabel('pointerType)]
     syntax SimpleType ::= "structType" "(" Id ")" 
          [klabel('structType)]
     syntax SimpleType ::= "unionType" "(" Id ")" 
          [klabel('unionType)]
     syntax SimpleType ::= "qualifiedType" "(" Type "," K ")" 
          [klabel('qualifiedType)]

     // Basic types
     syntax SimpleType ::= "void" | "bool" | "char" | "short-int" | "int" 
                         | "long-int" | "long-long-int"
     syntax SimpleType ::= "float" | "double" | "long-double"
     syntax SimpleType ::= "signed-char" | "unsigned-char"
     syntax SimpleType ::= "unsigned-short-int" | "unsigned-int" 
                         | "unsigned-long-int" | "unsigned-long-long-int"
     syntax SimpleType ::= "no-type"

     // these aren't real types, but are values that can appear in type contexts
     syntax SimpleType ::= "prototype" "(" Type ")" [klabel('prototype)]
     syntax SimpleType ::= "typedefType" "(" Id "," Type ")"
     syntax SimpleType ::= "variadic"

     syntax Bool ::= "isBasicType" "(" K ")" [function]

     // takes a type, but sometimes things like maps give K
     syntax KResult ::= unqualifyType(K) [function]
     syntax Type ::= removeStorageSpecifiers(K) [function]
     
     syntax Bool ::= hasSameSignedness(Type, Type) [function]
     syntax Type ::= correspondingUnsignedType(Type) [function] 
     syntax Set ::= "unsignedIntegerTypes" [function]
     syntax Set ::= "signedIntegerTypes" [function]
     syntax Bool ::= hasIntegerType(Type) [function]
     syntax Bool ::= hasUnsignedIntegerType(Type) [function]
     syntax Bool ::= hasSignedIntegerType(Type) [function]

     syntax Int ::= min(Type) [function]
     syntax Int ::= max(Type) [function]

     syntax Set ::= "getModifiers" "(" K ")" [function]

     syntax Type ::= "typedDeclaration" "(" Type "," Id ")" 
          [klabel('typedDeclaration), latex(\terminal{typedDecl}\!({#1},{#2}\!))] 

     syntax K ::= "giveType" "(" Id "," Type ")"

     syntax Int ::= numBits(Type) [function]

     syntax Bool ::= isTruthValue(TypedValue) [function]
     syntax K ::= simplifyTruth(K) [function]
endmodule

module C-TYPING
     imports C-TYPING-CANONICALIZATION
     imports C-TYPING-DECLARATION
     imports C-TYPING-INTERPRETATION
     imports C-TYPING-MISC
     imports C-TYPING-STRICTNESS
     imports C-TYPING-EXPRESSION
endmodule
