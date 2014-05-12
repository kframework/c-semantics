module C-COMMON-EXPR-MEMBERS
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-BITS-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.5.2.3}{3}}}{
     A postfix expression followed by the \cinline{.} operator and an
     identifier designates a member of a structure or union object. The value
     is that of the named member, and is an lvalue if the first expression is
     an lvalue. \broken{If the first expression has qualified type, the result
     has the so-qualified version of the type of the designated member.}
     }*/
     rule lval(Loc:SymLoc, t(Se:Set,
               structType(S:Id, _, Fields:FieldInfo))) . F:Id
          => lookupField(F, Loc, Se, S, Fields, Fields)
          [structural]
     rule lval(Loc:SymLoc, t(Mods:Set,
               unionType(S:Id, _, Fields:FieldInfo))) . F:Id
          => lookupField(F, Loc,
               stripUnionMarker(Mods) SetItem(fromUnion(Loc, F, Fields)),
               S, Fields, Fields)
          [structural]

     // The last two parameters are for convenience and should be the same.
     syntax K ::= lookupField(Id, SymLoc, Set, Id, FieldInfo, FieldInfo)
          [function]

     rule lookupField(F:Id, Loc:SymLoc, Mods:Set, S:Id, Fields:FieldInfo,
          fieldInfo(_,
               F |-> t(Mods':Set, T':SimpleType) _,
               F |-> Offset:Int _))
          // Complete recursive struct/union definitions.
          => lv(Loc +bits Offset, completeTag(S, Fields, t(Mods Mods', T')))

     // Same deal as above, only for byte lists.
     rule tv(agg(L:List), t(Mods:Set,
               structType(S:Id, _, Fields:FieldInfo))) . F:Id
          => extractField(F, L, Mods, S, Fields, Fields)
          [structural]
     rule tv(agg(L:List), t(Mods:Set,
               unionType(S:Id, _, Fields:FieldInfo))) . F:Id
          => extractField(F, L, Mods, S, Fields, Fields)
          [structural]

     syntax K ::= extractField(Id, List, Set, Id, FieldInfo, FieldInfo)
          [function]
     
     rule extractField(F:Id, L:List, Mods:Set, S:Id, Fields:FieldInfo,
          fieldInfo(_,
               F |-> t(Mods':Set, T':SimpleType) _,
               F |-> Offset:Int _))
          => concretize(completeTag(S, Fields, t(Mods Mods', T')),
               fillToBytes(extractBitsFromList(dataList(L), Offset,
                    bitSizeofType(completeTag(S, Fields, t(Mods Mods', T'))))))
          
     /*@ \fromStandard{\source[n1570]{\para{6.5.2.3}{4}}}{
     A postfix expression followed by the \cinline{->} operator and an
     identifier designates a member of a structure or union object. The value
     is that of the named member of the object to which the first expression
     points, and is an lvalue. \broken{If the first expression is a pointer to
     a qualified type, the result has the so-qualified version of the type of
     the designated member.}
     }*/
     rule K:K -> F:Id => (* K) . F [macro, structural]

     /*@ \fromStandard{\source[n1570]{\para{6.5.2.1}{2--3}}}{
     A postfix expression followed by an expression in square brackets
     \cinline{[]} is a subscripted designation of an element of an array
     object. The definition of the subscript operator \cinline{[]} is that
     \cinline{E1[E2]} is identical to \cinline{(*((E1)+(E2)))}. Because of the
     conversion rules that apply to the binary \cinline{+} operator, if
     \cinline{E1} is an array object (equivalently, a pointer to the initial
     element of an array object) and \cinline{E2} is an integer,
     \cinline{E1[E2]} designates the \cinline{E2}-th element of \cinline{E1}
     (counting from zero).

     Successive subscript operators designate an element of a multidimensional
     array object. If \cinline{E} is an $n$-dimensional array ($n \ge 2$) with
     dimensions $i \times j \times\cdots\times k$, then \cinline{E} (used as
     other than an lvalue) is converted to a pointer to an ($n -
     1$)-dimensional array with dimensions $j \times\cdots\times k$. If the
     unary \cinline{*} operator is applied to this pointer explicitly, or
     implicitly as a result of subscripting, the result is the referenced ($n -
     1$)-dimensional array, which itself is converted into a pointer if used as
     other than an lvalue. It follows from this that arrays are stored in
     row-major order (last subscript varies fastest).
     }*/
     rule E1:K[E2:K] => *(E1 + E2) 
          [structural]

endmodule
