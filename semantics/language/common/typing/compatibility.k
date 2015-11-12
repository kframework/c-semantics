module C-TYPING-COMPATIBILITY-SYNTAX
     imports SET
     syntax Bool ::= #areCompat(Type, Type, Set) [function]
     syntax Bool ::= sameQualifiers(Set, Set) [function]
     syntax Int ::= getAlignas(Type) [function]

     syntax Bool ::= areCompatible(Type, Type) [function]
     syntax Type ::= compositeType(Type, Type) [function]
endmodule

module C-TYPING-COMPATIBILITY
     imports C-TYPING-COMPATIBILITY-SYNTAX

     imports C-SYNTAX
     imports C-ALIGNMENT-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-BINDING-SYNTAX

     imports COMPAT-SYNTAX

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

     syntax Bool ::= #areCompat(List, List, Set) [function,klabel(#areCompatList)]

     rule areCompatible(T::Type, T'::Type) => #areCompat(T, T', .Set)

     rule #areCompat(T::Type, T, _) => true
     rule #areCompat(t(Mods:Set, T:SimpleType), t(Mods':Set, T), _) => true
          requires sameQualifiers(Mods, Mods')

     // TODO(chathhorn): should be a setting.
     // Each enumerated type shall be compatible with char, a signed integer
     // type, or an unsigned integer type. The choice of type is
     // implementation-defined. (6.7.2.2:4)
     rule #areCompat(
               t(Mods:Set, enumType(_)),
               t(Mods':Set, T:SimpleType), _)
          => true
          requires T ==K cfg:enumAlias andBool sameQualifiers(Mods, Mods')
     rule #areCompat(
               t(Mods:Set, T:SimpleType),
               t(Mods':Set, enumType(_)), _)
          => true
          requires T ==K cfg:enumAlias andBool sameQualifiers(Mods, Mods')

     // TODO(chathhorn): should also check for equivalent members
     rule #areCompat(
               t(Mods:Set, enumType(X:CId)),
               t(Mods':Set, enumType(X':CId)), _)
          => true
          requires sameQualifiers(Mods, Mods')
          andBool #areTagsCompat(X, X')

     rule #areCompat(T::Type, T'::Type, Cache::Set) => true
          requires kpair(T, T') in Cache

     rule #areCompat(
               t(Mods:Set, structType(S:StructId)),
               t(Mods':Set, structType(S':StructId)), Cache:Set)
          => #areFieldsCompat(getFieldInfo(S), getFieldInfo(S'), Cache SetItem(kpair(t(Mods, structType(S)), t(Mods', structType(S')))))
          requires sameQualifiers(Mods, Mods')
               andBool #areTagsCompat(getTag(S), getTag(S'))
               andBool getFieldInfo(S) =/=K #incomplete
               andBool getFieldInfo(S') =/=K #incomplete
               andBool notBool kpair(t(Mods, structType(S)), t(Mods', structType(S'))) in Cache
     rule #areCompat(
               t(Mods:Set, structType(S:StructId)),
               t(Mods':Set, structType(S':StructId)), _)
          => true
          requires sameQualifiers(Mods, Mods')
               andBool #areTagsCompat(getTag(S), getTag(S'))
               andBool (getFieldInfo(S) ==K #incomplete
                    orBool getFieldInfo(S') ==K #incomplete)
     rule #areCompat(
               t(Mods:Set, unionType(S:StructId)),
               t(Mods':Set, unionType(S':StructId)), Cache:Set)
          => #areFieldsCompat(getFieldInfo(S), getFieldInfo(S'), Cache SetItem(kpair(t(Mods, structType(S)), t(Mods', structType(S')))))
          requires sameQualifiers(Mods, Mods')
               andBool #areTagsCompat(getTag(S), getTag(S'))
               andBool getFieldInfo(S) =/=K #incomplete
               andBool getFieldInfo(S') =/=K #incomplete
               andBool notBool kpair(t(Mods, structType(S)), t(Mods', structType(S'))) in Cache
     syntax Bool ::= #areFieldsCompat(K, K, Set) [function]
     rule #areFieldsCompat(fieldInfo(Fs:List, _, _, _), fieldInfo(Fs':List, _, _, _), Cache:Set)
          => #areCompat(Fs, Fs', Cache) andBool #areBitFieldsCompat(Fs, Fs')
     syntax Bool ::= #areTagsCompat(K, K) [function]
     rule #areTagsCompat(C:CId, C:CId) => true
     rule #areTagsCompat(unnamed(_, _), unnamed(_, _)) => true
     rule #areTagsCompat(_, _) => false [owise]
     syntax Bool ::= #areBitFieldsCompat(List, List) [function]
     rule #areBitFieldsCompat(ListItem(typedDeclaration(t(_, bitfieldType(_, Size:Int)), _)) Fs:List, ListItem(typedDeclaration(t(_, bitfieldType(_, Size:Int)), _)) Fs':List) => #areBitFieldsCompat(Fs, Fs')
     rule #areBitFieldsCompat(ListItem(typedDeclaration(T:Type, _)) Fs:List, ListItem(typedDeclaration(T':Type, _)) Fs':List) => #areBitFieldsCompat(Fs, Fs')
     requires notBool isBitfieldType(T) andBool notBool isBitfieldType(T')
     rule #areBitFieldsCompat(.List, .List) => true
     rule #areBitFieldsCompat(_, _) => false [owise]

     // bit fields aren't really types, so they aren't part of type compatibility. According to the standard, they are part of the compatibility of the type of the struct, hence #areBitFieldsCompat above.
     rule #areCompat(t(Mods:Set, bitfieldType(T:Type, _)), T':Type, Cache:Set) => #areCompat(addModifiers(Mods, T), T', Cache)
     rule #areCompat(T':Type, t(Mods:Set, bitfieldType(T:Type, _)), Cache:Set) => #areCompat(addModifiers(Mods, T), T', Cache)

     rule #areCompat(
               t(Mods:Set, unionType(S:StructId)),
               t(Mods':Set, unionType(S':StructId)), _)
          => true
          requires sameQualifiers(Mods, Mods')
               andBool #areTagsCompat(getTag(S), getTag(S'))
               andBool (getFieldInfo(S) ==K #incomplete
                    orBool getFieldInfo(S') ==K #incomplete)
     rule #areCompat(
               t(Mods:Set, arrayType(T::Type, N:Int)),
               t(Mods':Set, arrayType(T'::Type, N)), Cache:Set)
          => #areCompat(T, T', Cache)
          requires sameQualifiers(Mods, Mods')
     rule #areCompat(
               t(Mods:Set, arrayType(T::Type, _)),
               t(Mods':Set, incompleteArrayType(T'::Type)), Cache:Set)
          => #areCompat(T, T',  Cache)
          requires sameQualifiers(Mods, Mods')
     rule #areCompat(
               t(Mods:Set, incompleteArrayType(T::Type)),
               t(Mods':Set, arrayType(T'::Type, _)), Cache:Set)
          => #areCompat(T, T', Cache)
          requires sameQualifiers(Mods, Mods')
     // TODO(chathhorn): need to rework VLA compatibility.
     rule #areCompat(
               t(Mods:Set, arrayType(T::Type, _)),
               t(Mods':Set, variableLengthArrayType(T'::Type, _)), Cache:Set)
          => #areCompat(T, T', Cache)
          requires sameQualifiers(Mods, Mods')
     rule #areCompat(
               t(Mods:Set, variableLengthArrayType(T::Type, _)),
               t(Mods':Set, arrayType(T'::Type, _)), Cache:Set)
          => #areCompat(T, T', Cache)
          requires sameQualifiers(Mods, Mods')
     rule #areCompat(
               t(Mods:Set, incompleteArrayType(T::Type)),
               t(Mods':Set, variableLengthArrayType(T'::Type, _)), Cache:Set)
          => #areCompat(T, T', Cache)
          requires sameQualifiers(Mods, Mods')
     rule #areCompat(
               t(Mods:Set, variableLengthArrayType(T::Type, _)),
               t(Mods':Set, incompleteArrayType(T'::Type)), Cache:Set)
          => #areCompat(T, T', Cache)
          requires sameQualifiers(Mods, Mods')
     rule #areCompat(
               t(Mods:Set, incompleteArrayType(T::Type)),
               t(Mods':Set, incompleteArrayType(T'::Type)), Cache:Set)
          => #areCompat(T, T', Cache)
          requires sameQualifiers(Mods, Mods')

     rule #areCompat(
               t(Mods:Set, pointerType(T::Type)),
               t(Mods':Set, pointerType(T'::Type)), Cache:Set)
          => #areCompat(T, T', Cache)
          requires sameQualifiers(Mods, Mods')

     // Struct and union fields.
     rule #areCompat(
               typedDeclaration(T::Type, X:CId),
               typedDeclaration(T'::Type, X:CId), Cache:Set)
          => #areCompat(T, T', Cache)

     // A function declaration with no arguments is compatible with a
     // declaration with any number of arguments, as long as they're all
     // promoted.

     // TODO(chathhorn): not sufficient?!? -- apparently we also need to look
     // at the argument types in a function definition w/no prototype?
     rule #areCompat(
               t(Mods:Set, functionType(T::Type, .List)),
               t(Mods':Set, functionType(T'::Type, Args':List)), Cache:Set)
          => #areCompat(T, T', Cache)
          requires sameQualifiers(Mods, Mods')
               andBool areArgPromoted(Args')
               andBool notBool (variadic in Args')
     rule #areCompat(
               t(Mods:Set, functionType(T::Type, Args:List)),
               t(Mods':Set, functionType(T'::Type, .List)), Cache:Set)
          => #areCompat(T, T', Cache)
          requires sameQualifiers(Mods, Mods')
               andBool areArgPromoted(Args)
               andBool notBool (variadic in Args)
     rule #areCompat(
               t(Mods:Set, functionType(T::Type,  L:List)),
               t(Mods':Set, functionType(T'::Type, L':List)), Cache:Set)
          => #areCompat(T, T', Cache) andBool #areParamsCompat(L, L', Cache)
          requires (size(L) ==Int size(L'))
               andBool sameQualifiers(Mods, Mods')
     rule #areCompat(_::Type, _::Type, _) => false [owise]

     syntax Bool ::= #areParamsCompat(List, List, Set) [function]
     rule #areParamsCompat(
               ListItem(T:Type) L:List,
               ListItem(T':Type) L':List, Cache:Set)
          => #areCompat(T, T', Cache) andBool #areParamsCompat(L, L', Cache)
     rule #areParamsCompat(ListItem(variadic), ListItem(variadic), _) => true
     rule #areParamsCompat(.List, .List, _) => true

     rule #areCompat(ListItem(T:Type) L:List, ListItem(T':Type) L':List, Cache:Set)
          => #areCompat(T, T', Cache) andBool #areCompat(L, L', Cache)
     rule #areCompat(.List, .List, _) => true

     rule sameQualifiers(Mods:Set, Mods':Set)
          => (intersectSet(Mods, typeQualifiers)
               ==K intersectSet(Mods', typeQualifiers))
               // TODO(chathhorn): treating alignas like a qualifier for now.
               // It's more complicated than this, too, I think -- e.g.,
               // alignas on a definition implies no alignas should be on any
               // declaration.
               andBool ((notBool hasAlignasMod(Mods) andBool notBool hasAlignasMod(Mods'))
                    orElseBool (getAlignasMod(Mods) ==Int getAlignasMod(Mods')))

     rule getAlignas(T:Type) => getAlignasMod(getModifiers(T))
          requires hasAlignasMod(getModifiers(T))
     rule getAlignas(T:Type) => byteAlignofType(T)
          requires notBool hasAlignasMod(getModifiers(T))

     syntax Int ::= getAlignasMod(Set) [function]
     rule getAlignasMod(Mods:Set) => getAlignas'(.K, Mods)

     // TODO(chathhorn): obnoxious unsupported map patterns thing.
     syntax Int ::= "getAlignas'" "(" K "," Set ")" [function]
     rule getAlignas'(.K, .Set) => 1
     rule getAlignas'(.K, SetItem(K:K) Mods:Set) => getAlignas'(K, Mods)
     rule getAlignas'(alignas(A:Int), _) => A
     rule getAlignas'(K:K, Mods:Set) => getAlignas'(.K, Mods)
          requires getKLabel(K) =/=K #klabel(`alignas`)
               andBool (K =/=K .K)

     // We can assume the types are compatible.
     rule compositeType(T:Type, T) => T
     rule compositeType(
               t(Mods:Set, T:SimpleType),
               t(Mods':Set, T:SimpleType))
          // The modifiers might include extra information besides just
          // specifiers and qualifiers, it's probably best to keep it all
          // around for now.
          => t(Mods Mods', T)
          requires isBasicType(t(.Set, T))
               orBool isStructOrUnionType(t(.Set, T))
               orBool isBitfieldType(t(.Set, T))

     // TODO(chathhorn): surely implementation defined, although I don't see
     // composite types for enums explicitly addressed in the standard.
     rule compositeType(
               t(Mods:Set, enumType(_)),
               t(Mods':Set, T:SimpleType))
          => t(Mods Mods', T)
          requires T ==K cfg:enumAlias
     rule compositeType(
               t(Mods:Set, T:SimpleType),
               t(Mods':Set, enumType(_)))
          => t(Mods Mods', T)
          requires T ==K cfg:enumAlias

     rule compositeType(
               t(Mods:Set, functionType(T:Type, P:List)),
               t(Mods':Set, functionType(T':Type, P':List)))
          => compositeFunctionType(compositeType(T, T'), Mods Mods', .K, P, P', .List)

     rule compositeType(
               t(Mods:Set, pointerType(T:Type)),
               t(Mods':Set, pointerType(T':Type)))
          => t(Mods Mods', pointerType(compositeType(T, T')))

     rule compositeType(
               t(Mods:Set, arrayType(T:Type, N:Int)),
               t(Mods':Set, arrayType(T':Type, N)))
          => t(Mods Mods', arrayType(compositeType(T, T'), N))
     rule compositeType(
               t(Mods:Set, arrayType(T:Type, N:Int)),
               t(Mods':Set, incompleteArrayType(T':Type)))
          => t(Mods Mods', arrayType(compositeType(T, T'), N))
     rule compositeType(
               t(Mods:Set, incompleteArrayType(T:Type)),
               t(Mods':Set, arrayType(T':Type, N:Int)))
          => t(Mods Mods', arrayType(compositeType(T, T'), N))
     // TODO(chathhorn): rework VLA composite types.
     rule compositeType(
               t(Mods:Set, arrayType(T:Type, N:Int)),
               t(Mods':Set, variableLengthArrayType(T':Type, _)))
          => t(Mods Mods', arrayType(compositeType(T, T'), N))
     rule compositeType(
               t(Mods:Set, variableLengthArrayType(T:Type, _)),
               t(Mods':Set, arrayType(T':Type, N:Int)))
          => t(Mods Mods', arrayType(compositeType(T, T'), N))
     rule compositeType(
               t(Mods:Set, flexibleArrayType(T:Type)),
               t(Mods':Set, flexibleArrayType(T':Type)))
          => t(Mods Mods', flexibleArrayType(compositeType(T, T')))

     rule compositeType(
               typedDeclaration(T:Type, X:CId),
               typedDeclaration(T':Type, X:CId))
          => typedDeclaration(compositeType(T, T'), X)

     rule compositeType(
               t(Mods:Set, structType(S:StructId)),
               t(Mods':Set, structType(S':StructId)))
          => t(Mods Mods', structType(S:StructId))
          requires getFieldInfo(S') ==K #incomplete
     rule compositeType(
               t(Mods:Set, structType(S:StructId)),
               t(Mods':Set, structType(S':StructId)))
          => t(Mods Mods', structType(S':StructId))
          requires getFieldInfo(S) ==K #incomplete

     // TODO(chathhorn): huge hack. Done like this just so things will "break"
     // when we can't form a composite type. Really need a better way to
     // propagate errors up through layers of function calls like this (or
     // maybe just a better mechanism for crawling ASTs...)
     // TODO(chathhorn): merging; these were anywhere.
     syntax KItem ::= compositeFunctionType(K, Set, K, List, List, List)
          [function]
     rule compositeFunctionType(T:Type, Mods:Set, .K, .List, .List, P':List)
          => t(Mods, functionType(T, P'))
     rule compositeFunctionType(T:Type, Mods:Set, .K, .List, P:List, _)
          => compositeFunctionType(T, Mods, .K, .List, .List, P)
          requires P =/=K .List
     rule compositeFunctionType(T:Type, Mods:Set, .K, P:List, .List, _)
          => compositeFunctionType(T, Mods, .K, .List, .List, P)
          requires P =/=K .List
     rule compositeFunctionType(T:Type, Mods:Set, .K,
          ListItem(variadic), ListItem(variadic), P:List)
          => compositeFunctionType(T, Mods, .K, .List, .List,
               P ListItem(variadic))
     rule compositeFunctionType(T:Type, Mods:Set, .K,
               ListItem(PT:Type) P:List,
               ListItem(PT':Type) P':List, P'':List)
          => compositeFunctionType(T, Mods, compositeType(PT, PT'), P, P', P'')
     rule compositeFunctionType(T:Type, Mods:Set, T':Type, P:List, P':List, P'':List)
          => compositeFunctionType(T, Mods, .K, P, P', P'' ListItem(T'))

endmodule

