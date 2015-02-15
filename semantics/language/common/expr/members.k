module C-COMMON-EXPR-MEMBERS
     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.5.2.3}{3}}}{
     A postfix expression followed by the \cinline{.} operator and an
     identifier designates a member of a structure or union object. The value
     is that of the named member, and is an lvalue if the first expression is
     an lvalue. If the first expression has qualified type, the result has the
     so-qualified version of the type of the designated member.
     }*/
     rule <k> nclv(Loc:SymLoc, t(Mods:Set,
                    structType(S:CId, Fields:FieldInfo))) . F:CId
               => lookupField(F, Loc, Mods, S, Fields, Fields)
          ...</k>
          <initializing> I:Int </initializing>
          requires notBool (Atomic in Mods)
               orBool I >Int 0
          [structural]
     rule <k> nclv(Loc:SymLoc, t(Mods:Set,
                    unionType(S:CId, Fields:FieldInfo))) . F:CId
               => lookupField(F, addProv(fromUnion(Loc, F, Fields), Loc),
                    Mods, S, Fields, Fields)
          ...</k>
          <initializing> I:Int </initializing>
          requires notBool (Atomic in Mods)
               orBool I >Int 0
          [structural]
     rule <k> (.K => UNDEF("CEM1",
               "attempting to access a member in an atomic struct.",
               "6.5.2.3:5"))
               ~> nclv(_, t(Mods:Set, structType(_, _))) . _:CId
          ...</k>
          <initializing> 0 </initializing>
          requires Atomic in Mods
          [structural]
     rule <k> (.K => UNDEF("CEM2",
               "attempting to access a member in an atomic union.",
               "6.5.2.3:5"))
               ~> nclv(_, t(Mods:Set, unionType(_, _))) . _:CId
          ...</k>
          <initializing> 0 </initializing>
          requires Atomic in Mods
          [structural]

     // The last two parameters are for convenience and should be the same.
     // TODO(chathhorn): anonymous structs/unions.
     syntax KItem ::= lookupField(CId, SymLoc, Set, CId, FieldInfo, FieldInfo)
          [function]
     syntax KItem ::= lookupFieldHold(CId, SymLoc, Set, CId, FieldInfo, FieldInfo)

     rule lookupField(F:CId, Loc:SymLoc, Mods:Set, S:CId, Fields:FieldInfo,
          fieldInfo(_, _,
               F |-> T:Type _,
               F |-> Offset:Int _))
          // Complete recursive struct/union definitions.
          => lv(Loc +bytes Offset,
               completeTag(S, Fields, addQualifiers(Mods, T)))
     rule lookupField(F:CId, Loc:SymLoc, Mods:Set, S:CId, Fields:FieldInfo, 
          fieldInfo(Decls:List, Size:Int, Types:Map, Offsets:Map))
          => lookupFieldHold(F, Loc, Mods, S, Fields, fieldInfo(Decls, Size, Types, Offsets))
          requires notBool (F in keys(Types) andBool F in keys(Offsets))

     rule (.K => CV("CEM3", "attempting to access member but it does not exist", "6.5.2.3:1"))
          ~> lookupFieldHold(F:CId, _, _, _, _, fieldInfo(_, _, Types:Map, Offsets:Map))
          requires notBool (F in keys(Types) andBool F in keys(Offsets))

     // Same deal as above, only for byte lists.
     rule tv(agg(L:List), t(Mods:Set,
               structType(S:CId, Fields:FieldInfo))) . F:CId
          => extractField(F, L, Mods, S, Fields, Fields)
          [structural]
     rule tv(agg(L:List), t(Mods:Set,
               unionType(S:CId, Fields:FieldInfo))) . F:CId
          => extractField(F, L, Mods, S, Fields, Fields)
          [structural]

     syntax KItem ::= extractField(CId, List, Set, CId, FieldInfo, FieldInfo)
          [function]

     rule extractField(F:CId, L:List, Mods:Set, S:CId, Fields:FieldInfo,
          fieldInfo(_, _,
               F |-> t(Mods':Set, T':SimpleType) _,
               F |-> Offset:Int _))
          => concretize(completeTag(S, Fields, t(Mods Mods', T')),
               fillToBytes(extractBitsFromList(dataList(L),
                    Offset *Int cfg:bitsPerByte,
                    bitSizeofType(completeTag(S, Fields, t(Mods Mods', T'))))))

     /*@ \fromStandard{\source[n1570]{\para{6.5.2.3}{4}}}{
     A postfix expression followed by the \cinline{->} operator and an
     identifier designates a member of a structure or union object. The value
     is that of the named member of the object to which the first expression
     points, and is an lvalue. \broken{If the first expression is a pointer to
     a qualified type, the result has the so-qualified version of the type of
     the designated member.}
     }*/
     rule K:K -> F:CId => (* K) . F [macro, structural]

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
          [macro, structural]

endmodule
