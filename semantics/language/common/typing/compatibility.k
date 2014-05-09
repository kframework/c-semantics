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

     // TODO(chathhorn): I think there are various notions of type
     // compatibility being conflated here.
     // TODO(chathhorn): const?
     rule isTypeCompatible(T1:Type, T2:Type) 
          => #isCompat(stripStorageSpecifiers(T1), stripStorageSpecifiers(T2))
               ==K true

     rule #isCompat(T:Type, T:Type) => true 
     rule #isCompat(T:Type, T':Type) => true 
          when hasIntegerType(T)
               andBool hasIntegerType(T') 
               andBool (getQualifiers(T) ==Set getQualifiers(T'))

     // TODO(chathhorn): struct/union fields and unnameds.
     rule #isCompat(
               t(Quals:Set, structType(_, _, fieldInfo(Fs:List, _, _))),
               t(Quals:Set, structType(_, _, fieldInfo(Fs':List, _, _))))
          => #areCompat(Fs, Fs')
     // rule #isCompat(
     //           t(Quals:Set, structType(X:Id, _, _)),
     //           t(Quals:Set, incompleteStructType(X:Id)))
     //      => true
     // rule #isCompat(
     //           t(Quals:Set, incompleteStructType(X:Id)),
     //           t(Quals:Set, structType(X:Id, _, _)))
     //      => true
     rule #isCompat(
               t(Quals:Set, unionType(_, _, fieldInfo(Fs:List, _, _))),
               t(Quals:Set, unionType(_, _, fieldInfo(Fs':List, _, _))))
          => #areCompat(Fs, Fs')
     // rule #isCompat(
     // rule #isCompat(
     //           t(Quals:Set, unionType(_, _, _)),
     //           t(Quals:Set, incompleteUnionType(_)))
     //      => true
     // rule #isCompat(
     //           t(Quals:Set, incompleteUnionType(_)),
     //           t(Quals:Set, unionType(_, _, _)))
     //      => true
     rule #isCompat(
               t(Quals:Set, arrayType(T:Type, N:Int)),
               t(Quals:Set, arrayType(T':Type, N:Int)))
          => #isCompat(T, T')
     rule #isCompat(
               t(Quals:Set, arrayType(T:Type, _)),
               t(Quals:Set, incompleteArrayType(T':Type)))
          => #isCompat(T, T')
     rule #isCompat(
               t(Quals:Set, incompleteArrayType(T:Type)),
               t(Quals:Set, arrayType(T':Type, _)))
          => #isCompat(T, T')

     rule #isCompat(
               t(Quals:Set, pointerType(T:Type)),
               t(Quals:Set, pointerType(T':Type)))
          => #isCompat(T, T')
          
     // Struct and union fields.
     rule #isCompat(
               typedDeclaration(T:Type, X:Id),
               typedDeclaration(T':Type, X:Id))
          => #isCompat(T, T')

     // TODO(chathhorn): left over from something?
     // rule #isCompat(t(Quals:Set, pointerType(_)), T:Type) => true
     //      when hasIntegerType(T) 
     // rule #isCompat(T:Type, t(Quals:Set, pointerType(_))) => true
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
               t(Quals:Set, functionType(T:Type, Args:List)),
               t(Quals:Set, functionType(T':Type, Args':List)))
          => #isCompat(T, T') 
          when (Args ==List .List) orBool (Args' ==List .List)
     rule #isCompat(
               t(Quals:Set, functionType(T:Type,  L:List)),
               t(Quals:Set, functionType(T':Type, L':List)))
          => #isCompat(T, T') andBool #areParamsCompat(L, L')
          when lengthList(L) ==Int lengthList(L')

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

endmodule

