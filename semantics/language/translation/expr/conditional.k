module C-EXPR-CONDITIONAL
     imports C-EXPR-LOGICAL-SYNTAX

     imports C-COMMON-PROMOTION-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX

     syntax KItem ::= getTypes(K, K) [strict]
     syntax KItem ::= types(Type, Type)
     syntax KItem ::= convertedType(K) [strict]

     rule getTypes(V1:KResult, V2:KResult)
          => types(retype(type(V1)), retype(type(V2)))

     // fixme, not handling qualifiers correctly
     syntax KItem ::= retype(Type) [function]
     rule retype(T:ArrayType) => t(.Set, pointerType(innerType(T)))
     rule retype(T:FunctionType) => t(.Set, pointerType(T))
     rule retype(T:Type) => T
          requires notBool isArrayOrFunctionType(T)

     /*@ \fromStandard{\source[n1570]{\para{6.5.15}{4}}}{
     The first operand is evaluated; there is a sequence point between its
     evaluation and the evaluation of the second or third operand (whichever is
     evaluated). The second operand is evaluated only if the first compares
     unequal to 0; the third operand is evaluated only if the first compares
     equal to 0; the result is the value of the second or third operand
     (whichever is evaluated), converted to the type described below.
     }*/
     rule (.K => getTypes(E1, E2)) ~> _ ? E1:K : E2:K

     /*@ \fromStandard{\source[n1570]{\para{6.5.15}{5}}}{
     If both the second and third operands have arithmetic type, the result
     type that would be determined by the usual arithmetic conversions, were
     they applied to those two operands, is the type of the result. If both the
     operands have structure or union type, the result has that type. If both
     operands have void type, the result has void type.
     }*/
     rule (types(T1:ArithmeticType, T2:ArithmeticType)
          => convertedType(usualArithmeticConversion(T1, T2)))
               ~> _ ? _ : _
          requires T1 =/=K T2

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
     rule (types(T1:IntegerType, T2:PointerType) => convertedType(T2))
          ~> _ ? tv(0, T1) : _
     rule (types(T1:PointerType, T2:IntegerType) => convertedType(T1))
          ~> _? _ : tv(0, T2)

     // TODO(chathhorn): variably modified types need to be evaluated at
     // execution and checked for compatibility at that point.
     rule (.K => CV("CEC1", "If both of a conditional expression's branches have pointer type, they must be compatible, or one must be a pointer to an object and the"
               +String " other must be a pointer to void.",
               "6.5.15:3"))
          ~> types(T1:PointerType, T2:PointerType)
          requires notBool areCompatible(stripQualifiers(innerType(T1)), stripQualifiers(innerType(T2)))
               andBool notBool isVoidType(innerType(T1))
               andBool notBool isVoidType(innerType(T2))

     rule (types(
               t(Mods:Set, pointerType(T:Type)),
               t(Mods':Set, pointerType(T':Type))
          ) => convertedType(t(Mods Mods', pointerType(compositeType(T, T')))))
          ~> _? _ : _
          requires areCompatible(stripQualifiers(T), stripQualifiers(T'))

     rule (types(
               t(Mods1:Set, pointerType(t(Mods1':Set, void))),
               t(Mods2:Set, pointerType(t(Mods2':Set, S:SimpleType)))
          ) => convertedType(t(Mods1 Mods2, pointerType(t(Mods1' Mods2', void)))))
          ~> _? _ : _
          requires notBool isFunctionType(t(Mods2', S))
     rule (types(
               t(Mods1:Set, pointerType(t(Mods1':Set, S:SimpleType))),
               t(Mods2:Set, pointerType(t(Mods2':Set, void)))
          ) => convertedType(t(Mods1 Mods2, pointerType(t(Mods1' Mods2', void)))))
          ~> _? _ : _
          requires notBool isFunctionType(t(Mods1', S))

     // this should take care of the void/struct cases
     rule (types(T:Type, T':Type) => convertedType(T))
          ~> _ ? _ : _
          when notBool isPointerType(T)
               andBool areCompatible(T, T')
     rule convertedType(T:Type) ~> E:K ? E1:K : E2:K
          => evalConditional(simplifyTruth(E), Cast(T, E1), Cast(T, E2))

     rule (.K => CV("CEC2", "If one of a conditional expression's branches has void type, the other must also have void type.", "6.5.15:3") )
          ~> types(t(_, void), t(_, T:SimpleType))
          requires T =/=K void
     rule (.K => CV("CEC3", "If one of a conditional expression's branches has void type, the other must also have void type.", "6.5.15:3") )
          ~> types(t(_, T:SimpleType), t(_, void))
          requires T =/=K void
     rule (.K => CV("CEC4", "If one of a conditional expression's branches has struct or union type, the other must have the same type.", "6.5.15:3") )
          ~> types(T:StructOrUnionType, T':StructOrUnionType)
          requires T =/=Type T'

     syntax KItem ::= evalConditional(K, K, K)
     context evalConditional(HOLE => reval(HOLE), _, _) [result(RValue)]
     context evalConditional(_, HOLE => reval(HOLE), _) [result(RValue)]
     context evalConditional(_, _, HOLE => reval(HOLE)) [result(RValue)]

     rule evalConditional(C:RValue, E1:RValue, E2:RValue)
          => te(stripHold(C) ? stripHold(E1) : stripHold(E2), stripConstants(type(E1)))
          requires isHold(C)
     rule evalConditional(tv(1, t(_, int)), E:RValue, _) => E
     rule evalConditional(tv(0, t(_, int)), _, E:RValue) => E

endmodule

