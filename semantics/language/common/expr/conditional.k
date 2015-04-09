module C-COMMON-EXPR-CONDITIONAL
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-PROMOTION-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX

     syntax KItem ::= getTypes(List)
     //TODO(liyili2): overcome the context associative matching
     //context types(_:List ListItem(HOLE) _:List)
     syntax KItem ::= convertedType(K) [strict]

     rule getTypes(L:List) => types(toTypeList(wrapWithTypeOf(L))) [structural]

     syntax KItem ::= types(TypeList) [strict]

     syntax TypeList ::= toTypeList(List) [function]
     rule toTypeList(.List) => .TypeList
     rule toTypeList(ListItem(K:K) L:List) => tItem(K) ts:: toTypeList(L)

     syntax KResult ::= TypeResult
     syntax TypeItem ::= TypeResult
     syntax TypeItem ::= tItem(K) [strict]
     rule tItem(V:KResult) => trItem(V)

     syntax TypeResult ::= trItem(K)

     //TODO(liyili2): might not need this list in the future.
     syntax TypeList ::= List{TypeItem, "ts::"} [seqstrict]
     syntax List ::= tListToList(TypeList) [function]

     rule tListToList(.TypeList) => .List
     rule tListToList(trItem(K:K) ts:: HL:TypeList)
          => ListItem(K) tListToList(HL)

     syntax List ::=  wrapWithTypeOf(List) [function]
     rule wrapWithTypeOf(ListItem(K:K) L:List)
          => ListItem(retype(typeof(K))) wrapWithTypeOf(L)
     rule wrapWithTypeOf(.List) => .List

     syntax KItem ::= retype(K) [strict]

     // fixme, not handling qualifiers correctly
     rule retype(T:Type) => t(.Set, pointerType(innerType(T)))
          requires isArrayType(T)
          [structural]
     rule retype(T:Type) => t(.Set, pointerType(T))
          requires isFunctionType(T)
          [structural]
     rule retype(T:Type) => T
          requires notBool (isArrayType(T) orBool isFunctionType(T))
          [structural]
     /*@ \fromStandard{\source[n1570]{\para{6.5.15}{4}}}{
     The first operand is evaluated; there is a sequence point between its
     evaluation and the evaluation of the second or third operand (whichever is
     evaluated). The second operand is evaluated only if the first compares
     unequal to 0; the third operand is evaluated only if the first compares
     equal to 0; the result is the value of the second or third operand
     (whichever is evaluated), converted to the type described below.
     }*/
     rule (.K => getTypes(ListItem(E1) ListItem(E2))) ~> _ ? E1:K : E2:K
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.15}{5}}}{
     If both the second and third operands have arithmetic type, the result
     type that would be determined by the usual arithmetic conversions, were
     they applied to those two operands, is the type of the result. If both the
     operands have structure or union type, the result has that type. If both
     operands have void type, the result has void type.
     }*/
     rule (types(trItem(T1:Type) ts:: trItem(T2:Type))
          => convertedType(usualArithmeticConversion(T1, T2)))
               ~> _ ? _ : _
          requires T1 =/=K T2
               andBool hasArithmeticType(T1)
               andBool hasArithmeticType(T2)
          [structural]
     /*
     //(liyili2):add this following rule for checking T1 ==K T2
     rule (types(trItem(T1:Type) ts:: trItem(T2:Type))
          => convertedType(T1))
               ~> _ ? _ : _
          requires T1 ==K T2
               andBool hasArithmeticType(T1)
               andBool hasArithmeticType(T2)
          [structural]
     */

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
     rule (types(trItem(T1:Type) ts:: trItem(T2:Type)) => convertedType(T2))
          ~> _ ? tv(0, T1) : _
          when hasIntegerType(T1) andBool isPointerType(T2)
          [structural]
     rule (types(trItem(T1:Type) ts:: trItem(T2:Type)) => convertedType(T1))
          ~> _? _ : tv(0, T2)
          when hasIntegerType(T2) andBool isPointerType(T1)
          [structural]

     rule (.K => CV("CEC1", "If both of a conditional expression's branches have pointer type, they must be compatible, or one must be a pointer to an object and the"
               +String " other must be a pointer to void.",
               "6.5.15:3"))
          ~> types(trItem(T1:Type) ts:: trItem(T2:Type))
          requires isPointerType(T1) andThenBool isPointerType(T2) andThenBool notBool areCompatible(stripQualifiers(innerType(T1)), stripQualifiers(innerType(T2)))
               andThenBool notBool isVoidType(innerType(T1)) andThenBool notBool isVoidType(innerType(T2))

     rule (types(
               trItem(t(Mods:Set, pointerType(T:Type)))
               ts:: trItem(t(Mods':Set, pointerType(T':Type)))
          ) => convertedType(t(Mods Mods', pointerType(compositeType(T, T')))))
          ~> _? _ : _
          requires areCompatible(stripQualifiers(T), stripQualifiers(T'))
          [structural]

     rule (types(
               trItem(t(Mods1:Set, pointerType(t(Mods1':Set, void))))
               ts:: trItem(t(Mods2:Set, pointerType(t(Mods2':Set, S:SimpleType))))
          ) => convertedType(t(Mods1 Mods2, pointerType(t(Mods1' Mods2', void)))))
          ~> _? _ : _
          requires notBool isFunctionType(t(Mods2', S))
          [structural]
     rule (types(
               trItem (t(Mods1:Set, pointerType(t(Mods1':Set, S:SimpleType))))
               ts:: trItem(t(Mods2:Set, pointerType(t(Mods2':Set, void))))
          ) => convertedType(t(Mods1 Mods2, pointerType(t(Mods1' Mods2', void)))))
          ~> _? _ : _
          requires notBool isFunctionType(t(Mods1', S))
          [structural]

     // this should take care of the void/struct cases
     rule (types(trItem(T:Type) ts:: trItem(T':Type)) => convertedType(T))
          ~> _ ? _ : _
          when notBool isPointerType(T)
               andBool areCompatible(T, T')
          [structural]
     rule convertedType(T:Type) ~> E:K ? E1:K : E2:K
          => IfThenElse(E, Cast(T, E1), Cast(T, E2))
          [structural]

     rule (.K => CV("CEC2", "If one of a conditional expression's branches has void type, the other must also have void type.", "6.5.15:3") ) ~>
          types(trItem(t(_, void)) ts:: trItem(t(_, T:SimpleType)))
          requires T =/=K void
          [structural]
     rule (.K => CV("CEC3", "If one of a conditional expression's branches has void type, the other must also have void type.", "6.5.15:3") ) ~>
          types(trItem(t(_, T:SimpleType)) ts:: trItem(t(_, void)))
          requires T =/=K void
          [structural]
     rule (.K => CV("CEC4", "If one of a conditional expression's branches has struct or union type, the other must have the same type.", "6.5.15:3") ) ~>
          types(trItem(T:Type) ts:: trItem(T':Type))
          requires (T =/=K T')
               andBool (isStructType(T) orBool isUnionType(T))
               andBool (isStructType(T') orBool isUnionType(T'))
          [structural]
endmodule

