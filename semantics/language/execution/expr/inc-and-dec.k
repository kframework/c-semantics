module C-EXPR-INC-AND-DEC
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-MEMORY-READING-SYNTAX

     syntax K ::= postOpRef(K, KLabel)
     syntax K ::= postInc(SymLoc, K, Type) [strict(2)]
     syntax K ::= postDec(SymLoc, K, Type) [strict(2)]

     /*@ \fromStandard{\source[n1570]{\para{6.5.2.4}{2}}}{
     The result of the postfix \cinline{++} operator is the value of the
     operand. As a side effect, the value of the operand object is incremented
     (that is, the value 1 of the appropriate type is added to it). See the
     discussions of additive operators and compound assignment for information
     on constraints, types, and conversions and the effects of operations on
     pointers. The value computation of the result is sequenced before the side
     effect of updating the stored value of the operand. With respect to an
     indeterminately-sequenced function call, the operation of postfix
     \cinline{++} is a single evaluation. Postfix \cinline{++} on an object
     with atomic type is a read-modify-write operation with
     \cinline{memory_order_seq_cst} memory order semantics.
     }*/
     rule nclv(Loc:SymLoc, T:Type) ++ => postInc(Loc, read(Loc, T), T)
          [structural]
     rule postInc(Loc:SymLoc, tv(V:CValue, T:Type), T':Type)
          => lv(Loc, T') := tv(V, T) + tv(1, t(.Set, int))
               ~> discard ~> tv(V, T)
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.2.4}{3}}}{
     The postfix \cinline{--} operator is analogous to the postfix \cinline{++}
     operator, except that the value of the operand is decremented (that is,
     the value 1 of the appropriate type is subtracted from it).
     }*/
     rule nclv(Loc:SymLoc, T:Type) -- => postDec(Loc, read(Loc, T), T)
          [structural]
     rule postDec(Loc:SymLoc, tv(V:CValue, T:Type), T':Type)
          => lv(Loc, T') := tv(V, T) - tv(1, t(.Set, int))
               ~> discard ~> tv(V, T)
          [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.3.1}{2}}}{
     The value of the operand of the prefix \cinline{++} operator is
     incremented. The result is the new value of the operand after
     incrementation. The expression \cinline{++E} is equivalent to
     \cinline{(E+=1)}. See the discussions of additive operators and compound
     assignment for information on constraints, types, side effects, and
     conversions and the effects of operations on pointers.
     }*/
     rule ++ E:K => E += tv(1, t(.Set, int)) [structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.3.1}{3}}}{
     The prefix \cinline{--} operator is analogous to the prefix \cinline{++}
     operator, except that the value of the operand is decremented.
     }*/
     rule -- E:K => E -= tv(1, t(.Set, int)) [structural]

endmodule
