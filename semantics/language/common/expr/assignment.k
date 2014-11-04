module C-COMMON-EXPR-ASSIGNMENT
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.5.16}{3}}}{
     An assignment operator stores a value in the object designated by the left
     operand. \broken{An assignment expression has the value of the left
     operand after the assignment}, but is not an lvalue. The type of an
     assignment expression is the type the left operand would have after lvalue
     conversion. The side effect of updating the stored value of the left
     operand is sequenced after the value computations of the left and right
     operands. The evaluations of the operands are unsequenced.
     }*/

     /*@ \fromStandard{\source[n1570]{\para{6.5.16.1}{1}}{
     One of the following shall hold:112)

     ---the left operand has atomic, qualified, or unqualified arithmetic type,
     and the right has arithmetic type;

     ---the left operand has an atomic, qualified, or unqualified version of a
     structure or union type compatible with the type of the right;

     ---the left operand has atomic, qualified, or unqualified pointer type,
     and (considering the type the left operand would have after lvalue
     conversion) both operands are pointers to qualified or unqualified
     versions of compatible types, and the type pointed to by the left has all
     the qualifiers of the type pointed to by the right;

     ---the left operand has atomic, qualified, or unqualified pointer type,
     and (considering the type the left operand would have after lvalue
     conversion) one operand is a pointer to an object type, and the other is a
     pointer to a qualified or unqualified version of void, and the type
     pointed to by the left has all the qualifiers of the type pointed to by
     the right;

     ---the left operand is an atomic, qualified, or unqualified pointer, and
     the right is a null pointer constant; or

     ---the left operand has type atomic, qualified, or unqualified _Bool, and
     the right is a pointer.

     }*/
     rule nclv(_, T':Type) := (tv(V:CValue, T:Type) => cast(T', tv(V, T)))
          when hasArithmeticType(T') andBool hasArithmeticType(T)
               andBool (getQualifiers(T) ==Set .Set)
               andBool (T' =/=Type T)
          [structural]

     rule nclv(_, T':Type) := (tv(V:CValue, T:Type) => cast(T', tv(V, T)))
          when (isStructType(T') orBool isUnionType(T'))
               andBool areCompatible(stripQualifiers(T'), T)
               andBool (T' =/=Type T)
          [structural]

     rule nclv(_, t(Mods':Set, pointerType(T':Type)))
               := (tv(V:CValue, t(Mods:Set, pointerType(T:Type)))
               => cast(t(Mods', pointerType(T')), tv(V, t(Mods, pointerType(T)))))
          when areCompatible(
                    stripQualifiers(stripAlignas(T')),
                    stripQualifiers(stripAlignas(T)))
               andBool getQualifiers(T) <=Set getQualifiers(T')
               andBool t(Mods', pointerType(T')) =/=Type t(Mods, pointerType(T))
               andBool getAlignas(T') <=Int getAlignas(T)
          [structural]

     rule nclv(_, t(Mods':Set, pointerType(T':Type)))
               := (tv(V:CValue, t(Mods:Set, pointerType(T:Type)))
               => cast(t(Mods', pointerType(T')), tv(V, t(Mods, pointerType(T)))))
          when (isVoidType(T') orBool isVoidType(T))
               andBool (getQualifiers(T) <=Set getQualifiers(T'))
               andBool (t(Mods', pointerType(T')) =/=Type t(Mods, pointerType(T)))
          [structural]

     rule nclv(_, T':Type) := (V:RValue => cast(T', V))
          when isPointerType(T')
               andBool isNullPointerConstant(V)
               andBool (T' =/=Type type(V))
          [structural]

     rule nclv(_, T':Type) := (tv(V:CValue, T:Type) => cast(T', tv(V, T)))
          when isBoolType(T') andBool isPointerType(T)
          [structural]

     rule (. => ERROR("CEA1", "incompatible types in assignment or function call arguments."))
          ~> nclv(_, T':Type) := tv(V:CValue, T:Type)
          when (isPointerType(T') andBool notBool isPointerType(T)
                    andBool notBool isNullPointerConstant(tv(V, T)))
               orBool (notBool isPointerType(T') andBool isPointerType(T))
     rule (. => ERROR("CEA2", "incompatible pointer types in assignment or function call arguments."))
          ~> nclv(_, T':Type) := tv(_, T:Type)
          // TODO(chathhorn): split these out for better errors.
          when isPointerType(T') andBool isPointerType(T)
               andBool notBool isVoidType(innerType(T'))
               andBool notBool isVoidType(innerType(T))
               andBool (
                    notBool areCompatible(
                         stripQualifiers(stripAlignas(innerType(T'))),
                         stripQualifiers(stripAlignas(innerType(T))))
                    orBool notBool (getQualifiers(innerType(T)) <=Set getQualifiers(innerType(T')))
                    orBool getAlignas(innerType(T')) >Int getAlignas(innerType(T))
               )
     rule (. => CV("CEA3", "lvalue required as left operand in assignment.", ""))
          ~> tv(_, _) := tv(_, _)

     /*@ \fromStandard{\source[n1570]{\para{6.5.16.1}{2}}}{
     In simple assignment (\cinline{=}), the value of the right operand is
     converted to the type of the assignment expression and replaces the value
     stored in the object designated by the left operand.
     }*/

     /*@ \fromStandard{\source[n1570]{\para{6.5.16.1}{3}}}{
     \broken{If the value being stored in an object is read from another object
     that overlaps in any way the storage of the first object, then the overlap
     shall be exact and the two objects shall have qualified or unqualified
     versions of a compatible type; otherwise, the behavior is undefined.}
     }*/

     // *** TODO(chathhorn) *** Does this only happen with unions? But if so,
     // why doesn't the standard just say that?

     /*@ \fromStandard{\source[n1570]{\para{6.5.16.2}{3}}}{
     Acompound assignment of the form \cinline{E1 op= E2} is equivalent to the
     simple assignment expression \cinline{E1 = E1 op (E2)}, except that the
     lvalue \cinline{E1} is evaluated only once, and with respect to an
     indeterminately-sequenced function call, the operation of a compound
     assignment is a single evaluation. If \cinline{E1} has an atomic type,
     compound assignment is a read-modify-write operation with
     \cinline{memory_order_seq_cst} memory order semantics.
     }*/

     rule E1:KResult *= E2:KResult => E1 := toRVal(E1) * E2
          [structural]
     rule E1:KResult /= E2:KResult => E1 := toRVal(E1) / E2
          [structural]
     rule E1:KResult %= E2:KResult => E1 := toRVal(E1) % E2
          [structural]
     rule E1:KResult += E2:KResult => E1 := toRVal(E1) + E2
          [structural]
     rule E1:KResult -= E2:KResult => E1 := toRVal(E1) - E2
          [structural]
     rule E1:KResult <<= E2:KResult => E1 := toRVal(E1) << E2
          [structural]
     rule E1:KResult >>= E2:KResult => E1 := toRVal(E1) >> E2
          [structural]
     rule E1:KResult &= E2:KResult => E1 := toRVal(E1) & E2
          [structural]
     rule E1:KResult ^= E2:KResult => E1 := toRVal(E1) ^ E2
          [structural]
     rule E1:KResult |= E2:KResult => E1 := toRVal(E1) | E2
          [structural]

endmodule
