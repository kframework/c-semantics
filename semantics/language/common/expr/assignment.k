module C-COMMON-EXPR-ASSIGNMENT
     imports C-COMMON-EXPR-EVAL-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-MEMORY-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.5.16}{3}}}{
     An assignment operator stores a value in the object designated by the left
     operand. \broken{An assignment expression has the value of the left
     operand after the assignment}, but is not an lvalue. The type of an
     assignment expression is the type the left operand would have after lvalue
     conversion. The side effect of updating the stored value of the left
     operand is sequenced after the value computations of the left and right
     operands. The evaluations of the operands are unsequenced.
     }*/
          
     /*@ \fromStandard{\source[n1570]{\para{6.5.16.1}{2}}}{
     Insimple assignment (\cinline{=}), the value of the right operand is
     converted to the type of the assignment expression and replaces the value
     stored in the object designated by the left operand.
     }*/

     // The actual rule for assignment that results in a write is in the
     // translation/execution semantics.

     rule [convert-for-assignment]:
          lval(_, T:Type) := (tv(V:KList, T':Type) => cast(T, tv(V, T')))
          when T =/=K T'
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.16.1}{3}}}{
     \broken{If the value being stored in an object is read from another object
     that overlaps in any way the storage of the first object, then the overlap
     shall be exact and the two objects shall have qualified or unqualified
     versions of a compatible type; otherwise, the behavior is undefined.}
     }*/
     
     /*@ \fromStandard{\source[n1570]{\para{6.5.16.2}{3}}}{
     Acompound assignment of the form \cinline{E1 op= E2} is equivalent to the
     simple assignment expression \cinline{E1 = E1 op (E2)}, except that the
     lvalue \cinline{E1} is evaluated only once, and with respect to an
     indeterminately-sequenced function call, the operation of a compound
     assignment is a single evaluation. If \cinline{E1} has an atomic type,
     compound assignment is a read-modify-write operation with
     \cinline{memory_order_seq_cst} memory order semantics.
     }*/
     syntax K ::= compoundAssignment(KLabel, K, K) [strict(2,3)]
     // these should not be nd, in order to keep the operations together
     //context compoundAssignment(_, (HOLE => peval(HOLE)), _)
     //context compoundAssignment(_, _, (HOLE => reval(HOLE)))
          
     rule [compoundAssignment-mult]:
          E1:K *= E2:K => compoundAssignment('_*_, E1, E2)
          [structural]
     rule [compoundAssignment-div]:
          E1:K /= E2:K => compoundAssignment('_/_, E1, E2)
          [structural]
     rule [compoundAssignment-modulo]:
          E1:K %= E2:K => compoundAssignment('_%_, E1, E2)
          [structural]
     rule [compoundAssignment-plus]:
          E1:K += E2:K => compoundAssignment('_+_, E1, E2)
          [structural]
     rule [compoundAssignment-minus]:
          E1:K -= E2:K => compoundAssignment('_-_, E1, E2)
          [structural]
     rule [compoundAssignment-left-shift]:
          E1:K <<= E2:K => compoundAssignment('_<<_, E1, E2)
          [structural]
     rule [compoundAssignment-right-shift]:
          E1:K >>= E2:K => compoundAssignment('_>>_, E1, E2)
          [structural]
     rule [compoundAssignment-bitwise-and]:
          E1:K &= E2:K => compoundAssignment('_&_, E1, E2)
          [structural]
     rule [compoundAssignment-bitwise-xor]:
          E1:K ^= E2:K => compoundAssignment('_^_, E1, E2)
          [structural]
     rule [compoundAssignment-bitwise-or]:
          E1:K |= E2:K => compoundAssignment('_|_, E1, E2)
          [structural]

     rule compoundAssignment(L:KLabel, V:Value, V':Value)
          => pkludge(V) := L(rkludge(V),, rkludge(V'))
          [structural]
endmodule

