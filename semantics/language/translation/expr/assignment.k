module C-EXPR-ASSIGNMENT
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SETTINGS-SYNTAX

     imports C-CONFIGURATION

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
     rule L:KResult := (R:RValue => cast(type(L), R))
          requires (isArithmeticType(type(L)) andBool isArithmeticType(type(R)))
               andBool (getQualifiers(type(R)) ==K .Set)
               andBool (type(L) =/=Type type(R))

     rule L:KResult := (R:RValue => cast(type(L), R))
          requires isStructOrUnionType(type(L))
               andBool areCompatible(stripQualifiers(type(L)), type(R))
               andBool (type(L) =/=Type type(R))

     rule L:KResult := (R:RValue => cast(type(L), R))
          requires isPointerType(type(L)) andBool isPointerType(type(R))
               andBool areCompatible(
                    stripQualifiers(innerType(type(L))),
                    stripQualifiers(innerType(type(R))))
               andBool getQualifiers(innerType(type(R)))
                    <=Set getQualifiers(innerType(type(L)))
               andBool (type(L) =/=Type type(R))

     rule L:KResult := (R:RValue => cast(type(L), R))
          requires isPointerType(type(L)) andBool isPointerType(type(R))
               andBool (isVoidType(innerType(type(L)))
                    orBool isVoidType(innerType(type(R))))
               andBool (getQualifiers(innerType(type(R)))
                    <=Set getQualifiers(innerType(type(L))))
               andBool (type(L) =/=Type type(R))

     rule L:KResult := (R:RValue => cast(type(L), R))
          requires isPointerType(type(L))
               andBool isNullPointerConstant(R)
               andBool (type(L) =/=Type type(R))
          [structural] //TODO(dwightguth): this tag is needed for confluence with null pointer constants. Might want to find a better way.

     rule L:KResult := (R:RValue => cast(type(L), R))
          requires isBoolType(type(L)) andBool isPointerType(type(R))

     /*@ \fromStandard{\source[n1570]{\para{6.6}{3}}}{
     Constant expressions shall not contain assignment, increment, decrement,
     function-call, or comma operators, except when they are contained within
     a subexpression that is not evaluated.
     }*/

     rule nclv(_, T:Type => stripConstants(T)) := _:RValue
          requires fromConstantExpr(T)
     rule _:KResult := tv(_:CValue, T:Type => stripConstants(T))
          requires fromConstantExpr(T)
     rule _:KResult := te(_, T:Type => stripConstants(T))
          requires fromConstantExpr(T)

     rule (.K => CV("TEAS1", "incompatible types in assignment or function call arguments.", "6.5.16.1:1"))
          ~> L:KResult := R:RValue
          requires type(L) =/=Type type(R)
               andBool (
                    (isPointerType(type(L)) andBool notBool isPointerType(type(R))
                         andBool notBool isNullPointerConstant(R))
                    orBool (isArithmeticType(type(L)) andBool notBool isBoolType(type(L)))
                         andBool notBool isArithmeticType(type(R))
                    orBool isStructOrUnionType(type(L))
                         andBool notBool areCompatible(stripQualifiers(type(L)), type(R))
                    orBool isBoolType(type(L)) andBool notBool isPointerType(type(R)) andBool notBool isArithmeticType(type(R))
                    orBool notBool (isPointerType(type(L))
                         orBool isArithmeticType(type(L))
                         orBool isStructOrUnionType(type(L))
                         orBool isBoolType(type(L)))
               ) andBool notBool R ==K voidVal
          [structural] //TODO(dwightguth): this tag is needed for confluence with null pointer constants. Might want to find a better way.

     rule (.K => CV("TEAS2", "incompatible pointer types in assignment or function call arguments.", "6.5.16.1:1"))
          ~> L:KResult := R:RValue
          requires (isPointerType(type(L)) andBool isPointerType(type(R)))
               andBool notBool isVoidType(innerType(type(L)))
               andBool notBool isVoidType(innerType(type(R)))
               andBool (
                    notBool areCompatible(
                         stripQualifiers(innerType(type(L))),
                         stripQualifiers(innerType(type(R))))
                    orBool notBool (getQualifiers(innerType(type(R)))
                         <=Set getQualifiers(innerType(type(L))))
               )
     rule (.K => CV("TEAS3", "lvalue required as left operand in assignment.", "6.5.16:2"))
          ~> tv(_, _) := _:RValue

     rule (.K => UNDEF("TEAS4", "void value as right operand in assignment", "6.3.2.2:1, J.2:1 item 23"))
          ~> _ := voidVal
     rule _:ErrorExit ~> _ := voidVal => voidVal //eat the invalid write
          requires isErrorRecovery
     rule <k> (.K => CV("TEAS5", "Non-constant static initializer.", "6.7.9:4"))
               ~> nclv(_, _) := te(_, _)
          ...</k>
          <initializing> true </initializing>
     rule <k> (.K => CV("TEAS6", "Trying to write through a const lvalue.", "6.5.16.1:1"))
               ~> L:KResult := _:RValue
          ...</k>
          <initializing> false </initializing>
          requires isConstType(type(L))

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
     A compound assignment of the form \cinline{E1 op= E2} is equivalent to the
     simple assignment expression \cinline{E1 = E1 op (E2)}, except that the
     lvalue \cinline{E1} is evaluated only once, and with respect to an
     indeterminately-sequenced function call, the operation of a compound
     assignment is a single evaluation. If \cinline{E1} has an atomic type,
     compound assignment is a read-modify-write operation with
     \cinline{memory_order_seq_cst} memory order semantics.
     }*/

     rule <k> nclv(Loc:SymLoc, T:Type) := tv(V:CValue, T':Type)
               => write(Loc, V, T)
               ~> tv(V, T)
          ...</k>
          <initializing> true </initializing>
          requires notBool fromConstantExpr(T)
               andBool notBool fromConstantExpr(T')
               andBool notBool isLinkerLoc(Loc)
               andBool (T ==Type T')
     rule <k> nclv(Loc:SymLoc, T:Type) := tv(V:CValue, T':Type)
               => te(nclv(Loc, T) := tv(V, T'), T)
          ...</k>
          <initializing> true </initializing>
          requires notBool fromConstantExpr(T)
               andBool notBool fromConstantExpr(T')
               andBool isLinkerLoc(Loc)
               andBool (T ==Type T')
     rule <k> ncle(L:K, T:Type) := R:RValue => te(L := stripHold(R), T) ...</k>
          <initializing> true </initializing>
          requires notBool fromConstantExpr(T)
               andBool notBool fromConstantExpr(type(R))
               andBool (T ==Type type(R))

     rule <k> nclv(Loc:SymLoc, T:Type) := tv(V:CValue, T':Type)
               => te(nclv(Loc, T) := tv(V, T'), T)
          ...</k>
          <initializing> false </initializing>
          requires notBool fromConstantExpr(T)
               andBool notBool fromConstantExpr(T')
               andBool notBool isConstType(T)
               andBool (T ==Type T')
     rule <k> nclv(Loc:SymLoc, T:Type) := te(K:K, T':Type)
               => te(nclv(Loc, T) := K, T)
          ...</k>
          <initializing> false </initializing>
          requires notBool fromConstantExpr(T)
               andBool notBool fromConstantExpr(T')
               andBool notBool isConstType(T)
               andBool (T ==Type T')
     rule <k> ncle(L:K, T:Type) := R:RValue => te(L := stripHold(R), T) ...</k>
          <initializing> false </initializing>
          requires notBool fromConstantExpr(T)
               andBool notBool fromConstantExpr(type(R))
               andBool notBool isConstType(T)
               andBool (T ==Type type(R))

     rule E1:KResult *= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, type(E1)) * E2)
     rule E1:KResult /= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, type(E1)) / E2)
     rule E1:KResult %= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, type(E1)) % E2)
     rule E1:KResult += E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, type(E1)) + E2)
     rule E1:KResult -= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, type(E1)) - E2)
     rule E1:KResult <<= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, type(E1)) << E2)
     rule E1:KResult >>= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, type(E1)) >> E2)
     rule E1:KResult &= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, type(E1)) & E2)
     rule E1:KResult ^= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, type(E1)) ^ E2)
     rule E1:KResult |= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, type(E1)) | E2)

     context compoundAssign(_, (HOLE => reval(HOLE))) [result(RValue)]
     rule <k> compoundAssign(LV:KResult, AExp:RValue)
               => #compoundAssign(LV, LV, AExp)
          ...</k>
          <curr-scope> fileScope </curr-scope>
          requires notBool isNCLHold(LV)
     rule <k> compoundAssign(LV:KResult, AExp:RValue)
               => te(compoundAssign(LV, AExp), type(LV))
          ...</k>
          <curr-scope> S:Scope </curr-scope>
          requires isNCLHold(LV) orBool S =/=K fileScope

     syntax KItem ::= #compoundAssign(K, K, RValue)
     context #compoundAssign(_, (HOLE => reval(HOLE)), _) [result(RValue)]
     rule #compoundAssign(LV:KResult, V:RValue, AExp:RValue)
          => fillLHoles(LV, fillRHoles(V, stripHold(AExp)))

endmodule
