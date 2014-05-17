module C-TYPING-COMPATIBILITY-SYNTAX
     syntax Bool ::= "#isCompat" "(" Type "," Type ")" [function]
     syntax Bool ::= sameQualifiers(Set, Set) [function]
endmodule

module C-TYPING-COMPATIBILITY
     imports C-TYPING-COMPATIBILITY-SYNTAX

     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX
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

     syntax Bool ::= "#areCompat" "(" List "," List ")" [function]

     rule areCompatibleTypes(T:Type, T':Type) => #isCompat(T, T') ==K true

     rule #isCompat(T:Type, T) => true 
     rule #isCompat(t(Mods:Set, T:SimpleType), t(Mods':Set, T)) => true 
          when sameQualifiers(Mods, Mods')

     rule #isCompat(
               t(Mods:Set, structType(X:Id, _, fieldInfo(Fs:List, _, _))),
               t(Mods':Set, structType(X:Id, _, fieldInfo(Fs':List, _, _))))
          => #areCompat(Fs, Fs')
          when sameQualifiers(Mods, Mods')
     rule #isCompat(
               t(Mods:Set, structType(X:Id, _, _)),
               t(Mods':Set, incompleteStructType(X:Id)))
          => true
          when sameQualifiers(Mods, Mods')
     rule #isCompat(
               t(Mods:Set, incompleteStructType(X:Id)),
               t(Mods':Set, structType(X:Id, _, _)))
          => true
          when sameQualifiers(Mods, Mods')
     rule #isCompat(
               t(Mods:Set, unionType(X:Id, _, fieldInfo(Fs:List, _, _))),
               t(Mods':Set, unionType(X:Id, _, fieldInfo(Fs':List, _, _))))
          => #areCompat(Fs, Fs')
          when sameQualifiers(Mods, Mods')
     rule #isCompat(
               t(Mods:Set, unionType(X:Id, _, _)),
               t(Mods':Set, incompleteUnionType(X:Id)))
          => true
          when sameQualifiers(Mods, Mods')
     rule #isCompat(
               t(Mods:Set, incompleteUnionType(X:Id)),
               t(Mods':Set, unionType(X:Id, _, _)))
          => true
          when sameQualifiers(Mods, Mods')
     rule #isCompat(
               t(Mods:Set, arrayType(T:Type, N:CSize)),
               t(Mods':Set, arrayType(T':Type, N:CSize)))
          => #isCompat(T, T')
          when sameQualifiers(Mods, Mods')
     rule #isCompat(
               t(Mods:Set, arrayType(T:Type, _)),
               t(Mods':Set, incompleteArrayType(T':Type)))
          => #isCompat(T, T')
          when sameQualifiers(Mods, Mods')
     rule #isCompat(
               t(Mods:Set, incompleteArrayType(T:Type)),
               t(Mods':Set, arrayType(T':Type, _)))
          => #isCompat(T, T')
          when sameQualifiers(Mods, Mods')

     rule #isCompat(
               t(Mods:Set, pointerType(T:Type)),
               t(Mods':Set, pointerType(T':Type)))
          => #isCompat(T, T')
          when sameQualifiers(Mods, Mods')
          
     // Struct and union fields.
     rule #isCompat(
               typedDeclaration(T:Type, X:Id),
               typedDeclaration(T':Type, X:Id))
          => #isCompat(T, T')

     // A function declaration with no arguments is compatible with a
     // declaration with any number of arguments.
     rule #isCompat(
               t(Mods:Set, functionType(T:Type, Args:List)),
               t(Mods':Set, functionType(T':Type, Args':List)))
          => #isCompat(T, T') 
          when ((Args ==List .List) orBool (Args' ==List .List))
               andBool sameQualifiers(Mods, Mods')
     rule #isCompat(
               t(Mods:Set, functionType(T:Type,  L:List)),
               t(Mods':Set, functionType(T':Type, L':List)))
          => #isCompat(T, T') andBool #areParamsCompat(L, L')
          when (lengthList(L) ==Int lengthList(L'))
               andBool sameQualifiers(Mods, Mods')

     syntax Bool ::= "#areParamsCompat" "(" List "," List ")" [function]
     rule #areParamsCompat(
               ListItem(T:Type) L:List,
               ListItem(T':Type) L':List)
          => #isCompat(T, T') andBool #areParamsCompat(L, L')
     rule #areParamsCompat(ListItem(variadic), ListItem(variadic)) => true
     rule #areParamsCompat(.List, .List) => true

     rule #areCompat(ListItem(T:Type) L:List, ListItem(T':Type) L':List)
          => #isCompat(T, T') andBool #areCompat(L, L')
     rule #areCompat(.List, .List) => true

     rule sameQualifiers(Mods:Set, Mods':Set)
          => intersectSet(Mods, typeQualifiers)
               ==Set intersectSet(Mods', typeQualifiers)

     // We can assume the types are compatible.
     rule compositeType(T:Type, T:Type) => T
     rule compositeType(
               t(Mods:Set, T:SimpleType),
               t(Mods':Set, T:SimpleType))
          // The modifiers might include extra information besides just
          // specifiers and qualifiers, it's probably best to keep it all
          // around for now.
          => t(Mods Mods', T)

     rule compositeType(
               t(Mods:Set, functionType(T:Type, P:List)),
               t(Mods':Set, functionType(T':Type, P':List)))
          => t(Mods Mods',
               functionType(compositeType(T, T'), compositeParams(P, P')))

     rule compositeType(
               t(Mods:Set, pointerType(T:Type)),
               t(Mods':Set, pointerType(T':Type)))
          => t(Mods Mods', pointerType(compositeType(T, T')))

     rule compositeType(
               t(Mods:Set, arrayType(T:Type, N:CSize)),
               t(Mods':Set, arrayType(T':Type, N:CSize)))
          => t(Mods Mods', arrayType(compositeType(T, T'), N))
     rule compositeType(
               t(Mods:Set, arrayType(T:Type, N:CSize)),
               t(Mods':Set, incompleteArrayType(T':Type)))
          => t(Mods Mods', arrayType(compositeType(T, T'), N))
     rule compositeType(
               t(Mods:Set, incompleteArrayType(T:Type)),
               t(Mods':Set, arrayType(T':Type, N:CSize)))
          => t(Mods Mods', arrayType(compositeType(T, T'), N))

     rule compositeType(
               t(Mods:Set, flexibleArrayType(T:Type)),
               t(Mods':Set, flexibleArrayType(T':Type)))
          => t(Mods Mods', flexibleArrayType(compositeType(T, T')))

     rule compositeType(
               typedDeclaration(T:Type, X:Id),
               typedDeclaration(T':Type, X:Id))
          => typedDeclaration(compositeType(T, T'), X)

     // TODO(chathhorn): really not sure about these. The standard doesn't seem
     // to mention structs/unions at all when talking about forming composite
     // types, but I think it's got to be defined something like this. There
     // must be some reason this never comes up, though.
     // rule compositeType(
     //           t(Mods:Set,
     //                structType(X:Id, N:CSize, fieldInfo(Fs:List, Ts:Map, Offs:Map))),
     //           t(Mods':Set,
     //                structType(X:Id, N:CSize, fieldInfo(Fs':List, Ts':Map, Offs:Map))))
     //      => t(Mods Mods', structType(X, N, fieldInfo(
     //                compositeFields(Fs, Fs'),
     //                compositeTypes(Ts, Ts'), Offs)))
     // rule compositeType(
     //           t(Mods:Set,
     //                structType(X:Id, N:CSize, fieldInfo(Fs:List, Ts:Map, Offs:Map))),
     //           t(Mods':Set, incompleteStructType(X:Id)))
     //      => t(Mods Mods', structType(X, N, fieldInfo(Fs, Ts, Offs)))
     // rule compositeType(
     //           t(Mods:Set, incompleteStructType(X:Id)),
     //           t(Mods':Set,
     //                structType(X:Id, N:CSize, fieldInfo(Fs':List, Ts':Map, Offs:Map))))
     //      => t(Mods Mods', structType(X, N, fieldInfo(Fs, Ts, Offs)))
     // rule compositeType(
     //           t(Mods:Set, incompleteStructType(X:Id)),
     //           t(Mods':Set, incompleteStructType(X:Id)))
     //      => t(Mods Mods', incompleteStructType(X))

     // rule compositeType(
     //           t(Mods:Set,
     //                unionType(X:Id, N:CSize, fieldInfo(Fs:List, Ts:Map, Offs:Map))),
     //           t(Mods':Set,
     //                unionType(X:Id, N:CSize, fieldInfo(Fs':List, Ts':Map, Offs:Map))))
     //      => t(Mods Mods', unionType(X, N, fieldInfo(
     //                compositeFields(Fs, Fs'),
     //                compositeTypes(Ts, Ts'), Offs)))
     // rule compositeType(
     //           t(Mods:Set,
     //                unionType(X:Id, N:CSize, fieldInfo(Fs:List, Ts:Map, Offs:Map))),
     //           t(Mods':Set, incompleteUnionType(X:Id)))
     //      => t(Mods Mods', unionType(X, N, fieldInfo(Fs, Ts, Offs)))
     // rule compositeType(
     //           t(Mods:Set, incompleteUnionType(X:Id)),
     //           t(Mods':Set,
     //                unionType(X:Id, N:CSize, fieldInfo(Fs':List, Ts':Map, Offs:Map))))
     //      => t(Mods Mods', unionType(X, N, fieldInfo(Fs, Ts, Offs)))
     // rule compositeType(
     //           t(Mods:Set, incompleteUnionType(X:Id)),
     //           t(Mods':Set, incompleteUnionType(X:Id)))
     //      => t(Mods Mods', incompleteUnionType(X))

     // syntax List ::= compositeFields(List, List)
     // rule compositeFields(ListItem(T:Type) Fs:List, ListItem(T':Type) Fs':List)
     //      => ListItem(compositeType(T, T')) compositeFields(Fs, Fs')
     // rule compositeFields(.List, .List) => .List

     // syntax Map ::= compositeTypes(Map, Map)
     // rule compositeTypes(X:Id |-> T:Type Ts:Map, X:Id |-> T':Type Ts':Map)
     //      => X |-> compositeType(T, T') compositeTypes(Ts, Ts')
     // rule compositeTypes(.Map, .Map) => .List

     // We replace all ids in non-def param lists with #NoName, so we can get
     // away with this.
     syntax List ::= compositeParams(List, List) [function]
     rule compositeParams(.List, P:List) => P
     rule compositeParams(P:List, .List) => P
     rule compositeParams(ListItem(variadic), ListItem(variadic))
          => ListItem(variadic)
     rule compositeParams(
               ListItem(T:Type) P:List,
               ListItem(T':Type) P':List)
          => ListItem(compositeType(T, T')) compositeParams(P, P')
     
endmodule

