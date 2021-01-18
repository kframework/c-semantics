module C-TYPING-COMPATIBILITY-SYNTAX
     syntax Type ::= compositeType(Type, Type) [function]
     syntax UType ::= compositeType(UType, UType) [function]

     syntax Bool ::= areDeclCompat(Type, Type) [function]

endmodule

module C-TYPING-COMPATIBILITY
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports BASIC-K
     imports BOOL
     imports INT
     imports K-EQUAL
     imports LIST
     imports SET
     imports COMMON-SORTS
     imports COMPAT-SYNTAX
     imports C-COMMON-PROMOTION-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-TYPING-SYNTAX

     rule T::Type ==Type T'::Type => areCompatible(T, T')
     rule T::Type =/=Type T'::Type => notBool areCompatible(T, T')

     rule T::UType ==Type T'::UType => areCompatible(type(T), type(T'))
     rule T::UType =/=Type T'::UType => notBool areCompatible(type(T), type(T'))

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

     syntax Bool ::= areCompatible(Type, Type) [function, klabel(areCompatibleType)]
     rule areCompatible(T::Type, T'::Type) => #areCompat(T, T', .Set)

     syntax Bool ::= areCompatible(UType, UType) [function, klabel(areCompatibleUType)]
     rule areCompatible(T::UType, T'::UType) => #areCompat(type(T), type(T'), .Set)

     syntax Bool ::= #areCompat(Type, Type, Set) [function]
     rule #areCompat(
               t(Qs::Quals, _, T:SimpleBasicType),
               t(Qs       , _, T), _)
          => true
     rule #areCompat(
               t(Qs::Quals, _, signed-int),
               t(Qs       , _, int), _)
          => true
     rule #areCompat(
               t(Qs::Quals, _, int),
               t(Qs       , _, signed-int), _)
          => true

     // TODO(chathhorn): should be a setting.
     // Each enumerated type shall be compatible with char, a signed integer
     // type, or an unsigned integer type. The choice of type is
     // implementation-defined. (6.7.2.2:4)
     rule #areCompat(
               t(Qs::Quals, Mods::Set, enumType(S::TagId)),
               t(Qs, Mods'::Set, T::SimpleType), _)
          => true
          requires T ==K getEnumAlias(S)
     rule #areCompat(
               t(Qs::Quals, Mods::Set, T::SimpleType),
               t(Qs, Mods'::Set, enumType(S::TagId)), _)
          => true
          requires T ==K getEnumAlias(S)

     // TODO(chathhorn): should also check for equivalent members
     rule #areCompat(
               t(Qs::Quals, Mods::Set, enumType(S::TagId)),
               t(Qs, Mods'::Set, enumType(S'::TagId)), _)
          => #areTagsCompat(getTag(S), getTag(S'))

     rule #areCompat(
               t(Qs::Quals, _, structType(S::TagId)) #as T::Type,
               t(Qs, _, structType(S'::TagId)) #as T'::Type, Cache::Set)
          => true
          requires S ==K S'
               orBool kpair(S, S') in Cache
               orBool (#areTagsCompat(getTag(S), getTag(S'))
                    andBool #areStructsCompat(getFields(T), getFields(T'),
                    Cache SetItem(kpair(S, S'))))
     rule #areCompat(
               t(Qs::Quals, _, unionType(S::TagId)) #as T::Type,
               t(Qs, _, unionType(S'::TagId)) #as T'::Type, Cache::Set)
          => true
          requires S ==K S'
               orBool kpair(S, S') in Cache
               orBool (#areTagsCompat(getTag(S), getTag(S'))
                    andBool #areStructsCompat(getFields(T), getFields(T'),
                    Cache SetItem(kpair(S, S'))))

     syntax Bool ::= #areStructsCompat(FieldInfo, FieldInfo, Set) [function, memo]
     // TODO: are they compatible even if one was packed using attribute or pragma?
     rule #areStructsCompat(fieldInfo(Fs::List, _, _, _, _, _), fieldInfo(Fs'::List, _, _, _, _, _), Cache::Set)
          => #areCompatFields(Fs, Fs', Cache)
          requires Fs =/=K .List andBool Fs' =/=K .List
     rule #areStructsCompat(_, _, _) => true [owise]

     syntax Bool ::= #areTagsCompat(K, K) [function]
     rule #areTagsCompat(C::CId, C::CId) => true
     rule #areTagsCompat(unnamed(_, _), unnamed(_, _)) => true
     rule #areTagsCompat(_, _) => false [owise]

     rule #areCompat(
               t(Qs::Quals, Mods::Set, bitfieldType(T::SimpleType, Width::Int)),
               t(Qs'::Quals, Mods'::Set, bitfieldType(T'::SimpleType, Width::Int)), Cache::Set)
          => #areCompat(t(Qs, Mods, T), t(Qs', Mods', T'), Cache)

     rule #areCompat(
               t(Qs::Quals, Mods::Set, arrayType(T::Type, N::Int)),
               t(Qs, Mods'::Set, arrayType(T'::Type, N)), Cache::Set)
          => #areCompat(T, T', Cache)

     rule #areCompat(
               t(Qs::Quals, _, arrayType(T::Type, _)),
               t(Qs, _, incompleteArrayType(T'::Type)), Cache::Set)
          => #areCompat(T, T', Cache)
     rule #areCompat(
               t(Qs::Quals, _, arrayType(T::Type, _)),
               t(Qs, _, flexibleArrayType(T'::Type)), Cache::Set)
          => #areCompat(T, T', Cache)
     rule #areCompat(
               t(Qs::Quals, _, incompleteArrayType(T::Type)),
               t(Qs, _, arrayType(T'::Type, _)), Cache::Set)
          => #areCompat(T, T', Cache)
     rule #areCompat(
               t(Qs::Quals, _, flexibleArrayType(T::Type)),
               t(Qs, _, arrayType(T'::Type, _)), Cache::Set)
          => #areCompat(T, T', Cache)

     rule #areCompat(
               t(Qs::Quals, _, arrayType(T::Type, _)),
               t(Qs, _, unspecifiedArrayType(T'::Type)), Cache::Set)
          => #areCompat(T, T', Cache)
     rule #areCompat(
               t(Qs::Quals, _, arrayType(T::Type, _)),
               t(Qs, _, variableLengthArrayType(T'::Type, _)), Cache::Set)
          => #areCompat(T, T', Cache)
     rule #areCompat(
               t(Qs::Quals, _, unspecifiedArrayType(T::Type)),
               t(Qs, _, arrayType(T'::Type, _)), Cache::Set)
          => #areCompat(T, T', Cache)
     rule #areCompat(
               t(Qs::Quals, _, variableLengthArrayType(T::Type, _)),
               t(Qs, _, arrayType(T'::Type, _)), Cache::Set)
          => #areCompat(T, T', Cache)

     // Two variable length arrays are compatible, but it's undefined if
     // they're used in an expression where they're required to be compat but
     // they have different sizes.
     rule #areCompat(
               t(Qs::Quals, _, unspecifiedArrayType(T::Type)),
               t(Qs, _, unspecifiedArrayType(T'::Type)), Cache::Set)
          => #areCompat(T, T', Cache)
     rule #areCompat(
               t(Qs::Quals, _, variableLengthArrayType(T::Type, _)),
               t(Qs, _, variableLengthArrayType(T'::Type, _)), Cache::Set)
          => #areCompat(T, T', Cache)
     rule #areCompat(
               t(Qs::Quals, _, unspecifiedArrayType(T::Type)),
               t(Qs, _, variableLengthArrayType(T'::Type, _)), Cache::Set)
          => #areCompat(T, T', Cache)
     rule #areCompat(
               t(Qs::Quals, _, variableLengthArrayType(T::Type, _)),
               t(Qs, _, unspecifiedArrayType(T'::Type)), Cache::Set)
          => #areCompat(T, T', Cache)

     rule #areCompat(
               t(Qs::Quals, _, incompleteArrayType(T::Type)),
               t(Qs, _, unspecifiedArrayType(T'::Type)), Cache::Set)
          => #areCompat(T, T', Cache)
     rule #areCompat(
               t(Qs::Quals, _, incompleteArrayType(T::Type)),
               t(Qs, _, variableLengthArrayType(T'::Type, _)), Cache::Set)
          => #areCompat(T, T', Cache)
     rule #areCompat(
               t(Qs::Quals, _, flexibleArrayType(T::Type)),
               t(Qs, _, variableLengthArrayType(T'::Type, _)), Cache::Set)
          => #areCompat(T, T', Cache)
     rule #areCompat(
               t(Qs::Quals, _, flexibleArrayType(T::Type)),
               t(Qs, _, unspecifiedArrayType(T'::Type)), Cache::Set)
          => #areCompat(T, T', Cache)

     rule #areCompat(
               t(Qs::Quals, _, unspecifiedArrayType(T::Type)),
               t(Qs, _, incompleteArrayType(T'::Type)), Cache::Set)
          => #areCompat(T, T', Cache)
     rule #areCompat(
               t(Qs::Quals, _, variableLengthArrayType(T::Type, _)),
               t(Qs, _, incompleteArrayType(T'::Type)), Cache::Set)
          => #areCompat(T, T', Cache)
     rule #areCompat(
               t(Qs::Quals, _, variableLengthArrayType(T::Type, _)),
               t(Qs, _, flexibleArrayType(T'::Type)), Cache::Set)
          => #areCompat(T, T', Cache)
     rule #areCompat(
               t(Qs::Quals, _, unspecifiedArrayType(T::Type)),
               t(Qs, _, flexibleArrayType(T'::Type)), Cache::Set)
          => #areCompat(T, T', Cache)

     rule #areCompat(
               t(Qs::Quals, _, incompleteArrayType(T::Type)),
               t(Qs, _, incompleteArrayType(T'::Type)), Cache::Set)
          => #areCompat(T, T', Cache)
     rule #areCompat(
               t(Qs::Quals, _, flexibleArrayType(T::Type)),
               t(Qs, _, incompleteArrayType(T'::Type)), Cache::Set)
          => #areCompat(T, T', Cache)
     rule #areCompat(
               t(Qs::Quals, _, flexibleArrayType(T::Type)),
               t(Qs, _, flexibleArrayType(T'::Type)), Cache::Set)
          => #areCompat(T, T', Cache)
     rule #areCompat(
               t(Qs::Quals, _, incompleteArrayType(T::Type)),
               t(Qs, _, flexibleArrayType(T'::Type)), Cache::Set)
          => #areCompat(T, T', Cache)

     rule #areCompat(
               t(Qs::Quals, Mods::Set, pointerType(T::Type)),
               t(Qs, Mods'::Set, pointerType(T'::Type)), Cache::Set)
          => #areCompat(T, T', Cache)

     // A function declaration with no arguments is compatible with a
     // declaration with any number of arguments, as long as they're all
     // promoted.

     // TODO(chathhorn): not sufficient?!? -- apparently we also need to look
     // at the argument types in a function definition w/no prototype?
     rule #areCompat(
               t(Qs::Quals, Mods::Set, functionType(T::UType, .List)),
               t(Qs, Mods'::Set, functionType(T'::UType, Args'::List)), Cache::Set)
          => #areCompat(type(T), type(T'), Cache)
          requires areArgPromoted(Args')
               andBool notBool (variadic in Args')
     rule #areCompat(
               t(Qs::Quals, Mods::Set, functionType(T::UType, Args::List)),
               t(Qs, Mods'::Set, functionType(T'::UType, .List)), Cache::Set)
          => #areCompat(type(T), type(T'), Cache)
          requires areArgPromoted(Args)
               andBool notBool (variadic in Args)
     rule #areCompat(
               t(Qs::Quals, Mods::Set, functionType(T::UType,  L::List)),
               t(Qs, Mods'::Set, functionType(T'::UType, L'::List)), Cache::Set)
          => #areCompat(type(T), type(T'), Cache)
               andBool #areParamsCompat(L, L', Cache)
          requires size(L) ==Int size(L')
     rule #areCompat(_, _, _) => false [owise]

     syntax Bool ::= #areParamsCompat(List, List, Set) [function]
     rule #areParamsCompat(
               ListItem(T::KItem) L::List,
               ListItem(T'::KItem) L'::List, Cache::Set)
          => T ==K T' andBool #areParamsCompat(L, L', Cache)
          requires T ==K variadic orBool T' ==K variadic
     rule #areParamsCompat(
               ListItem(typedDeclaration(T::Type, _)) L::List,
               ListItem(typedDeclaration(T'::Type, _)) L'::List, Cache::Set)
          => #areCompat(stripQualifiers(T), stripQualifiers(T'), Cache)
               andBool #areParamsCompat(L, L', Cache)
     rule #areParamsCompat(
               ListItem(t(...) #as T::Type) L::List,
               ListItem(typedDeclaration(T'::Type, _)) L'::List, Cache::Set)
          => #areCompat(stripQualifiers(T), stripQualifiers(T'), Cache)
               andBool #areParamsCompat(L, L', Cache)
     rule #areParamsCompat(
               ListItem(typedDeclaration(T::Type, _)) L::List,
               ListItem(t(...) #as T'::Type) L'::List, Cache::Set)
          => #areCompat(stripQualifiers(T), stripQualifiers(T'), Cache)
               andBool #areParamsCompat(L, L', Cache)
     rule #areParamsCompat(
               ListItem(t(...) #as T::Type) L::List,
               ListItem(t(...) #as T'::Type) L'::List, Cache::Set)
          => #areCompat(stripQualifiers(T), stripQualifiers(T'), Cache)
               andBool #areParamsCompat(L, L', Cache)
     rule #areParamsCompat(.List, .List, _) => true
     rule #areParamsCompat(_, _, _) => false [owise]

     syntax Bool ::= #areCompatFields(List, List, Set) [function]
     rule #areCompatFields(
                    ListItem(typedDeclaration(T::Type, X::CId)) L::List,
                    ListItem(typedDeclaration(T'::Type, X'::CId)) L'::List, Cache::Set)
          => #areCompatIds(X, X') andBool #areCompat(T, T', Cache) andBool #areCompatFields(L, L', Cache)
     rule #areCompatFields(.List, .List, _) => true
     rule #areCompatFields(_:List, _, _) => false [owise]

     syntax Bool ::= #areCompatIds(CId, CId) [function]
     rule #areCompatIds(X::CId, X) => true
     rule #areCompatIds(_:NoName, _:NoName) => true
     rule #areCompatIds(_, _) => false [owise]

     rule compositeType(T:UType, T':UType)
          => utype(compositeType(type(T), type(T')))

     // We can assume the types are compatible.
     rule compositeType(T:Type, T) => T
     rule compositeType(
               t(Qs::Quals, Mods::Set, T::SimpleType),
               t(Qs'::Quals, Mods'::Set, T::SimpleType))
          // The modifiers might include extra information besides just
          // specifiers, it's probably best to keep it all around for now.
          => t(Qs +Quals Qs', Mods Mods', T)
          requires isBasicType(type(T))
               orBool isStructOrUnionType(type(T))
               orBool isBitfieldType(type(T))

     // TODO(chathhorn): surely implementation defined, although I don't see
     // composite types for enums explicitly addressed in the standard.
     rule compositeType(
               t(Qs::Quals, Mods::Set, enumType(S::TagId)),
               t(Qs'::Quals, Mods'::Set, T::SimpleType))
          => t(Qs +Quals Qs', Mods Mods', T)
          requires T ==K getEnumAlias(S)
     rule compositeType(
               t(Qs::Quals, Mods::Set, T::SimpleType),
               t(Qs'::Quals, Mods'::Set, enumType(S::TagId)))
          => t(Qs +Quals Qs', Mods Mods', T)
          requires T ==K getEnumAlias(S)

     rule compositeType(
               t(Qs::Quals, Mods:Set, functionType(T::UType, P:List)),
               t(Qs'::Quals, Mods'::Set, functionType(T'::UType, P':List)))
          => compositeFunctionType(compositeType(T, T'), Qs +Quals Qs', Mods Mods', P, P', .List)

     rule compositeType(
               t(Qs::Quals, Mods::Set, pointerType(T:Type)),
               t(Qs'::Quals, Mods'::Set, pointerType(T':Type)))
          => t(Qs +Quals Qs', Mods Mods', pointerType(compositeType(T, T')))

     rule compositeType(
               t(Qs::Quals, Mods::Set, arrayType(T:Type, N:Int)),
               t(Qs'::Quals, Mods'::Set, arrayType(T':Type, N)))
          => t(Qs +Quals Qs', Mods Mods', arrayType(compositeType(T, T'), N))
     rule compositeType(
               t(Qs::Quals, Mods::Set, arrayType(T:Type, N:Int)),
               t(Qs'::Quals, Mods'::Set, incompleteArrayType(T':Type)))
          => t(Qs +Quals Qs', Mods Mods', arrayType(compositeType(T, T'), N))
     rule compositeType(
               t(Qs::Quals, Mods::Set, incompleteArrayType(T:Type)),
               t(Qs'::Quals, Mods'::Set, arrayType(T':Type, N:Int)))
          => t(Qs +Quals Qs', Mods Mods', arrayType(compositeType(T, T'), N))
     rule compositeType(
               t(Qs::Quals, Mods:Set, arrayType(T:Type, N:Int)),
               t(... st: _:SimpleVariableArrayType) #as T'::Type)
          => t(Qs +Quals getQualifiers(T'), Mods getModifiers(T'), arrayType(compositeType(T, innerType(T')), N))
     rule compositeType(
               t(... st: _:SimpleVariableArrayType) #as T::Type,
               t(Qs'::Quals, Mods':Set, arrayType(T':Type, N:Int)))
          => t(getQualifiers(T) +Quals Qs', getModifiers(T) Mods', arrayType(compositeType(innerType(T), T'), N))
     rule compositeType(
               t(Qs::Quals, Mods:Set, variableLengthArrayType(T:Type, E:K)),
               t(Qs'::Quals, Mods':Set, variableLengthArrayType(T':Type, _)))
          => t(Qs +Quals Qs', Mods Mods', variableLengthArrayType(compositeType(T, T'), E))
     rule compositeType(
               t(Qs::Quals, Mods:Set, unspecifiedArrayType(T:Type)),
               t(Qs'::Quals, Mods':Set, variableLengthArrayType(T':Type, E:K)))
          => t(Qs +Quals Qs', Mods Mods', variableLengthArrayType(compositeType(T, T'), E))
     rule compositeType(
               t(Qs'::Quals, Mods':Set, variableLengthArrayType(T:Type, E:K)),
               t(Qs::Quals, Mods:Set, unspecifiedArrayType(T':Type)))
          => t(Qs +Quals Qs', Mods Mods', variableLengthArrayType(compositeType(T, T'), E))
     rule compositeType(
               t(Qs'::Quals, Mods':Set, unspecifiedArrayType(T:Type)),
               t(Qs::Quals, Mods:Set, unspecifiedArrayType(T':Type)))
          => t(Qs +Quals Qs', Mods Mods', unspecifiedArrayType(compositeType(T, T')))
     rule compositeType(
               t(Qs::Quals, Mods:Set, flexibleArrayType(T:Type)),
               t(Qs'::Quals, Mods':Set, flexibleArrayType(T':Type)))
          => t(Qs +Quals Qs', Mods Mods', flexibleArrayType(compositeType(T, T')))

     rule compositeType(
               t(Qs::Quals, Mods:Set, structType(S::TagId)),
               t(Qs'::Quals, Mods':Set, structType(S'::TagId)))
          => t(Qs +Quals Qs', Mods Mods', structType(S::TagId))
          requires getTagInfo(S') ==K #incomplete
     rule compositeType(
               t(Qs::Quals, Mods:Set, structType(S::TagId)),
               t(Qs'::Quals, Mods':Set, structType(S'::TagId)))
          => t(Qs +Quals Qs', Mods Mods', structType(S'::TagId))
          requires getTagInfo(S) ==K #incomplete

     syntax Type ::= compositeFunctionType(UType, Quals, Set, List, List, List) [function]
     rule compositeFunctionType(R::UType, Qs::Quals, Mods::Set, .List, .List, P'::List)
          => t(Qs, Mods, functionType(R, P'))
     rule compositeFunctionType(_, _, _, .List, (P::List => .List), (_ => P))
          requires P =/=K .List
     rule compositeFunctionType(_, _, _, (P::List => .List), .List, (_ => P))
          requires P =/=K .List
     rule compositeFunctionType(_, _, _,
               (ListItem(variadic) => .List),
               (ListItem(variadic) => .List),
               _:List (.List => ListItem(variadic)))
     rule compositeFunctionType(_, _, _,
               (ListItem(P:Type) => .List) _:List,
               (ListItem(P':Type) => .List) _:List,
               _:List (.List => ListItem(compositeType(P, P'))))
     rule compositeFunctionType(_, _, _,
               (ListItem(P:Type) => .List) _:List,
               (ListItem(typedDeclaration(P'::Type, X::CId)) => .List) _:List,
               _:List (.List => ListItem(typedDeclaration(compositeType(P, P'), X))))
     rule compositeFunctionType(_, _, _,
               (ListItem(typedDeclaration(P::Type, X::CId)) => .List) _:List,
               (ListItem(P':Type) => .List) _:List,
               _:List (.List => ListItem(typedDeclaration(compositeType(P, P'), X))))
     rule compositeFunctionType(_, _, _,
               (ListItem(typedDeclaration(P::Type, X:CId)) => .List) _:List,
               (ListItem(typedDeclaration(P'::Type, _)) => .List) _:List,
               _:List (.List => ListItem(typedDeclaration(compositeType(P, P'), X))))

     rule areDeclCompat(T::Type, T'::Type) => T ==Type T' andBool sameAlignas(getModifiers(T), getModifiers(T'))
endmodule

