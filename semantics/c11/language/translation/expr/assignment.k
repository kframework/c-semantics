module C-EXPR-ASSIGNMENT
     imports C-CONFIGURATION
     imports BASIC-K
     imports BOOL
     imports K-EQUAL
     imports SYMLOC-SYNTAX
     imports C-ABSTRACT-SYNTAX
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.6}{3}}}{
     Constant expressions shall not contain assignment, increment, decrement,
     function-call, or comma operators, except when they are contained within
     a subexpression that is not evaluated.
     }*/

     rule <k> (.K => CV("TEAS1", "Incompatible types in assignment or function call arguments."))
               ~> L:Nclv := R:RValue
          ...</k>
          <initializing> IsInit:Bool </initializing>
          requires utype(L) =/=Type utype(R)
               andBool (notBool isConstType(type(L)) orBool IsInit)
               andBool (
                    (isPointerType(type(L)) andBool notBool isPointerType(type(R))
                         andBool notBool isNullPointerConstant(R))
                    orBool (isArithmeticType(type(L)) andBool notBool isBoolType(type(L))
                         andBool notBool isArithmeticType(type(R)))
                    orBool (isStructOrUnionType(type(L))
                         andBool type(L) =/=Type type(R))
                    orBool (isBoolType(type(L)) andBool notBool isPointerType(type(R))
                         andBool notBool isArithmeticType(type(R)))
                    orBool notBool (isPointerType(type(L))
                         orBool isArithmeticType(type(L))
                         orBool isStructOrUnionType(type(L))
                         orBool isBoolType(type(L)))
               ) andBool R =/=K voidVal
               andBool notBool isAutoType(type(L))

     rule <k> (.K => CV("TEAS2", "Incompatible pointer types in assignment or function call arguments."))
               ~> L:Nclv := R:RValue
          ...</k>
          <initializing> IsInit:Bool </initializing>
          requires (isPointerType(type(L)) andBool isPointerType(type(R)))
               andBool notBool isNullPointerConstant(R)
               andBool utype(L) =/=Type utype(R)
               andBool (notBool isConstType(type(L)) orBool IsInit)
               andBool notBool (
                    (stripQualifiers(innerType(type(L))) =/=Type stripQualifiers(innerType(type(R)))
                              impliesBool (isVoidType(innerType(type(L))) orBool isVoidType(innerType(type(R)))))
                    andBool (getQualifiers(innerType(type(R)))
                         <=Quals getQualifiers(innerType(type(L))))
               ) andBool notBool isAutoType(type(L))
     rule (.K => CV("TEAS3", "'lvalue' required as left operand in assignment."))
          ~> tv(_, _) := _:RValue

     rule (.K => UNDEF("TEAS4", "Void value as right operand in assignment."))
          ~> _ := voidVal
     rule <k> (.K => CV("TEAS5", "Non-constant static initializer."))
               ~> nclv(_, _) := te(_, _)
          ...</k>
          <initializing> true </initializing>
     rule <k> (.K => CV("TEAS6", "Trying to write through a const lvalue."))
               ~> L:Nclv := _:RValue
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

     rule <k> nclv(Loc:SymLoc, T::Type) := tv(V:CValue, T'::UType)
               => write(Loc, V, T)
               ~> tv(V, stripConstants(utype(T')))
          ...</k>
          <initializing> true </initializing>
          requires notBool isLinkerLoc(Loc)
               andBool (utype(T) ==Type T')
     rule <k> nclv(Loc:SymLoc, T::Type) := tv(V:CValue, T'::UType)
               => te(lv(Loc, T) := checkUse(tv(V, T')), stripConstants(utype(T')))
          ...</k>
          <initializing> true </initializing>
          requires isLinkerLoc(Loc)
               andBool (utype(T) ==Type T')
     rule <k> ncle(L:K, T::Type) := R:RValue
               => te(L := stripHold(R), stripConstants(utype(R)))
          ...</k>
          <initializing> true </initializing>
          requires utype(T) ==Type utype(R)

     rule <k> nclv(Loc:SymLoc, T::Type) := tv(V:CValue, T'::UType)
               => te(lv(Loc, T) := checkUse(tv(V, T')), stripConstants(utype(T')))
          ...</k>
          <initializing> false </initializing>
          requires notBool isConstType(T)
               andBool (utype(T) ==Type T')
     rule <k> nclv(Loc:SymLoc, T::Type) := te(K:K, T'::UType)
               => te(lv(Loc, T) := K, stripConstants(utype(T')))
          ...</k>
          <initializing> false </initializing>
          requires notBool isConstType(T)
               andBool (utype(T) ==Type T')
     rule <k> ncle(L:K, T::Type) := R:RValue
               => te(L := stripHold(R), stripConstants(utype(R)))
          ...</k>
          <initializing> false </initializing>
          requires notBool isConstType(T)
               andBool (utype(T) ==Type utype(R))

     rule ncle(_, (t(_, _, auto-type) => type(V))) := V:RValue

     rule E1:KResult *= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, utype(E1)) * E2)
     rule E1:KResult /= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, utype(E1)) / E2)
     rule E1:KResult %= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, utype(E1)) % E2)
     rule E1:KResult += E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, utype(E1)) + E2)
     rule E1:KResult -= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, utype(E1)) - E2)
     rule E1:KResult <<= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, utype(E1)) << E2)
     rule E1:KResult >>= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, utype(E1)) >> E2)
     rule E1:KResult &= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, utype(E1)) & E2)
     rule E1:KResult ^= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, utype(E1)) ^ E2)
     rule E1:KResult |= E2:RValue
          => compoundAssign(E1, ncle(LHOLE, type(E1)) := te(RHOLE, utype(E1)) | E2)

     context compoundAssign(_, (HOLE:KItem => reval(HOLE))) [result(RValue)]
     rule <k> compoundAssign(LV:KResult, AExp:RValue)
               => #compoundAssign(LV, LV, AExp)
          ...</k>
          <curr-scope> fileScope </curr-scope>
          requires notBool isNCLHold(LV)
     rule <k> compoundAssign(LV:KResult, AExp:RValue)
               => te(compoundAssign(LV, AExp), utype(LV))
          ...</k>
          <curr-scope> S:Scope </curr-scope>
          requires isNCLHold(LV) orBool S =/=K fileScope

     syntax KItem ::= #compoundAssign(K, K, RValue)
     context #compoundAssign(_, (HOLE:KItem => reval(HOLE)), _) [result(RValue)]
     rule #compoundAssign(LV:KResult, V:RValue, AExp:RValue)
          => fillLHoles(LV, fillRHoles(V, stripHold(AExp)))

endmodule
