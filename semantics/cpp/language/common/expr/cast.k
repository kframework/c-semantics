module CPP-EXPR-CAST-SYNTAX
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS

     syntax Val ::= convertConst(CPPType, Val) [function]

     syntax Expr ::= convertStatic(CPPType, Val, Trace) [function]
                   | #convertStatic(CPPType, Expr) [strict(c; 2)]

     syntax Expr ::= convertReinterpret(CPPType, Val) [function]

endmodule

module CPP-EXPR-CAST
     imports CPP-EXPR-CAST-SYNTAX
     imports BOOL
     imports INT
     imports BITS-SYNTAX
     imports COMMON-SYNTAX
     imports CPP-ALIGNMENT-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ERROR-SYNTAX
     imports CPP-SETTINGS-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports C-CONFIGURATION

     context <k> ConstCast(T:CPPType, (HOLE:Expr => reval(HOLE))) ...</k>
             <compile-time-evaluation> true </compile-time-evaluation>
             requires isUnnamedPRValue(T) [result(PRV)]
     context <k> ConstCast(T:CPPType, (HOLE:Expr => reval(HOLE))) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation>
             requires isUnnamedPRValue(T) [result(PRVal)]

     rule ConstCast(T:CPPType, V:PRVal) => convertConst(T, V)

     rule ConstCast(T:CPPType, V:Val) => convertConst(T, V)
          requires notBool isUnnamedPRValue(T)

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

     rule convertConst(t(_, _, rvRefType(T2::CPPType)), prv(Loc::SymLoc, Tr::Trace, t(... st: classType(...)) #as T1::CPPType))
          => xv(Loc, Tr, T2)

     rule convertConst(_, V::Val) => cannot-convert [owise]

     rule #convertStatic(T::CPPType, V:PRVal) => inverseConvertType(T, V)

     syntax K ::= inverseConvertType(CPPType, KItem) [function]

     syntax KItem ::= inverseConvertTypeHold(CPPType, PRVal)

     rule inverseConvertType(cppIntegerType #as T::CPPType, prv(C::CPPValue, Tr::Trace, t(... st: _:CPPSimpleScopedEnumType) #as T'::CPPType))
          => prv(C, Tr, T)
          requires notBool isCPPBoolType(T) andBool inRange(C, T)

     rule inverseConvertType(cppIntegerType #as T::CPPType, prv(C::CPPValue, Tr::Trace, t(... st: _:CPPSimpleScopedEnumType) #as T'::CPPType))
          => prv(unknown(C), Tr, T)
          requires notBool isCPPBoolType(T) andBool notBool inRange(C, T)

     rule inverseConvertType(t(... st: _:CPPSimpleBoolType) #as T::CPPType, prv(0, Tr::Trace, t(... st: _:CPPSimpleScopedEnumType) #as T'::CPPType))
          => prv(0, Tr, T)

     rule inverseConvertType(t(... st: _:CPPSimpleBoolType) #as T::CPPType, prv(I:Int, Tr::Trace, t(... st: _:CPPSimpleScopedEnumType) #as T'::CPPType))
          => prv(1, Tr, T)
          requires I =/=Int 0

     rule inverseConvertType(t(... st: _:CPPSimpleFloatingType), prv(_, _, (t(... st: _:CPPSimpleScopedEnumType) #as T::CPPType => underlyingType(T))))

     rule inverseConvertType(cppEnumType #as T::CPPType, prv(C::CPPValue, Tr::Trace, cppIntegerType #as T'::CPPType))
          => prv(C, Tr, T)
          requires inRange(C, T)

     rule inverseConvertType(cppEnumType, prv(_, _, (cppEnumType #as T::CPPType => underlyingType(T))))

     rule inverseConvertType(cppEnumType #as T::CPPType, prv(C::CPPValue, Tr::Trace, cppIntegerType #as T'::CPPType))
          => UNDEF("CEC1", "Static cast to enumeration type of value outside range of enumeration.")
          ~> inverseConvertTypeHold(T, prv(C, Tr, T'))
          requires notBool inRange(C, T)

     rule inverseConvertType(cppEnumType #as T::CPPType, prv(C::CPPValue, Tr::Trace, t(... st: _:CPPSimpleFloatingType) #as T'::CPPType))
          => inverseConvertType(T, convertType(underlyingType(T), prv(C, Tr, T')))

     rule inverseConvertType(t(_, _, pointerType(t(Q::Quals, _, classType(...)) #as D::CPPType)) #as T::CPPType, prv(L::SymLoc, Tr::Trace, t(_, _, pointerType(t(Q'::Quals, _, classType(...)) #as B::CPPType))))
          => prv(derivedClassSuperobject(L, B, D), Tr, T)
          requires B =/=K D andBool isBaseClassOf(B, D) andBool Q' <=Quals Q andBool notBool isVirtualBaseClassOf(B, D) andBool isBaseClassSubobject(L, B, D)

     rule inverseConvertType(t(_, _, pointerType(t(Q::Quals, _, classType(...)) #as D::CPPType)) #as T::CPPType, prv(L::SymLoc, Tr::Trace, t(_, _, pointerType(t(Q'::Quals, _, _) #as B::CPPType))) #as V::PRVal)
          => UNDEF("CEC2", "Static cast to pointer to derived class type of pointer which does not point to object of that type.") ~> inverseConvertTypeHold(T, V)
          requires B =/=K D andBool isBaseClassOf(B, D) andBool Q' <=Quals Q andBool notBool isVirtualBaseClassOf(B, D) andBool notBool isBaseClassSubobject(L, B, D)

     rule inverseConvertType(t(_, _, memberPointerType(B::CPPType, t(Q::Quals, _, _) #as T1::CPPType)) #as T::CPPType, prv(L::MemberPtr, Tr::Trace, t(_, _, memberPointerType(D::CPPType, t(Q'::Quals, _, _) #as T2::CPPType))))
          => prv(baseClassSubobject(L, B, D), Tr, T)
          requires B =/=K D andBool isBaseClassOf(B, D) andBool utype(T1) ==Type utype(T2) andBool Q' <=Quals Q andBool containsMember(L, B)

     rule inverseConvertType(t(_, _, memberPointerType(B::CPPType, t(Q::Quals, _, _) #as T1::CPPType)) #as T::CPPType, prv(L::MemberPtr, Tr::Trace, t(_, _, memberPointerType(D::CPPType, t(Q'::Quals, _, _) #as T2::CPPType))) #as V::PRVal)
          => UNDEF("CEC3", "Static cast to pointer to member of base class of pointer to member not contained in base class.") ~> inverseConvertTypeHold(T, V)
          requires B =/=K D andBool isBaseClassOf(B, D) andBool utype(T1) ==Type utype(T2) andBool Q' <=Quals Q andBool notBool containsMember(L, B)

     rule inverseConvertType(t(Q::Quals, Mods::Set, pointerType(t(Q'::Quals, Mods'::Set, T::CPPSimpleType))), prv(Loc::SymLoc, Tr::Trace, t(_, _, pointerType(t(Q2::Quals, Mods2::Set, void)))))
          => #if getAlign(Loc) >=Int byteAlignofType(t(Q', Mods', T)) #then prv(Loc, Tr, t(Q, Mods, pointerType(t(Q', Mods', T)))) #else prv(unknown(Loc), Tr, t(Q, Mods, pointerType(t(Q', Mods', T)))) #fi
          requires isObjectType(t(Q', Mods', T)) andBool Q2 <=Quals Q'


     rule inverseConvertType(T::CPPType, V:PRExpr) => pre(#convertStatic(T, makePRVal(stripHold(V))), trace(V), T)
          requires (isCPPIntegerType(T) andBool isCPPScopedEnumType(type(V)))
               orBool (isCPPFloatingType(T) andBool isCPPScopedEnumType(type(V)))
               orBool (isCPPEnumType(T) andBool isCPPIntegerType(type(V)))
               orBool (isCPPEnumType(T) andBool isCPPEnumType(type(V)))
               orBool (isCPPEnumType(T) andBool isCPPFloatingType(type(V)))

     rule inverseConvertType(t(... st: pointerType(t(... q: Q::Quals, st: classType(...)) #as D::CPPType)) #as T::CPPType, pre(E::Expr, Tr::Trace, t(... st: pointerType(t(... q: Q'::Quals, st: classType(...)) #as B::CPPType))))
          => pre(#convertStatic(T, makePRVal(E)), Tr, T)
          requires B =/=K D andBool isBaseClassOf(B, D) andBool Q' <=Quals Q andBool notBool isVirtualBaseClassOf(B, D)

     rule inverseConvertType(t(... st: memberPointerType(B::CPPType, t(... q: Q::Quals) #as T1::CPPType)) #as T::CPPType, pre(E::Expr, Tr::Trace, t(... st: memberPointerType(D::CPPType, t(... q: Q'::Quals) #as T2::CPPType))))
          => pre(#convertStatic(T, makePRVal(E)), Tr, T)
          requires B =/=K D andBool isBaseClassOf(B, D) andBool T1 ==Type T2 andBool Q' <=Quals Q

     rule inverseConvertType(t(... st: pointerType(t(... q: Q::Quals) #as T1::CPPType)) #as T::CPPType, pre(E::Expr, Tr::Trace, t(... st: pointerType(t(Q'::Quals, _, void)))))
          => pre(#convertStatic(T, makePRVal(E)), Tr, T)
          requires isObjectType(T1) andBool Q' <=Quals Q

     rule inverseConvertType(T::CPPType, V::PRVal) => cannot-convert
          requires notBool isCPPRefType(T) [owise]

     context <k> ReinterpretCast(T:CPPType, (HOLE:Expr => reval(HOLE))) ...</k>
             <compile-time-evaluation> true </compile-time-evaluation>
             requires isUnnamedPRValue(T) [result(PRV)]
     context <k> ReinterpretCast(T:CPPType, (HOLE:Expr => reval(HOLE))) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation>
             requires isUnnamedPRValue(T) [result(PRVal)]

     rule ReinterpretCast(T:CPPType, V:PRVal) => convertReinterpret(T, V)

     rule ReinterpretCast(T:CPPType, V:Val) => convertReinterpret(T, V)
          requires notBool isUnnamedPRValue(T)

     rule convertReinterpret(T2::CPPType, prv(V::CPPValue, Tr::Trace, T1::CPPType))
          => prv(V, Tr, T2)
          requires T1 ==Type T2

     rule convertReinterpret(cppIntegerType #as T2::CPPType, prv(V::SymLoc, Tr::Trace, t(... st: pointerType(...)) #as T1::CPPType))
          => prv(cfg:pointerToInt(V, T2), Tr, T2)
          requires byteSizeofType(T2) >=Int byteSizeofType(T1)

     rule convertReinterpret(cppRefType #as T2::CPPType, lv(Loc::SymLoc, Tr::Trace, T1::CPPType))
          => lv(Loc, Tr, innerType(T2))
          requires ((isObjectType(innerType(T2)) andBool isObjectType(T1))
               orBool (isCPPFunctionType(innerType(T2)) andBool isCPPFunctionType(T1)))
               andBool isUnnamedLValue(T2)

     rule convertReinterpret(cppRefType #as T2::CPPType, xv(Loc::SymLoc, Tr::Trace, T1::CPPType))
          => lv(Loc, Tr, innerType(T2))
          requires ((isObjectType(innerType(T2)) andBool isObjectType(T1))
               orBool (isCPPFunctionType(innerType(T2)) andBool isCPPFunctionType(T1)))
               andBool isUnnamedLValue(T2)

     rule convertReinterpret(cppRefType #as T2::CPPType, lv(Loc::SymLoc, Tr::Trace, T1::CPPType))
          => xv(Loc, Tr, innerType(T2))
          requires ((isObjectType(innerType(T2)) andBool isObjectType(T1))
               orBool (isCPPFunctionType(innerType(T2)) andBool isCPPFunctionType(T1)))
               andBool isUnnamedXValue(T2)

     rule convertReinterpret(cppRefType #as T2::CPPType, xv(Loc::SymLoc, Tr::Trace, T1::CPPType))
          => xv(Loc, Tr, innerType(T2))
          requires ((isObjectType(innerType(T2)) andBool isObjectType(T1))
               orBool (isCPPFunctionType(innerType(T2)) andBool isCPPFunctionType(T1)))
               andBool isUnnamedXValue(T2)

endmodule
