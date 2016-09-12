module CPP-CONVERSION-SYNTAX
     imports SYMLOC-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS

     syntax Expr ::= instantiate(SymLoc, Trace, CPPType) [klabel(instantiateCpp)]

     syntax PRVal ::= convertType(CPPType, PRVal) [function]
                    | convertType(CPPType, PRExpr) [function]
     syntax PRVal ::= convertLVal(GLVal) [function]
                    | convertLVal(GLExpr) [function]
     syntax PRVal ::= convertArray(Val) [function]
     syntax PRVal ::= convertFunction(LVal) [function]

     syntax CPPType ::= promote(CPPType) [function, klabel(promoteCpp)]
     syntax Bool ::= isPromoted(CPPType) [function, klabel(isPromotedCpp)]

     syntax CPPType ::= usualArithmeticConversions(CPPType, CPPType) [function]

     syntax KItem ::= arithInterpret(CPPType, CPPValue, Trace) [function, klabel(arithInterpretCpp)]
                    | arithInterpretHold(CPPType, CPPValue, Trace) [klabel(arithInterpretHoldCpp)]
endmodule

module CPP-CONVERSION
     imports CPP-CONVERSION-SYNTAX
     imports SETTINGS-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ERROR-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule arithInterpret(T::CPPIntegerType, N::Int, Tr::Trace) => prv(N, Tr, T)
          requires min(T) <=Int N andBool max(T) >=Int N
     rule arithInterpret(T:CPPUnsignedType, N::Int, Tr::Trace) => prv(N modInt (max(T) +Int 1), Tr, T)
          requires (N >Int max(T) orBool N <Int min(T)) andBool notBool hasLint
     rule arithInterpret(T:CPPSignedType, N::Int, Tr::Trace) 
          => UNDIAG("CCV1", "Signed integer overflow.", "5:4") ~> arithInterpretHold(T, N, Tr)
          requires notBool (min(T) <=Int N andBool max(T) >=Int N)

     rule convertType(T::CPPType, prv(V::CPPValue, Tr::Trace, T)) => prv(V, Tr, T)
     rule convertType(T::CPPType, pre(E::Expr, Tr::Trace, T)) => pre(E, Tr, T)

     rule convertType(T:CPPUnsignedType, prv(C::CPPValue, Tr::Trace, T':CPPIntegerType)) => arithInterpret(T, C, Tr)
     rule convertType(T:CPPPointerType, prv(_, Tr::Trace, _:CPPNullPtrTType)) => prv(NullPointer, Tr, T)

     rule convertArray(lv(Loc::SymLoc, Tr::Trace, t(Q::Quals, Mods::Set, T::CPPSimpleArrayType)))
          => prv(Loc, Tr, t(Q, Mods, pointerType(innerType(t(Q, Mods, T)))))

     rule convertFunction(lv(Loc::SymLoc, Tr::Trace, T::CPPFunctionType))
          => prv(Loc, Tr, t(noQuals, .Set, pointerType(T)))

     rule convertLVal(lv(Loc::SymLoc, Tr::Trace, T::CPPType))
          => instantiate(Loc, Tr, T)
     rule convertLVal(le(E::Expr, Tr::Trace, T::CPPType))
          => pre(E, Tr, utype(T))

     syntax Int ::= rank(CPPType) [function, klabel(rankcpp)]
     rule rank(t(_, _, bool)) => 0
     rule rank(t(_, _, char)) => 1
     rule rank(t(_, _, signed-char)) => 1
     rule rank(t(_, _, unsigned-char)) => 1
     rule rank(t(_, _, short)) => 2
     rule rank(t(_, _, unsigned-short)) => 2
     rule rank(t(_, _, int)) => 3
     rule rank(t(_, _, unsigned)) => 3
     rule rank(t(_, _, long)) => 4
     rule rank(t(_, _, unsigned-long)) => 4
     rule rank(t(_, _, long-long)) => 5
     rule rank(t(_, _, unsigned-long-long)) => 5
     rule rank(t(_, _, char16_t)) => rank(type(underlyingType(char16_t)))
     rule rank(t(_, _, char32_t)) => rank(type(underlyingType(char32_t)))
     rule rank(t(_, _, wchar_t)) => rank(type(underlyingType(wchar_t)))

     syntax Bool ::= broaderTypeThan(CPPType, CPPType) [function]
     rule broaderTypeThan(T1::CPPIntegerType, T2::CPPIntegerType)
          => max(T1) >=Int max(T2) andBool min(T1) <=Int min(T2)

     // 4.5:1
     rule promote(t(_, _, T::CPPSimpleType)) => #if broaderTypeThan(type(int), type(T)) #then type(int) #else type(unsigned) #fi
          requires isCPPIntegerType(T) andBool T =/=K bool andBool T =/=K char16_t andBool T =/=K char32_t andBool T =/=K wchar_t
               andBool rank(type(T)) <Int rank(type(int))
     // 4.5:2
     rule promote(t(_, _, T::CPPSimpleType)) => #if broaderTypeThan(type(int), type(T)) #then type(int) #else 
                                                #if broaderTypeThan(type(unsigned), type(T)) #then type(unsigned) #else
                                                #if broaderTypeThan(type(long), type(T)) #then type(long) #else
                                                #if broaderTypeThan(type(unsigned-long), type(T)) #then type(unsigned-long) #else
                                                #if broaderTypeThan(type(long-long), type(T)) #then type(long-long) #else
                                                #if broaderTypeThan(type(unsigned-long-long), type(T)) #then type(unsigned-long-long) #else
                                                type(underlyingType(T)) 
                                                #fi #fi #fi #fi #fi #fi
          requires T ==K char16_t orBool T ==K char32_t orBool T ==K wchar_t
     // TODO(dwightguth): 4.5:3-5
     // 4.5:6
     rule promote(t(_, _, bool)) => type(int)
     rule promote(T::CPPType) => T
          requires notBool isCPPBitfieldType(T) andBool notBool isCPPEnumType(T) [owise]
     rule isPromoted(T::CPPType) => T ==Type promote(T)
     

     // TODO(dwightguth): handle modifiers if we need them
     // 5:10.1
     rule usualArithmeticConversions(T:CPPEnumType, T) => T
     // 5:10.2
     rule usualArithmeticConversions(t(_, _, long-double), _) => t(noQuals, .Set, long-double)
     rule usualArithmeticConversions(_, t(_, _, long-double)) => t(noQuals, .Set, long-double)
     // 5:10.3
     rule usualArithmeticConversions(t(_, _, double), t(_, _, T::CPPSimpleType)) => t(noQuals, .Set, double)
          requires T =/=K long-double
     rule usualArithmeticConversions(t(_, _, T::CPPSimpleType), t(_, _, double)) => t(noQuals, .Set, double)
          requires T =/=K long-double
     // 5:10.4
     rule usualArithmeticConversions(t(_, _, float), t(_, _, T::CPPSimpleType)) => t(noQuals, .Set, float)
          requires T =/=K long-double andBool T =/=K double
     rule usualArithmeticConversions(t(_, _, T::CPPSimpleType), t(_, _, float)) => t(noQuals, .Set, float)
          requires T =/=K long-double andBool T =/=K double
     // 5:10.5
     rule usualArithmeticConversions(T1::CPPType, T2::CPPType) => #usualArithmeticConversions(promote(T1), promote(T2))
     syntax CPPType ::= #usualArithmeticConversions(CPPType, CPPType) [function]
                      | #usualArithmeticConversions2(CPPType, CPPType) [function]
     // 5:10.5.1
     rule #usualArithmeticConversions(T::CPPType, T::CPPType) => T
     // 5:10.5.2
     rule #usualArithmeticConversions(T1:CPPSignedType, T2:CPPSignedType) => #if rank(T1) >Int rank(T2) #then T1 #else T2 #fi
     rule #usualArithmeticConversions(T1:CPPUnsignedType, T2:CPPUnsignedType) => #if rank(T1) >Int rank(T2) #then T1 #else T2 #fi
     rule #usualArithmeticConversions(T1:CPPUnsignedType, T2:CPPSignedType) => #usualArithmeticConversions2(T1, T2)
     rule #usualArithmeticConversions(T1:CPPSignedType, T2:CPPUnsignedType) => #usualArithmeticConversions2(T2, T1)
     // 5:10.5.3
     rule #usualArithmeticConversions2(Unsigned::CPPType, Signed::CPPType) => Unsigned
          requires rank(Unsigned) >=Int rank(Signed)
     // 5:10.5.4
     rule #usualArithmeticConversions2(Unsigned::CPPType, Signed::CPPType) => Signed
          requires rank(Unsigned) <Int rank(Signed)
               andBool broaderTypeThan(Signed, Unsigned)
     // 5:10.5.5
     rule #usualArithmeticConversions2(_, Signed::CPPSignedType) => correspondingUnsignedType(Signed)

endmodule
