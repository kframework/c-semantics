module C-TYPING-PREDICATES
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports COMPAT-SYNTAX

     rule isBasicType(T:Type) => #isBasicType'(T) ==K true

     syntax Bool ::= "#isBasicType'" "(" Type ")" [function]

     rule #isBasicType'(t(_, T:SimpleType)) => true
          when (T ==K bool)
               orBool (T ==K void)
               orBool (T ==K char)
               orBool (T ==K short-int)
               orBool (T ==K int)
               orBool (T ==K long-int)
               orBool (T ==K long-long-int)
               orBool (T ==K float)
               orBool (T ==K double)
               orBool (T ==K long-double)
               orBool (T ==K signed-char)
               orBool (T ==K unsigned-char)
               orBool (T ==K unsigned-short-int)
               orBool (T ==K unsigned-int)
               orBool (T ==K unsigned-long-int)
               orBool (T ==K unsigned-long-long-int)
               orBool (T ==K no-type)
               orBool (getKLabel(T) ==KLabel 'enumType)

     rule unsignedIntegerTypes => 
          SetItem(bool)
          SetItem(unsigned-char)
          SetItem(unsigned-short-int)
          SetItem(unsigned-int)
          SetItem(unsigned-long-int)
          SetItem(unsigned-long-long-int)

     rule signedIntegerTypes => 
          SetItem(char)
          SetItem(signed-char)
          SetItem(short-int)
          SetItem(int)
          SetItem(long-int)
          SetItem(long-long-int)

     rule hasSameSignedness(T:Type, T':Type)
          => (hasSignedIntegerType(T) andBool hasSignedIntegerType(T'))
               orBool 
               (hasUnsignedIntegerType(T) andBool hasUnsignedIntegerType(T'))

     rule hasIntegerType(T:Type) 
          => ((hasUnsignedIntegerType(T) ==K true) 
               orBool (hasSignedIntegerType(T) ==K true))

     rule hasUnsignedIntegerType(T:Type)
          => #hasUnsignedIntegerType'(T) ==K true
     rule hasSignedIntegerType(T:Type)
          => #hasSignedIntegerType'(T) ==K true

     syntax Bool ::= "#hasUnsignedIntegerType'" "(" Type ")" [function]
                   | "#hasSignedIntegerType'" "(" Type ")" [function]
     
     rule #hasUnsignedIntegerType'(t(_, T:SimpleType)) => true
          when (T in unsignedIntegerTypes)
     rule #hasUnsignedIntegerType'(t(_, bitfieldType(T:Type, _))) => true
          when hasUnsignedIntegerType(T)

     rule #hasSignedIntegerType'(t(_, T:SimpleType)) => true
          when (T in signedIntegerTypes)
     rule #hasSignedIntegerType'(t(_, enumType(_))) => true
     rule #hasSignedIntegerType'(t(_, bitfieldType(T:Type, _))) => true
          when #hasSignedIntegerType'(T)

     /*@ \fromStandard{\source[n1570]{\para{6.2.7}{1}}}{
     Two types have compatible type if their types are the same. Additional
     rules for determining whether two types are compatible are described in
     6.7.2 for type specifiers, in 6.7.3 for type qualifiers, and in 6.7.6 for
     declarators.  Moreover, two structure, union, or enumerated types declared
     in separate translation units are compatible if their tags and members
     satisfy the following requirements: If one is declared with a tag, the
     other shall be declared with the same tag. If both are completed anywhere
     within their respective translation units, then the following additional
     requirements apply: there shall be a one-to-one correspondence between
     their members such that each pair of corresponding members are declared
     with compatible types; if one member of the pair is declared with an
     alignment specifier, the other is declared with an equivalent alignment
     specifier; and if one member of the pair is declared with a name, the
     other is declared with the same name. For two structures, corresponding
     members shall be declared in the same order. For two structures or unions,
     corresponding bit-fields shall have the same widths. For two enumerations,
     corresponding members shall have the same values.
     
     \source[n1570]{\para{6.7.3}{10}}
     For two qualified types to be compatible, both shall have the identically
     qualified version of a compatible type; the order of type qualifiers
     within a list of specifiers or qualifiers does not affect the specified
     type.
     }*/

     syntax Bool ::= "#isCompat" "(" Type "," Type ")" [function]
     syntax Bool ::= "#areCompat" "(" List "," List ")" [function]

     // TODO(chathhorn): I think there are various notions of type
     // compatibility being conflated here.
     // TODO(chathhorn): const?
     rule isTypeCompatible(T1:Type, T2:Type) 
          => #isCompat(stripModifiers(T1), stripModifiers(T2)) ==K true

     // TODO(chathhorn): struct/union fields and unnameds.
     // rule #isCompat(t(_, structType(X:Id, _, _)), t(_, structType(X:Id, _, _)))
     //      => true
     // rule #isCompat(t(_, structType(X:Id, _, _)), t(_, incompleteStructType(X:Id)))
     //      => true
     // rule #isCompat(t(_, incompleteStructType(X:Id)), t(_, structType(X:Id, _, _)))
     //      => true
     // rule #isCompat(t(_, unionType(X:Id, _, _)), t(_, unionType(X:Id, _, _)))
     //      => true
     // rule #isCompat(t(_, unionType(X:Id, _, _)), t(_, incompleteUnionType(X:Id)))
     //      => true
     // rule #isCompat(t(_, incompleteUnionType(X:Id)), t(_, unionType(X:Id, _, _)))
     //      => true
     rule #isCompat(t(_, structType(_, _, _)), t(_, structType(_, _, _)))
          => true
     rule #isCompat(t(_, structType(_, _, _)), t(_, incompleteStructType(_)))
          => true
     rule #isCompat(t(_, incompleteStructType(_)), t(_, structType(_, _, _)))
          => true
     rule #isCompat(t(_, unionType(_, _, _)), t(_, unionType(_, _, _)))
          => true
     rule #isCompat(t(_, unionType(_, _, _)), t(_, incompleteUnionType(_)))
          => true
     rule #isCompat(t(_, incompleteUnionType(_)), t(_, unionType(_, _, _)))
          => true

     // TODO(chathhorn): are enums compatible with e.g. ints?
     rule #isCompat(t(_, enumType(_)), t(_, enumType(_))) => true

     rule [typeCompatible-identical]:
          #isCompat(T:Type, T:Type) => true 
     rule [typeCompatible-two-ints]:
          #isCompat(T:Type, T':Type) => true 
          when hasIntegerType(T)
               andBool hasIntegerType(T') 
     rule [typeCompatible-two-ptr]:
          #isCompat(t(_, pointerType(_)), t(_, pointerType(_))) => true 
     rule [typeCompatible-ptr-int]:
          #isCompat(t(_, pointerType(_)), T:Type) => true
          when hasIntegerType(T) 
     rule [typeCompatible-int-ptr]:
          #isCompat(T:Type, t(_, pointerType(_))) => true
          when hasIntegerType(T)
          
     rule [typeCompatible-declarations]:
          #isCompat(typedDeclaration(T:Type, _), typedDeclaration(T':Type, _))
          => #isCompat(T, T') 

     rule [typeCompatible-array-right]:
          #isCompat(T:Type, t(S:Set, arrayType(T':Type, _)))
          => #isCompat(T, t(S:Set, pointerType(T'))) 
     rule [typeCompatible-array-left]:
          #isCompat(t(S:Set, arrayType(T:Type, _)), T':Type)
          => #isCompat(t(S, pointerType(T)), T') 
     
     rule [typeCompatible-incompleteArray-right]:
          #isCompat(T:Type, t(S:Set, incompleteArrayType(T':Type)))
          => #isCompat(T, t(S, pointerType(T'))) 
     rule [typeCompatible-incompleteArray-left]:
          #isCompat(t(S:Set, incompleteArrayType(T:Type)), T':Type)
          => #isCompat(t(S, pointerType(T)), T') 

     // A function declaration with no arguments is compatible with a
     // declaration with any number of arguments.
     // TODO(chathhorn): still needs work. Also, specifiers.
     rule [typeCompatible-function-empty-args]:
          #isCompat(
               t(_, functionType(T:Type, Args:List)),
               t(_, functionType(T':Type, Args':List)))
          => #isCompat(T, T') 
          when (Args ==List .List) orBool (Args' ==List .List)
     rule [typeCompatible-function]:
          #isCompat(
               t(_, functionType(T:Type,  L:List)),
               t(_, functionType(T':Type, L':List)))
          => #isCompat(T, T') andBool #areCompat(L, L')
          when lengthList(L) ==Int lengthList(L')

     rule #areCompat(ListItem(T:Type) L:List, ListItem(T':Type) L':List)
          => #isCompat(T, T') andBool #areCompat(L, L')
     rule #areCompat(.List, .List) => true
          
     rule isFloatType(t(_, float)) => true 
     rule isFloatType(t(_, double)) => true 
     rule isFloatType(t(_, long-double)) => true 
     rule isFloatType(t(_, T:SimpleType)) => false
          when (T =/=K float)
               andBool (T =/=K double)
               andBool (T =/=K long-double)
          
     rule [isCharType-char]: isCharType(t(_, char)) => true 
     rule [isCharType-unsigned-char]: isCharType(t(_, unsigned-char)) => true 
     rule [isCharType-signed-char]: isCharType(t(_, signed-char)) => true 
     rule [isCharType-other]: isCharType(t(_, T:SimpleType)) => false
          when (T =/=K char)
               andBool (T =/=K unsigned-char)
               andBool (T =/=K signed-char)
          
     syntax SimpleType ::= simpleType(Type) [function]
     rule simpleType(t(_, T:SimpleType)) => T

     rule isWCharType(t(_, T:SimpleType)) 
          => T ==K simpleType(cfg:wcharut)
          
     rule isPointerType(t(_, pointerType(_))) => true 
     rule isPointerType(t(_, T:SimpleType)) => false
          when (getKLabel(T) =/=KLabel 'pointerType)
     
     rule [isBoolType-bool]: isBoolType(t(_, bool)) => true 
     rule [isBoolType-other]: isBoolType(t(_, T:SimpleType)) => false
          when (T =/=K bool)
          
     rule isArrayType(t(_, arrayType(_, _))) => true 
     rule isArrayType(t(_, incompleteArrayType(_))) => true 
     rule isArrayType(t(_, flexibleArrayType(_))) => true 
     rule isArrayType(t(_, T:SimpleType)) => false
          when (getKLabel(T) =/=KLabel 'arrayType)
               andBool (getKLabel(T) =/=KLabel 'incompleteArrayType)
               andBool (getKLabel(T) =/=KLabel 'flexibleArrayType)

     rule isVoidType(T:Type) => #isVoidType'(T) ==K true
          
     syntax Bool ::= "#isVoidType'" "(" Type ")" [function]
     rule #isVoidType'(t(_, void)) => true
     rule #isVoidType'(typedDeclaration(T:Type, _)) => #isVoidType'(T)

     rule isAggregateType(T:Type)
          => isArrayType(T) orBool isStructType(T) 
          
     rule isStructType(t(_, structType(_, _, _))) => true 
     rule isStructType(t(_, incompleteStructType(_))) => true 
     rule isStructType(t(_, T:SimpleType)) => false
          when (getKLabel(T) =/=KLabel 'structType)
               andBool (getKLabel(T) =/=KLabel 'incompleteStructType)

     rule isUnionType(t(_, unionType(_, _, _))) => true 
     rule isUnionType(t(_, incompleteUnionType(_))) => true 
     rule isUnionType(t(_, T:SimpleType)) => false
          when (getKLabel(T) =/=KLabel 'unionType)
               andBool (getKLabel(T) =/=KLabel 'incompleteUnionType)

     rule isCompleteType(T:Type)
          => notBool (isIncompleteArrayType(T)
               orBool isIncompleteStructType(T)
               orBool isIncompleteUnionType(T)
               orBool isVoidType(T))

     syntax Bool ::= "#isIncompleteArrayType'" "(" Type ")"  [function]
                   | "#isIncompleteStructType'" "(" Type ")" [function]
                   | "#isIncompleteUnionType'" "(" Type ")"  [function]

     rule isIncompleteArrayType(T:Type)
          => #isIncompleteArrayType'(T) ==K true
     rule isIncompleteStructType(T:Type)
          => #isIncompleteStructType'(T) ==K true
     rule isIncompleteUnionType(T:Type)
          => #isIncompleteUnionType'(T) ==K true

     rule #isIncompleteArrayType'(t(_, incompleteArrayType(_)))
          => true 
     rule #isIncompleteArrayType'(typedDeclaration(T:Type, _))
          => #isIncompleteArrayType'(T) 

     rule #isIncompleteStructType'(t(_, incompleteStructType(_)))
          => true 
     rule #isIncompleteStructType'(typedDeclaration(T:Type, _))
          => #isIncompleteStructType'(T) 

     rule #isIncompleteUnionType'(t(_, incompleteUnionType(_)))
          => true 
     rule #isIncompleteUnionType'(typedDeclaration(T:Type, _))
          => #isIncompleteUnionType'(T) 
          
     rule isExternType(t(Quals:Set, _)) => Extern in Quals
          
     rule isStaticType(t(Quals:Set, _)) => Static in Quals
          
     rule isConstType(t(Quals:Set, _)) => Const in Quals
          
     rule isBitfieldType(t(_, bitfieldType(_, _))) => true 
     rule isBitfieldType(t(_, T:SimpleType)) => false
          when getKLabel(T) =/=KLabel 'bitfieldType
          
     rule isFunctionType(t(_, functionType(_, _))) => true 
     rule isFunctionType(t(_, T:SimpleType)) => false
          when (getKLabel(T) =/=KLabel 'functionType)

     rule isFunctionPointerType(T:Type) => #isFunctionPointerType'(T) ==K true

     syntax Bool ::= "#isFunctionPointerType'" "(" Type ")" [function]
     rule #isFunctionPointerType'(t(_, pointerType(t(_, functionType(_, _)))))
          => true 

     // /*@ \source[n1570]{\para{6.2.5}{18}}
     // Integer and floating types are collectively called arithmetic types.
     // Each arithmetic type belongs to one type domain: the real type domain
     // comprises the real types, the complex type domain comprises the complex
     // types. 
     // */
     rule isArithmeticType(T:Type)
          => hasIntegerType(T) orBool isFloatType(T)
               
endmodule
