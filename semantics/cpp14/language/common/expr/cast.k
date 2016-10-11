module CPP-EXPR-CAST-SYNTAX
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS

     syntax Val ::= convertConst(CPPType, Val) [function]
     syntax Expr ::= convertStatic(CPPType, Val, Trace) [function]
                   | #convertStatic(CPPType, Expr) [strict(2)]

endmodule

module CPP-EXPR-CAST
     imports CPP-EXPR-CAST-SYNTAX
     imports BOOL
     imports INT
     imports BITS-SYNTAX
     imports COMMON-SYNTAX
     imports CPP-ALIGNMENT-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ERROR-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule convertConst(T2::CPPType, prv(V::CPPValue, Tr::Trace, T1::CPPType))
          => prv(V, Tr, T2)
          requires isSimilar(T2, T1)
     rule convertConst(t(_, _, lvRefType(T2::CPPType)), lv(Loc::SymLoc, Tr::Trace, T1::CPPType))
          => lv(Loc, Tr, T2)
          requires isObjectType(T1) andBool isObjectType(T2)
               andBool isSimilar(type(pointerType(T2)), 
                                 type(pointerType(T1)))

     rule convertConst(t(_, _, rvRefType(T2::CPPType)), lv(Loc::SymLoc, Tr::Trace, T1::CPPType))
          => xv(Loc, Tr, T2)
          requires isObjectType(T1) andBool isObjectType(T2)
               andBool isSimilar(type(pointerType(T2)), 
                                 type(pointerType(T1)))
     rule convertConst(t(_, _, rvRefType(T2::CPPType)), xv(Loc::SymLoc, Tr::Trace, T1::CPPType))
          => xv(Loc, Tr, T2)
          requires isObjectType(T1) andBool isObjectType(T2)
               andBool isSimilar(type(pointerType(T2)), 
                                 type(pointerType(T1)))
     rule convertConst(t(_, _, rvRefType(T2::CPPType)), prv(Loc::SymLoc, Tr::Trace, T1:CPPClassType))
          => xv(Loc, Tr, T2)
     rule convertConst(_, V::Val) => cannot-convert
          requires notBool isTExpr(V) [owise]

     rule #convertStatic(T::CPPType, V:PRVal) => inverseConvertType(T, V)

     syntax PRVal ::= inverseConvertType(CPPType, PRVal) [function]
     syntax KItem ::= inverseConvertTypeHold(CPPType, PRVal)
     rule inverseConvertType(T:CPPIntegerType, prv(C::CPPValue, Tr::Trace, T':CPPScopedEnumType))
          => prv(C, Tr, T)
          requires notBool isCPPBoolType(T) andBool inRange(C, T)
     rule inverseConvertType(T:CPPIntegerType, prv(C::CPPValue, Tr::Trace, T':CPPScopedEnumType))
          => prv(unknown(C), Tr, T)
          requires notBool isCPPBoolType(T) andBool notBool inRange(C, T)
     rule inverseConvertType(T:CPPBoolType, prv(0, Tr::Trace, T':CPPScopedEnumType))
          => prv(0, Tr, T)
     rule inverseConvertType(T:CPPBoolType, prv(I:Int, Tr::Trace, T':CPPScopedEnumType))
          => prv(1, Tr, T)
          requires I =/=Int 0
     rule inverseConvertType(_:CPPFloatingType, prv(_, _, (T:CPPScopedEnumType => underlyingType(T))))
     rule inverseConvertType(T:CPPEnumType, prv(C::CPPValue, Tr::Trace, T':CPPIntegerType))
          => prv(C, Tr, T)
          requires inRange(C, T)
     rule inverseConvertType(_:CPPEnumType, prv(_, _, (T:CPPEnumType => underlyingType(T))))
     rule inverseConvertType(T:CPPEnumType, prv(C::CPPValue, Tr::Trace, T':CPPIntegerType))
          => UNDIAG("CEC1", "Static cast to enumeration type of value outside range of enumeration.", "5.2.9:10")
          ~> inverseConvertTypeHold(T, prv(C, Tr, T'))
          requires notBool inRange(C, T)
     rule inverseConvertType(T:CPPEnumType, prv(C::CPPValue, Tr::Trace, T':CPPFloatingType))
          => inverseConvertType(T, convertType(underlyingType(T), prv(C, Tr, T')))

     rule inverseConvertType(t(Q::Quals, Mods::Set, pointerType(t(Q'::Quals, Mods'::Set, D:CPPSimpleClassType))), prv(L::SymLoc, Tr::Trace, t(_, _, pointerType(t(Q2::Quals, Mods2::Set, B:CPPSimpleClassType)))))
          => prv(derivedClassSuperobject(L, B, D), Tr, t(Q, Mods, pointerType(t(Q', Mods', D))))
          requires isBaseClassOf(B, D) andBool Q2 <=Quals Q' andBool notBool isVirtualBaseClassOf(B, D) andBool isBaseClassSubobject(L, B, D)
     rule inverseConvertType(t(Q::Quals, Mods::Set, pointerType(t(Q'::Quals, Mods'::Set, D:CPPSimpleClassType))), prv(L::SymLoc, Tr::Trace, t(Q2::Quals, Mods2::Set, pointerType(t(Q2'::Quals, Mods2'::Set, B:CPPSimpleClassType)))))
          => UNDIAG("CEC2", "Static cast to pointer to derived class type of pointer which does not point to object of that type.", "5.2.9:11") ~> inverseConvertTypeHold(t(Q, Mods, pointerType(t(Q', Mods', D))), prv(L, Tr, t(Q2, Mods2, pointerType(t(Q2', Mods2', B)))))
          requires isBaseClassOf(B, D) andBool Q2' <=Quals Q' andBool notBool isVirtualBaseClassOf(B, D) andBool notBool isBaseClassSubobject(L, B, D)

     rule inverseConvertType(t(Q::Quals, Mods::Set, memberPointerType(B::CPPClassType, t(Q'::Quals, Mods'::Set, T1::CPPSimpleType))), prv(L::MemberPtr, Tr::Trace, t(_, _, memberPointerType(D::CPPClassType, t(Q2::Quals, Mods2::Set, T2::CPPSimpleType)))))
          => prv(baseClassSubobject(L, B, D), Tr, t(Q, Mods, memberPointerType(B, t(Q', Mods', T1))))
          requires isBaseClassOf(B, D) andBool type(T1) ==Type type(T2) andBool Q2 <=Quals Q' andBool containsMember(L, B)
     rule inverseConvertType(t(Q::Quals, Mods::Set, memberPointerType(B::CPPClassType, t(Q'::Quals, Mods'::Set, T1::CPPSimpleType))), prv(L::MemberPtr, Tr::Trace, t(Q2::Quals, Mods2::Set, memberPointerType(D::CPPClassType, t(Q2'::Quals, Mods2'::Set, T2::CPPSimpleType)))))
          => UNDIAG("CEC3", "Static cast to pointer to member of base class of pointer to member not contained in base class.", "5.2.9:12") ~> inverseConvertTypeHold(t(Q, Mods, memberPointerType(B, t(Q', Mods', T1))), prv(L, Tr, t(Q2, Mods2, memberPointerType(D, t(Q2', Mods2', T2)))))
          requires isBaseClassOf(B, D) andBool type(T1) ==Type type(T2) andBool Q2' <=Quals Q' andBool notBool containsMember(L, B)

     rule inverseConvertType(t(Q::Quals, Mods::Set, pointerType(t(Q'::Quals, Mods'::Set, T::CPPSimpleType))), prv(Loc::SymLoc, Tr::Trace, t(_, _, pointerType(t(Q2::Quals, Mods2::Set, void)))))
          => #if getAlign(Loc) <=Int getAlignof(t(Q', Mods', T)) #then prv(Loc, Tr, t(Q, Mods, pointerType(t(Q', Mods', T)))) #else prv(unknown(Loc), Tr, t(Q, Mods, pointerType(t(Q', Mods', T)))) #fi
          requires isObjectType(t(Q', Mods', T)) andBool Q2 <=Quals Q'

     rule inverseConvertType(T::CPPType, V::PRVal) => cannot-convert
          requires notBool isTExpr(V) andBool notBool isCPPRefType(T) [owise]

endmodule
