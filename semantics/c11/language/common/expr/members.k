module C-COMMON-EXPR-MEMBERS
     imports C-CONFIGURATION
     imports BOOL
     imports INT
     imports LIST
     imports SET
     imports SETTINGS-SYNTAX
     imports C-ALIGNMENT-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-BITS-SYNTAX
     imports C-CHECK-USE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-READING-SYNTAX
     imports COMMON-SORTS
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-EFFECTIVE-SYNTAX
     imports C-TYPING-SYNTAX

     /*@ \fromStandard{\source[n1570]{\para{6.5.2.3}{3}}}{
     A postfix expression followed by the \cinline{.} operator and an
     identifier designates a member of a structure or union object. The value
     is that of the named member, and is an lvalue if the first expression is
     an lvalue. If the first expression has qualified type, the result has the
     so-qualified version of the type of the designated member.
     }*/
     rule nclv(Loc::SymLoc, T:StructOrUnionType) .init F:CId
          => createLv(Loc, T, F, getLastAccessType(Loc), getFixedFieldType(Loc, F, T))
          [structural]
     rule nclv(Loc::SymLoc, T:StructOrUnionType) . F:CId
          => createLv(Loc, T, F, getLastAccessType(Loc), getFixedFieldType(Loc, F, T))
          requires notBool (Atomic() inQuals getQualifiers(T))
          [structural]
     rule (.K => UNDEF("CEM1", "Attempting to access a member in an atomic struct."))
          ~> Lbl:KLabel(_, t(Qs::Quals, _, structType(_))) . _:CId
          requires Atomic() inQuals Qs
               andBool isNCLKLabel(#klabel(Lbl))
          [structural]
     rule (.K => UNDEF("CEM2", "Attempting to access a member in an atomic union."))
          ~> Lbl:KLabel(_, t(Qs::Quals, _, unionType(_))) . _:CId
          requires Atomic() inQuals Qs
               andBool isNCLKLabel(#klabel(Lbl))
          [structural]

     rule nclv(Loc::SymLoc, T:ArrayType) [[ N::Int ]]
          => * (checkUse(tv(Loc, utype(arrayToPtrType(T)))) + tv(N, utype(int)))
          [structural]

     syntax KItem ::= createLv(SymLoc, StructOrUnionType, CId, K, K) [strict(4, 5)]
     rule createLv(NullPointer => loc(obj(0, 1, nativeAddress()), 0), _, _, _, _)
     rule createLv(Loc::SymLoc, T::StructOrUnionType, F::CId, LAT:EffectiveType, t(...) #as T'::Type)
          => lv(updateLastAccessVariant(Loc, F, LAT) +bits findFieldOffset(F, T), addQualifiers(getQualifiers(T), T'))
          requires Loc =/=K NullPointer andBool notBool isNoType(T')
     rule (.K => unknownMemberAccess)
          ~> createLv(_, _, _, _, _:NoType)

     // Same deal as above, only for byte lists.
     rule tv(agg(L:List), T:StructOrUnionUType) . F:CId
          => concretize(addModifiers(getModifiers(T) getModifiers(findFieldTypeU(F, T)), utype(findFieldTypeU(F, T))),
               fillToBytes(extractBitsFromList(dataList(L), findFieldOffsetU(F, T), bitSizeofType(findFieldTypeU(F, T)))))
          requires notBool isNoType(findFieldTypeU(F, T))
          [structural]
     rule (.K => unknownMemberAccess)
          ~> tv(agg(L:List), T:StructOrUnionUType) . F:CId
          requires isNoType(findFieldTypeU(F, T))

     syntax Type ::= findFieldTypeU(CId, StructOrUnionUType) [function]
     rule findFieldTypeU(F::CId, T::StructOrUnionUType) => findFieldType(F, {type(T)}:>StructOrUnionType)

     syntax Int ::= findFieldOffsetU(CId, StructOrUnionUType) [function]
     rule findFieldOffsetU(F::CId, T::StructOrUnionUType) => findFieldOffset(F, {type(T)}:>StructOrUnionType)

     syntax KItem ::= "unknownMemberAccess" [function]
     rule unknownMemberAccess => CV("CEM3", "Attempting to access member but it does not exist.")

endmodule
