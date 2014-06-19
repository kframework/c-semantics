module C-COMMON-EXPR-CONDITIONAL-SYNTAX
     // TODO(chathhorn): error check
     syntax K ::= types(List)
endmodule

module C-COMMON-EXPR-CONDITIONAL
     imports C-COMMON-EXPR-CONDITIONAL-SYNTAX

     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX

     syntax K ::= getTypes(List)
     context types(_:List ListItem(HOLE) _:List)
     syntax K ::= convertedType(K) [strict]

     rule getTypes(L:List) => types(wrapWithTypeOf(L)) [structural]

     syntax List ::=  wrapWithTypeOf(List) [function]
     rule wrapWithTypeOf(ListItem(K:K) L:List)
          => ListItem(retype(typeof(K))) wrapWithTypeOf(L)
     rule wrapWithTypeOf(.List) => .List

     syntax K ::= retype(K) [strict]

     // fixme, not handling qualifiers correctly
     rule retype(T:Type) => t(.Set, pointerType(innerType(T)))
          when isArrayType(T)
          [structural]
     rule retype(T:Type) => t(.Set, pointerType(T))
          when isFunctionType(T)
          [structural]
     rule retype(T:Type) => T
          when notBool (isArrayType(T) orBool isFunctionType(T))
          [structural]
     /*@ \fromStandard{\source[n1570]{\para{6.5.15}{4}}}{
     The first operand is evaluated; there is a sequence point between its
     evaluation and the evaluation of the second or third operand (whichever is
     evaluated). The second operand is evaluated only if the first compares
     unequal to 0; the third operand is evaluated only if the first compares
     equal to 0; the result is the value of the second or third operand
     (whichever is evaluated), converted to the type described below.
     }*/
     rule (. => getTypes(ListItem(E1) ListItem(E2))) ~> _ ? E1:K : E2:K 
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.15}{5}}}{
     If both the second and third operands have arithmetic type, the result
     type that would be determined by the usual arithmetic conversions, were
     they applied to those two operands, is the type of the result. If both the
     operands have structure or union type, the result has that type. If both
     operands have void type, the result has void type.
     }*/
     rule (types(ListItem(T1:Type) ListItem(T2:Type))
          => convertedType(usualArithmeticConversion(T1, T2)))
               ~> _ ? _ : _
          when T1 =/=K T2
               andBool hasArithmeticType(T1)
               andBool hasArithmeticType(T2)
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.15}{6}}}{
     \broken{If both the second and third operands are pointers or one is a
     null pointer constant and the other is a pointer, the result type is a
     pointer to a type qualified with all the type qualifiers of the types
     referenced by both operands. Furthermore, if both operands are pointers to
     compatible types or to differently qualified versions of compatible types,
     the result type is a pointer to an appropriately qualified version of the
     composite type}; if one operand is a null pointer constant, the result has
     the type of the other operand; otherwise, one operand is a pointer
     to void or a qualified version of \cinline{void}, in which case the result
     type is a pointer to an appropriately qualified version of
     \cinline{void}.}
     }*/
     // fixme, this is too relaxed; could be any integer zero.  need static
     // semantics to handle this properly
     rule (types(ListItem(T1:Type) ListItem(T2:Type)) => convertedType(T2))
          ~> _ ? tv(0, T1) : _
          when hasIntegerType(T1) andBool isPointerType(T2)
          [structural]
     rule (types(ListItem(T1:Type) ListItem(T2:Type)) => convertedType(T1))
          ~> _? _ : tv(0, T2)
          when hasIntegerType(T2) andBool isPointerType(T1)
          [structural]

     rule (types(
               ListItem(t(Mods:Set, pointerType(T:Type)))
               ListItem(t(Mods':Set, pointerType(T':Type)))
          ) => convertedType(t(Mods Mods', pointerType(compositeType(T, T')))))
          ~> _? _ : _
          when areCompatible(stripQualifiers(T), stripQualifiers(T'))
          [structural]

     rule (types(
               ListItem(t(Mods1:Set, pointerType(t(Mods1':Set, void))))
               ListItem(t(Mods2:Set, pointerType(t(Mods2':Set, _))))
          ) => convertedType(t(Mods1 Mods2, pointerType(t(Mods1' Mods2', void)))))
          ~> _? _ : _
          [structural]
     rule (types(
               ListItem(t(Mods1:Set, pointerType(t(Mods1':Set, _))))
               ListItem(t(Mods2:Set, pointerType(t(Mods2':Set, void))))
          ) => convertedType(t(Mods1 Mods2, pointerType(t(Mods1' Mods2', void)))))
          ~> _? _ : _
          [structural]

     // this should take care of the void/struct cases
     rule (types(ListItem(T:Type) ListItem(T':Type)) => convertedType(T))
          ~> _ ? _ : _
          when notBool isPointerType(T)
               andBool areCompatible(T, T')
          [structural]
     rule convertedType(T:Type) ~> E:K ? E1:K : E2:K
          => IfThenElse(E, Cast(T, E1), Cast(T, E2))
          [structural]

     rule (. => ERROR("00041", "If one of a conditional expression's branches has void type, the other must also have void type.", "6.5.15:3") ) ~>
          types(ListItem(t(_, void)) ListItem(t(_, T:SimpleType)))
          when T =/=K void
          [structural]
     rule (. => ERROR("00042", "If one of a conditional expression's branches has void type, the other must also have void type.") ) ~>
          types(ListItem(t(_, T:SimpleType)) ListItem(t(_, void)))
          when T =/=K void
          [structural]
     rule (. => ERROR("00043", "If one of a conditional expression's branches has struct or union type, the other must have the same type.", "6.5.15:3") ) ~>
          types(ListItem(T:Type) ListItem(T':Type))
          when (T =/=K T')
               andBool (isStructType(T) orBool isUnionType(T))
               andBool (isStructType(T') orBool isUnionType(T'))
          [structural]
endmodule

