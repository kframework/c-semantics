module C-TYPING-COMPATIBILITY
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

     syntax Bool ::= "#isCompat" "(" Type "," Type ")" [function]
     syntax Bool ::= "#areCompat" "(" List "," List ")" [function]

     rule isTypeCompatible(T1:Type, T2:Type) 
          => #isCompat(stripStorageSpecifiers(T1), stripStorageSpecifiers(T2))
               ==K true

     rule #isCompat(T:Type, T:Type) => true 
     rule #isCompat(T:Type, T':Type) => true 
          when hasIntegerType(T)
               andBool hasIntegerType(T') 
               andBool (getQualifiers(T) ==Set getQualifiers(T'))

     rule #isCompat(
               t(Mods:Set, structType(X:Id, _, fieldInfo(Fs:List, _, _))),
               t(Mods':Set, structType(X:Id, _, fieldInfo(Fs':List, _, _))))
          => #areCompat(Fs, Fs')
          when sameQualifiers(Mods, Mods')
     rule #isCompat(
               t(Mods:Set, structType(unnamed(_, _), _, fieldInfo(Fs:List, _, _))),
               t(Mods':Set, structType(unnamed(_, _), _, fieldInfo(Fs':List, _, _))))
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
               t(Mods:Set, unionType(unnamed(_, _), _, fieldInfo(Fs:List, _, _))),
               t(Mods':Set, unionType(unnamed(_, _), _, fieldInfo(Fs':List, _, _))))
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
               t(Mods:Set, arrayType(T:Type, N:Int)),
               t(Mods':Set, arrayType(T':Type, N:Int)))
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

     // TODO(chathhorn): left over from something?
     // rule #isCompat(t(Mods:Set, pointerType(_)), T:Type) => true
     //      when hasIntegerType(T) 
     // rule #isCompat(T:Type, t(Mods:Set, pointerType(_))) => true
     //      when hasIntegerType(T)

     // rule #isCompat(T:Type, t(S:Set, arrayType(T':Type, _)))
     //      => #isCompat(T, t(S:Set, pointerType(T'))) 
     // rule #isCompat(t(S:Set, arrayType(T:Type, _)), T':Type)
     //      => #isCompat(t(S, pointerType(T)), T') 
     
     // rule #isCompat(T:Type, t(S:Set, incompleteArrayType(T':Type)))
     //      => #isCompat(T, t(S, pointerType(T'))) 
     // rule #isCompat(t(S:Set, incompleteArrayType(T:Type)), T':Type)
     //      => #isCompat(t(S, pointerType(T)), T') 

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
               ListItem(typedDeclaration(T:Type, _)) L:List,
               ListItem(typedDeclaration(T':Type, _)) L':List)
          => #isCompat(T, T') andBool #areParamsCompat(L, L')
     rule #areParamsCompat(ListItem(variadic), ListItem(variadic)) => true
     rule #areParamsCompat(.List, .List) => true

     rule #areCompat(ListItem(T:Type) L:List, ListItem(T':Type) L':List)
          => #isCompat(T, T') andBool #areCompat(L, L')
     rule #areCompat(.List, .List) => true

     syntax Bool ::= sameQualifiers(Set, Set) [function]
     rule sameQualifiers(Mods:Set, Mods':Set)
          => intersectSet(Mods, typeQualifiers)
               ==Set intersectSet(Mods', typeQualifiers)
endmodule

