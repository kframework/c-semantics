module C-COMMON-EXPR-ASSIGNMENT
     imports BOOL
     imports COMMON-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYNTAX
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
     rule L:Nclv := (R:RValue => cast(utype(L), R, false))
          requires isArithmeticType(type(L)) andBool isArithmeticType(type(R))
               andBool utype(L) =/=Type utype(R)

     rule L:Nclv := (R:RValue => cast(utype(L), R, false))
          requires isPointerType(type(L)) andBool isPointerType(type(R))
               andBool notBool isNullPointerConstant(R)
               andBool (stripQualifiers(innerType(type(L))) =/=Type stripQualifiers(innerType(type(R)))
                         impliesBool (isVoidType(innerType(type(L))) orBool isVoidType(innerType(type(R)))))
               andBool (getQualifiers(innerType(type(R)))
                    <=Quals getQualifiers(innerType(type(L))))
               andBool utype(L) =/=Type utype(R)

     rule L:Nclv := (R:RValue => cast(utype(L), R, false))
          requires isPointerType(type(L)) andBool isNullPointerConstant(R)
               andBool utype(L) =/=Type utype(R)

     rule L:Nclv := (R:RValue => cast(utype(L), R, false))
          requires isBoolType(type(L)) andBool isPointerType(type(R))

     rule Initializer(L:Nclv := (R:RValue => cast(utype(L), R, false)))
          requires isArithmeticType(type(L)) andBool isArithmeticType(type(R))
               andBool utype(L) =/=Type utype(R)

     rule Initializer(L:Nclv := (R:RValue => cast(utype(L), R, false)))
          requires isPointerType(type(L)) andBool isPointerType(type(R))
               andBool notBool isNullPointerConstant(R)
               andBool (stripQualifiers(innerType(type(L))) =/=Type stripQualifiers(innerType(type(R)))
                         impliesBool (isVoidType(innerType(type(L))) orBool isVoidType(innerType(type(R)))))
               andBool (getQualifiers(innerType(type(R)))
                    <=Quals getQualifiers(innerType(type(L))))
               andBool utype(L) =/=Type utype(R)

     rule Initializer(L:Nclv := (R:RValue => cast(utype(L), R, false)))
          requires isPointerType(type(L)) andBool isNullPointerConstant(R)
               andBool utype(L) =/=Type utype(R)

     rule Initializer(L:Nclv := (R:RValue => cast(utype(L), R, false)))
          requires isBoolType(type(L)) andBool isPointerType(type(R))

endmodule
