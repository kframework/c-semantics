module C-TYPING-COMPATIBILITY-SYNTAX
     syntax Bool ::= "#areCompat" "(" Type "," Type ")" [function]
     syntax Bool ::= sameQualifiers(Set, Set) [function]
     syntax Int ::= getAlignas(Type) [function]

     syntax Bool ::= areCompatible(Type, Type) [function]
     syntax K ::= compositeType(Type, Type) [function]
endmodule

module C-TYPING-COMPATIBILITY
     imports C-TYPING-COMPATIBILITY-SYNTAX

     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-BINDING-SYNTAX

     imports COMPAT-SYNTAX
     imports DEBUG-SYNTAX

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

     syntax Bool ::= "#areCompat" "(" List "," List ")" [function]

     rule areCompatible(T:Type, T':Type) => #areCompat(T, T') ==K true

     rule #areCompat(T:Type, T) => true
     rule #areCompat(t(Mods:Set, T:SimpleType), t(Mods':Set, T)) => true
          when sameQualifiers(Mods, Mods')

     // TODO(chathhorn): should be a setting.
     // Each enumerated type shall be compatible with char, a signed integer
     // type, or an unsigned integer type. The choice of type is
     // implementation-defined. (6.7.2.2:4)
     rule #areCompat(
               t(Mods:Set, enumType(_)),
               t(Mods':Set, int))
          => true
          when sameQualifiers(Mods, Mods')
     rule #areCompat(
               t(Mods:Set, int),
               t(Mods':Set, enumType(_)))
          => true
          when sameQualifiers(Mods, Mods')

     rule #areCompat(
               t(Mods:Set, structType(X:CId, _, fieldInfo(Fs:List, _, _))),
               t(Mods':Set, structType(X:CId, _, fieldInfo(Fs':List, _, _))))
          => #areCompat(Fs, Fs')
          when sameQualifiers(Mods, Mods')
     rule #areCompat(
               t(Mods:Set, structType(X:CId, _, _)),
               t(Mods':Set, incompleteStructType(X:CId)))
          => true
          when sameQualifiers(Mods, Mods')
     rule #areCompat(
               t(Mods:Set, incompleteStructType(X:CId)),
               t(Mods':Set, structType(X:CId, _, _)))
          => true
          when sameQualifiers(Mods, Mods')
     rule #areCompat(
               t(Mods:Set, unionType(X:CId, _, fieldInfo(Fs:List, _, _))),
               t(Mods':Set, unionType(X:CId, _, fieldInfo(Fs':List, _, _))))
          => #areCompat(Fs, Fs')
          when sameQualifiers(Mods, Mods')
     rule #areCompat(
               t(Mods:Set, unionType(X:CId, _, _)),
               t(Mods':Set, incompleteUnionType(X:CId)))
          => true
          when sameQualifiers(Mods, Mods')
     rule #areCompat(
               t(Mods:Set, incompleteUnionType(X:CId)),
               t(Mods':Set, unionType(X:CId, _, _)))
          => true
          when sameQualifiers(Mods, Mods')
     rule #areCompat(
               t(Mods:Set, arrayType(T:Type, N:CSize)),
               t(Mods':Set, arrayType(T':Type, N:CSize)))
          => #areCompat(T, T')
          when sameQualifiers(Mods, Mods')
     rule #areCompat(
               t(Mods:Set, arrayType(T:Type, _)),
               t(Mods':Set, incompleteArrayType(T':Type)))
          => #areCompat(T, T')
          when sameQualifiers(Mods, Mods')
     rule #areCompat(
               t(Mods:Set, incompleteArrayType(T:Type)),
               t(Mods':Set, arrayType(T':Type, _)))
          => #areCompat(T, T')
          when sameQualifiers(Mods, Mods')
     rule #areCompat(
               t(Mods:Set, arrayType(T:Type, _)),
               t(Mods':Set, variableLengthArrayType(T':Type, _)))
          => #areCompat(T, T')
          when sameQualifiers(Mods, Mods')
     rule #areCompat(
               t(Mods:Set, variableLengthArrayType(T:Type, _)),
               t(Mods':Set, arrayType(T':Type, _)))
          => #areCompat(T, T')
          when sameQualifiers(Mods, Mods')
     rule #areCompat(
               t(Mods:Set, incompleteArrayType(T:Type)),
               t(Mods':Set, variableLengthArrayType(T':Type, _)))
          => #areCompat(T, T')
          when sameQualifiers(Mods, Mods')
     rule #areCompat(
               t(Mods:Set, variableLengthArrayType(T:Type, _)),
               t(Mods':Set, incompleteArrayType(T':Type)))
          => #areCompat(T, T')
          when sameQualifiers(Mods, Mods')

     rule #areCompat(
               t(Mods:Set, pointerType(T:Type)),
               t(Mods':Set, pointerType(T':Type)))
          => #areCompat(T, T')
          when sameQualifiers(Mods, Mods')

     // Struct and union fields.
     rule #areCompat(
               typedDeclaration(T:Type, X:CId),
               typedDeclaration(T':Type, X:CId))
          => #areCompat(T, T')

     // A function declaration with no arguments is compatible with a
     // declaration with any number of arguments, as long as they're all
     // promoted.

     // TODO(chathhorn): not sufficient?!? -- apparently we also need to look
     // at the argument types in a function definition w/no prototype?
     rule #areCompat(
               t(Mods:Set, functionType(T:Type, .List)),
               t(Mods':Set, functionType(T':Type, Args':List)))
          => #areCompat(T, T')
          when sameQualifiers(Mods, Mods')
               andBool areArgPromoted(Args')
               andBool notBool (variadic in Args')
     rule #areCompat(
               t(Mods:Set, functionType(T:Type, Args:List)),
               t(Mods':Set, functionType(T':Type, .List)))
          => #areCompat(T, T')
          when sameQualifiers(Mods, Mods')
               andBool areArgPromoted(Args)
               andBool notBool (variadic in Args)
     rule #areCompat(
               t(Mods:Set, functionType(T:Type,  L:List)),
               t(Mods':Set, functionType(T':Type, L':List)))
          => #areCompat(T, T') andBool #areParamsCompat(L, L')
          when (lengthList(L) ==Int lengthList(L'))
               andBool sameQualifiers(Mods, Mods')

     syntax Bool ::= "#areParamsCompat" "(" List "," List ")" [function]
     rule #areParamsCompat(
               ListItem(T:Type) L:List,
               ListItem(T':Type) L':List)
          => #areCompat(T, T') andBool #areParamsCompat(L, L')
     rule #areParamsCompat(ListItem(variadic), ListItem(variadic)) => true
     rule #areParamsCompat(.List, .List) => true

     rule #areCompat(ListItem(T:Type) L:List, ListItem(T':Type) L':List)
          => #areCompat(T, T') andBool #areCompat(L, L')
     rule #areCompat(.List, .List) => true

     rule sameQualifiers(Mods:Set, Mods':Set)
          => (intersectSet(Mods, typeQualifiers)
               ==Set intersectSet(Mods', typeQualifiers))
               // TODO(chathhorn): treating alignas like a qualifier for now.
               // It's more complicated than this, too, I think -- e.g.,
               // alignas on a definition implies no alignas should be on any
               // declaration.
               andBool (((notBool hasAlignasMod(Mods))
                    andBool (notBool hasAlignasMod(Mods')))
                    orElseBool getAlignasMod(Mods) ==Int getAlignasMod(Mods'))

     rule getAlignas(T:Type) => getAlignasMod(getModifiers(T))
          when hasAlignasMod(getModifiers(T))
     rule getAlignas(T:Type) => 1
          when notBool hasAlignasMod(getModifiers(T))

     syntax Int ::= getAlignasMod(Set) [function]
     rule getAlignasMod(SetItem(alignas(A:Int)) _) => A

     // We can assume the types are compatible.
     rule compositeType(T:Type, T:Type) => T
          when isBasicType(T)
               orBool isStructType(T)
               orBool isUnionType(T)
               orBool isBitfieldType(T)
          [structural, anywhere]
     rule compositeType(
               t(Mods:Set, T:SimpleType),
               t(Mods':Set, T:SimpleType))
          // The modifiers might include extra information besides just
          // specifiers and qualifiers, it's probably best to keep it all
          // around for now.
          => t(Mods Mods', T)
          when isBasicType(t(.Set, T))
               orBool isStructType(t(.Set, T))
               orBool isUnionType(t(.Set, T))
               orBool isBitfieldType(t(.Set, T))
          [structural, anywhere]

     // TODO(chathhorn): surely implementation defined, although I don't see
     // composite types for enums explicitly addressed in the standard.
     rule compositeType(
               t(Mods:Set, enumType(_)),
               t(Mods':Set, int))
          => t(Mods Mods', int)
          [structural, anywhere]
     rule compositeType(
               t(Mods:Set, int),
               t(Mods':Set, enumType(_)))
          => t(Mods Mods', int)
          [structural, anywhere]

     rule compositeType(
               t(Mods:Set, functionType(T:Type, P:List)),
               t(Mods':Set, functionType(T':Type, P':List)))
          => compositeFunctionType(compositeType(T, T'), Mods Mods', .K, P, P', .List)
          [structural, anywhere]

     rule compositeType(
               t(Mods:Set, pointerType(T:Type)),
               t(Mods':Set, pointerType(T':Type)))
          => t(Mods Mods', pointerType(compositeType(T, T')))
          [structural, anywhere]

     rule compositeType(
               t(Mods:Set, arrayType(T:Type, N:CSize)),
               t(Mods':Set, arrayType(T':Type, N:CSize)))
          => t(Mods Mods', arrayType(compositeType(T, T'), N))
          [structural, anywhere]
     rule compositeType(
               t(Mods:Set, arrayType(T:Type, N:CSize)),
               t(Mods':Set, incompleteArrayType(T':Type)))
          => t(Mods Mods', arrayType(compositeType(T, T'), N))
          [structural, anywhere]
     rule compositeType(
               t(Mods:Set, incompleteArrayType(T:Type)),
               t(Mods':Set, arrayType(T':Type, N:CSize)))
          => t(Mods Mods', arrayType(compositeType(T, T'), N))
          [structural, anywhere]
     rule compositeType(
               t(Mods:Set, arrayType(T:Type, N:CSize)),
               t(Mods':Set, variableLengthArrayType(T':Type, _)))
          => t(Mods Mods', arrayType(compositeType(T, T'), N))
          [structural, anywhere]
     rule compositeType(
               t(Mods:Set, variableLengthArrayType(T:Type, _)),
               t(Mods':Set, arrayType(T':Type, N:CSize)))
          => t(Mods Mods', arrayType(compositeType(T, T'), N))
          [structural, anywhere]

     rule compositeType(
               t(Mods:Set, flexibleArrayType(T:Type)),
               t(Mods':Set, flexibleArrayType(T':Type)))
          => t(Mods Mods', flexibleArrayType(compositeType(T, T')))
          [structural, anywhere]

     rule compositeType(
               typedDeclaration(T:Type, X:CId),
               typedDeclaration(T':Type, X:CId))
          => typedDeclaration(compositeType(T, T'), X)
          [structural, anywhere]

     // TODO(chathhorn): huge hack. Done like this just so things will "break"
     // when we can't form a composite type. Really need a better way to
     // propagate errors up through layers of function calls like this (or
     // maybe just a better mechanism for crawling ASTs...)
     syntax K ::= compositeFunctionType(K, Set, K, List, List, List)
     rule compositeFunctionType(T:Type, Mods:Set, .K, .List, .List, P':List)
          => t(Mods, functionType(T, P'))
          [structural, anywhere]
     rule compositeFunctionType(T:Type, Mods:Set, .K, .List, P:List, _)
          => compositeFunctionType(T, Mods, .K, .List, .List, P)
          [structural, anywhere]
     rule compositeFunctionType(T:Type, Mods:Set, .K, P:List, .List, _)
          => compositeFunctionType(T, Mods, .K, .List, .List, P)
          [structural, anywhere]
     rule compositeFunctionType(T:Type, Mods:Set, .K,
          ListItem(variadic), ListItem(variadic), P:List)
          => compositeFunctionType(T, Mods, .K, .List, .List,
               P ListItem(variadic))
          [structural, anywhere]
     rule compositeFunctionType(T:Type, Mods:Set, .K,
               ListItem(PT:Type) P:List,
               ListItem(PT':Type) P':List, P'':List)
          => compositeFunctionType(T, Mods, compositeType(PT, PT'), P, P', P'')
          [structural, anywhere]
     rule compositeFunctionType(T:Type, Mods:Set, T':Type, P:List, P':List, P'':List)
          => compositeFunctionType(T, Mods, .K, P, P', P'' ListItem(T'))
          [structural, anywhere]

endmodule

