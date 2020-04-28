module CPP-CONVERSION-SYNTAX
     imports SYMLOC-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS

     syntax Expr ::= instantiate(SymLoc, Trace, CPPType) [klabel(instantiateCpp)]

     // performs standard type conversions only
     syntax PRVal ::= convertType(CPPType, PRVal) [function]

     syntax PRExpr ::= convertType(CPPType, PRExpr) [function]

     syntax Expr ::= convertTypeHold(CPPType, Expr)

     syntax KItem
     syntax Expr ::= convertLVal(KItem) [function]
                   | convertArray(Val) [function]
                   | convertFunction(LVal) [function]
                   | convertReval(Val) [function]

     syntax Bool ::= isSimilar(CPPType, CPPType) [function]

     syntax List ::= cvQualificationSignature(CPPType) [function]

     syntax Bool ::= List "<=QualSig" List [function]

     syntax CPPType ::= prvalType(CPPType) [function]
                      | revalType(CPPType) [function]

     // remember to call promote twice if you want to get the promoted
     // type of another type. calling promote once is intended to
     // allow differentiation between the underlying type of an enum
     // and the promoted underlying type, both of which are conversions
     // considered "promotion".
     syntax CPPType ::= promote(CPPType) [function, klabel(promoteCpp)]

     syntax Bool ::= isPromoted(CPPType) [function, klabel(isPromotedCpp)]
                   | isCompositePointerType(CPPType) [function]

     syntax CPPType ::= compositePointerType(PRVal, PRVal) [function]
                      | compositePointerType(Expr, CPPType, Expr, CPPType) [function, klabel(compositePointerType4)]
                      | usualArithmeticConversions(CPPType, CPPType) [function]

     syntax PRVal ::= arithInterpret(CPPType, CPPValue, Trace) [function, klabel(arithInterpretCpp)]
                   | arithInterpretHold(CPPType, CPPValue, Trace) [klabel(arithInterpretHoldCpp)]

     syntax Bool ::= isNullPointerConstant(PRVal) [function, klabel(isNullPointerConstantCpp)]

     syntax Bool ::= canConvertWithStandardConversion(CPPType, CPPType, ValueCategory) [function]

     syntax CannotConvert ::= "cannot-convert"

     syntax PRVal ::= CannotConvert

     syntax PRExpr ::= CannotConvert

     syntax ValResult ::= CannotConvert
endmodule

module CPP-CONVERSION
     imports CPP-CONVERSION-SYNTAX
     imports FLOAT
     imports INT
     imports SETTINGS-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ERROR-SYNTAX
     imports CPP-REFERENCE-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-SYNTAX
     imports C-CONFIGURATION

     syntax PRVal ::= ErrorResult

     syntax PRExpr ::= ErrorResult

     context <k> ConvertType(_, (HOLE:Expr => reval(HOLE))) ...</k> 
             <compile-time-evaluation> true </compile-time-evaluation> [result(PRV)]
     context <k> ConvertType(_, (HOLE:Expr => reval(HOLE))) ...</k>
             <compile-time-evaluation> false </compile-time-evaluation> [result(PRVal)]

     rule ConvertType(T::CPPType, R:PRVal) => convertType(T, R)

     rule arithInterpret(cppIntegerType #as T::CPPType, N:Int, Tr::Trace) => prv(N, Tr, T)
          requires min(T) <=Int N andBool max(T) >=Int N

     rule arithInterpret(t(... st: _:CPPSimpleUnsignedType) #as T::CPPType, N:Int, Tr::Trace) => prv(N modInt (max(T) +Int 1), Tr, T)
          requires (N >Int max(T) orBool N <Int min(T)) andBool notBool hasLint

     rule arithInterpret(t(... st: _:CPPSimpleSignedType) #as T::CPPType, N:Int, Tr::Trace)
          => errorFuncResult(UNDEF("CCV1", "Signed integer overflow."), arithInterpretHold(T, N, Tr))
          requires notBool (min(T) <=Int N andBool max(T) >=Int N)

     rule arithInterpret(t(... st: _:CPPSimpleFloatingType) #as T::CPPType, (F:Float => roundFloat(F, precision(T), exponent(T))), _)
          requires precisionFloat(F) =/=Int precision(T) orBool exponentBitsFloat(F) =/=Int exponent(T)

     rule arithInterpret(t(... st: _:CPPSimpleFloatingType) #as T::CPPType, F:Float, Tr::Trace) => prv(F, Tr, T)
          requires precisionFloat(F) ==Int precision(T) andBool exponentBitsFloat(F) ==Int exponent(T)
               andBool notBool isInfinite(F)

     rule arithInterpret(t(... st: _:CPPSimpleFloatingType) #as T::CPPType, F:Float, Tr::Trace)
          => errorFuncResult(UNDEF("CCV2", "Floating point overflow."),
             arithInterpretHold(T, F, Tr))
          requires isInfinite(F)

     rule convertType(T1::CPPType, prv(V::CPPValue, Tr::Trace, T2::CPPType)) => prv(V, Tr, T2)
          requires T1 ==Type T2

     rule convertType(T1::CPPType, pre(E::Expr, Tr::Trace, T2::CPPType)) => pre(E, Tr, T2)
          requires T1 ==Type T2

     rule convertType(T::CPPType, prv(C::CPPValue, Tr::Trace, cppIntegerType #as T'::CPPType)) => prv(C, Tr, T)
          requires isCPPSignedType(underlyingType(T)) andBool inRange(C, T)

     rule convertType(T::CPPType, prv(C::CPPValue, Tr::Trace, cppIntegerType #as T'::CPPType))
          => errorFuncResult(IMPL("CCV3", "Integral conversion to signed integer type in which value cannot be represented."),
             convertTypeHold(T, prv(C, Tr, T')))
          requires isCPPSignedType(underlyingType(T)) andBool notBool inRange(C, T)

     rule convertType(T::CPPType, prv(C::CPPValue, Tr::Trace, cppIntegerType #as T'::CPPType)) => arithInterpret(T, C, Tr)
          requires notBool isCPPEnumType(T) andBool isCPPUnsignedType(underlyingType(T)) andBool inRange(C, T)

     rule convertType(T::CPPType, prv(N:Int, Tr::Trace, cppIntegerType #as T'::CPPType)) => prv(N modInt (max(T) +Int 1), Tr, T)
          requires notBool isCPPEnumType(T) andBool isCPPUnsignedType(underlyingType(T)) andBool notBool inRange(N, T)

     rule convertType(cppIntegerType #as T::CPPType, prv(C::CPPValue, Tr::Trace, t(... st: _:CPPSimpleBoolType) #as T'::CPPType)) => prv(C, Tr, T)

     rule convertType(t(... st: _:CPPSimpleBoolType) #as T::CPPType, prv(0, Tr::Trace, cppIntegerType #as T'::CPPType)) => prv(0, Tr, T)

     rule convertType(t(... st: _:CPPSimpleBoolType) #as T::CPPType, prv(I:Int, Tr::Trace, cppIntegerType #as T'::CPPType)) => prv(1, Tr, T)
          requires I =/=Int 0

     rule convertType(cppIntegerType, prv(_, _, (t(... st: _:CPPSimpleUnscopedEnumType) #as T::CPPType => underlyingType(T))))

     rule convertType(t(... st: _:CPPSimpleFloatingType) #as T::CPPType, prv(F:Float, Tr::Trace, t(... st: _:CPPSimpleFloatingType) #as T'::CPPType)) => arithInterpret(T, F, Tr)
          requires inRange(F, T)

     rule convertType(t(... st: _:CPPSimpleFloatingType) #as T::CPPType, prv(F:Float, Tr::Trace, t(... st: _:CPPSimpleFloatingType) #as T'::CPPType))
          => errorFuncResult(UNDEF("CCV4", "Floating point conversion to type in which value is not between any two adjacent destination values."),
             convertTypeHold(T, prv(F, Tr, T')))
          requires notBool inRange(F, T)

     rule convertType(cppIntegerType #as T::CPPType, prv(F:Float, Tr::Trace, t(... st: _:CPPSimpleFloatingType) #as T'::CPPType))
          => arithInterpret(T, Float2Int(F), Tr)
          requires notBool isCPPBoolType(T) andBool inRange(Float2Int(F), T)

     rule convertType(cppIntegerType #as T::CPPType, prv(F:Float, Tr::Trace, t(... st: _:CPPSimpleFloatingType) #as T'::CPPType))
          => errorFuncResult(UNDEF("CCV5", "Floating-integral conversion to integer type in which value cannot be represented."),
             convertTypeHold(T, prv(F, Tr, T')))
          requires notBool isCPPBoolType(T) andBool notBool inRange(Float2Int(F), T)

     rule convertType(t(... st: _:CPPSimpleBoolType) #as T::CPPType, prv(F:Float, Tr::Trace, t(... st: _:CPPSimpleFloatingType) #as T'::CPPType))
          => prv(0, Tr, T)
          requires F ==Float 0.0

     rule convertType(t(... st: _:CPPSimpleBoolType) #as T::CPPType, prv(F:Float, Tr::Trace, t(... st: _:CPPSimpleFloatingType) #as T'::CPPType))
          => prv(1, Tr, T)
          requires F =/=Float 0.0

     rule convertType(t(... st: _:CPPSimpleFloatingType), prv(_, _, (t(... st: _:CPPSimpleUnscopedEnumType) #as T::CPPType => underlyingType(T))))

     rule convertType(t(... st: _:CPPSimpleFloatingType) #as T::CPPType, prv(I:Int, Tr::Trace, cppIntegerType #as T'::CPPType))
          => arithInterpret(T, Int2Float(I, precision(T), exponent(T)), Tr)
          requires notBool isInfinite(Int2Float(I, precision(T), exponent(T)))

     rule convertType(t(... st: _:CPPSimpleFloatingType) #as T::CPPType, prv(I:Int, Tr::Trace, cppIntegerType #as T'::CPPType))
          => errorFuncResult(UNDEF("CCV6", "Floating-integral conversion to floating point type in which value is outside range that can be represented."),
             convertTypeHold(T, prv(I, Tr, T')))
          requires isInfinite(Int2Float(I, precision(T), exponent(T)))

     rule convertType(t(... st: pointerType(...)) #as T::CPPType, prv(_, Tr::Trace, t(... st: nullptr_t))) => prv(NullPointer, Tr, T)

     rule convertType(t(_, _, pointerType(t(Q::Quals, _, void))) #as T::CPPType, prv(L::SymLoc, Tr::Trace, t(_, _, pointerType(t(Q'::Quals, _, _) #as T'::CPPType))))
          => prv(L, Tr, T)
          requires isObjectType(T') andBool Q' <=Quals Q

     rule convertType(t(_, _, pointerType(t(Q::Quals, _, classType(...)) #as B::CPPType)) #as T::CPPType, prv(L::SymLoc, Tr::Trace, t(_, _, pointerType(t(Q'::Quals, _, classType(...)) #as D::CPPType))))
          => prv(baseClassSubobject(L, B, D), Tr, T)
          requires utype(B) =/=Type utype(D) andBool isBaseClassOf(B, D) andBool Q' <=Quals Q

     rule convertType(t(... st: _:CPPSimpleBoolType) #as T::CPPType, prv(NullPointer, Tr::Trace, t(... st: pointerType(...)) #as T'::CPPType))
          => prv(0, Tr, T)

     rule convertType(t(... st: _:CPPSimpleBoolType) #as T::CPPType, prv(Loc::SymLoc, Tr::Trace, t(... st: pointerType(...)) #as T'::CPPType))
          => prv(1, Tr, T)
          requires Loc =/=K NullPointer

     rule convertType(t(... st: memberPointerType(_, t(... st: functionType(...)))) #as T::CPPType, prv(_, Tr::Trace, t(... st: nullptr_t))) => prv(NullMemberFunctionPointer, Tr, T)

     rule convertType(t(... st: memberPointerType(...)) #as T::CPPType, prv(_, Tr::Trace, t(... st: nullptr_t))) => prv(NullMemberPointer, Tr, T)
          requires notBool(isCPPMemberFunctionPointerType(T))

     rule convertType(t(_, _, memberPointerType(D::CPPType, T1::CPPType)) #as MemberT::CPPType, prv(L::MemberPtr, Tr::Trace, t(_, _, memberPointerType(B::CPPType, T2::CPPType))))
          => prv(derivedClassSuperobject(L, B, D), Tr, MemberT)
          requires B =/=K D andBool isBaseClassOf(B, D) andBool utype(T1) ==Type utype(T2) andBool getQuals(T2) <=Quals getQuals(T1)

     rule convertType(t(... st: _:CPPSimpleBoolType) #as T::CPPType, prv(NullMemberPointer, Tr::Trace, t(... st: memberPointerType(...)) #as T'::CPPType))
          => prv(0, Tr, T)

     rule convertType(t(... st: _:CPPSimpleBoolType) #as T::CPPType, prv(Loc::MemberPtr, Tr::Trace, t(... st: memberPointerType(...)) #as T'::CPPType))
          => prv(1, Tr, T)
          requires Loc =/=K NullMemberPointer andBool Loc =/=K NullMemberFunctionPointer

     // Qualification conversions: http://rvdoc.org/C++14/4.4
     // 1
     rule convertType(t(... st: pointerType(...)) #as T2::CPPType, prv(L::SymLoc, Tr::Trace, t(... st: pointerType(...)) #as T1::CPPType))
          => prv(L, Tr, T2)
          requires isSimilar(T1, T2)
               andBool cvQualificationSignature(T1) <=QualSig cvQualificationSignature(T2)

     // 2
     rule convertType(t(... st: memberPointerType(X2::CPPType, T2::CPPType)) #as T::CPPType,
            prv(L::MemberPtr, Tr::Trace, t(... st: memberPointerType(X1::CPPType, T1::CPPType))))
          => prv(L, Tr, T)
          requires X1 ==Type X2 andBool isSimilar(T1, T2)
               andBool cvQualificationSignature(T1) <=QualSig cvQualificationSignature(T2)

     rule convertType(_::CPPType, _::PRExpr) => cannot-convert [owise]

     rule isSimilar(t(_, _, pointerType(T1::CPPType)), t(_, _, pointerType(T2::CPPType)))
          => isSimilar(T1, T2)

     rule isSimilar(t(_, _, memberPointerType(C1::CPPType, T1::CPPType)), t(_, _, memberPointerType(C2::CPPType, T2::CPPType)))
          => C1 ==Type C2 andBool isSimilar(T1, T2)

     rule isSimilar(t(_, _, arrayType(T1::CPPType, N1::Int)), t(_, _, arrayType(T2::CPPType, N2::Int)))
          => N1 ==Int N2 andBool isSimilar(T1, T2)

     rule isSimilar(t(_, _, incompleteArrayType(T1::CPPType)), t(_, _, incompleteArrayType(T2::CPPType)))
          => isSimilar(T1, T2)

     rule isSimilar(T1::CPPType, T2::CPPType)
          => utype(T1) ==Type utype(T2) [owise]

     rule convertArray(lv(Loc::SymLoc, Tr::Trace, T::CPPType))
          => prv(arrayToPtrLoc(Loc, T), Tr, revalType(T))

     rule convertArray(xv(Loc::SymLoc, Tr::Trace, T::CPPType))
          => prv(arrayToPtrLoc(Loc, T), Tr, revalType(T))

     rule convertArray(prv(Loc::SymLoc, Tr::Trace, T::CPPType))
         => prv(arrayToPtrLoc(Loc, T), Tr, revalType(T))

     syntax SymLoc ::= arrayToPtrLoc(SymLoc, CPPType) [function, klabel(arrayToPtrLocCpp)]

     rule arrayToPtrLoc(Loc::SymLoc, t(_, _, arrayType(...)) #as T::CPPType)
          => addProv(fromArray(0, byteSizeofType(T), T), Loc)

     rule arrayToPtrLoc(Loc::SymLoc, _) => Loc [owise]

     rule convertFunction(lv(Loc::SymLoc, Tr::Trace, T::CPPType))
          => prv(Loc, Tr, revalType(T))

     rule prvalType(t(... st: _:CPPSimpleArrayType) #as T::CPPType) => T

     rule prvalType(t(... st: classType(...)) #as T::CPPType) => T

     rule prvalType(T::CPPType) => utype(T) [owise]

     rule revalType(t(Q::Quals, Mods::Set, arrayType(T::CPPType, _))) => t(Q, Mods, pointerType(T))

     rule revalType(t(... st: functionType(...)) #as T::CPPType) => type(pointerType(T))

     rule revalType(T::CPPType) => prvalType(T) [owise]

     rule convertLVal(lv(Loc::SymLoc, Tr::Trace, T::CPPType))
          => instantiate(Loc, Tr, T)

     rule convertLVal(xv(Loc::SymLoc, Tr::Trace, T::CPPType))
          => instantiate(Loc, Tr, T)

     rule convertLVal(le(E::Expr, Tr::Trace, T::CPPType))
          => pre(E, Tr, prvalType(T))

     rule convertLVal(xe(E::Expr, Tr::Trace, T::CPPType))
          => pre(E, Tr, prvalType(T))

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

     rule rank(t(_, _, oversized)) => 6

     rule rank(t(_, _, unsigned-oversized)) => 6

     rule rank(t(_, _, char16_t)) => rank(type(underlyingType(char16_t)))

     rule rank(t(_, _, char32_t)) => rank(type(underlyingType(char32_t)))

     rule rank(t(_, _, wchar_t)) => rank(type(underlyingType(wchar_t)))

     rule rank(t(_, _, bitfieldType(T::CPPSimpleType, _))) => rank(type(T))

     syntax Bool ::= broaderTypeThan(CPPType, CPPType) [function]

     rule broaderTypeThan(T1::CPPType, T2::CPPType)
          => max(T1) >=Int max(T2) andBool min(T1) <=Int min(T2)

     // 4.5:1
     rule promote(t(_, _, T::CPPSimpleType)) => #if broaderTypeThan(type(int), type(T)) #then type(int) #else type(unsigned) #fi
          requires isCPPIntegerType(type(T)) andBool T =/=K bool andBool T =/=K char16_t andBool T =/=K char32_t andBool T =/=K wchar_t
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

     // 4.5:3
     // TODO(h0nzZik) (1) store the type in configuration for performance reasons,
     //               (2) what if we have an extended integer type other then the underlying type?
     rule promote(t(_, _, unscopedEnum(_, _, false) #as T::CPPSimpleType)) =>
               #if broaderTypeThan(type(int), type(T)) #then type(int) #else
               #if broaderTypeThan(type(unsigned), type(T)) #then type(unsigned) #else
               #if broaderTypeThan(type(long), type(T)) #then type(long) #else
               #if broaderTypeThan(type(unsigned-long), type(T)) #then type(unsigned-long) #else
               #if broaderTypeThan(type(long-long), type(T)) #then type(long-long) #else
               #if broaderTypeThan(type(unsigned-long-long), type(T)) #then type(unsigned-long-long) #else
               type(underlyingType(T)) // Not reachable without extended integer types
               #fi #fi #fi #fi #fi #fi

     // 4.5:4
     rule promote(t(_, _, unscopedEnum(_, UT::CPPType, true))) => UT

     // 4.5:5
     rule promote(t(_, _, bitfieldType(T::CPPSimpleType, N::Int))) =>
          #if broaderTypeThan(type(int), type(bitfieldType(T, N))) #then type(int) #else
          #if broaderTypeThan(type(unsigned), type(bitfieldType(T, N))) #then type(unsigned) #else
          type(bitfieldType(T, N))
          #fi #fi
          requires notBool isCPPSimpleEnumType(T)

     rule promote(t(_, _, bitfieldType(T:CPPSimpleEnumType, _) => T))

     // 4.5:6
     rule promote(t(_, _, bool)) => type(int)

     rule promote(T::CPPType) => T [owise]

     rule isPromoted(T::CPPType) => T ==Type promote(promote(T))


     // TODO(dwightguth): handle modifiers if we need them
     // 5:10.1
     rule usualArithmeticConversions(t(... st: _:CPPSimpleScopedEnumType) #as T::CPPType, T) => T

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
     rule usualArithmeticConversions(T1::CPPType, T2::CPPType) => #usualArithmeticConversions(promote(promote(T1)), promote(promote(T2))) [owise]

     syntax CPPType ::= #usualArithmeticConversions(CPPType, CPPType) [function]
                      | #usualArithmeticConversions2(CPPType, CPPType) [function]

     // 5:10.5.1
     rule #usualArithmeticConversions(T::CPPType, T::CPPType) => T

     // 5:10.5.2
     rule #usualArithmeticConversions(t(... st: _:CPPSimpleSignedType) #as T1::CPPType, t(... st: _:CPPSimpleSignedType) #as T2::CPPType) => #if rank(T1) >Int rank(T2) #then T1 #else T2 #fi

     rule #usualArithmeticConversions(t(... st: _:CPPSimpleUnsignedType) #as T1::CPPType, t(... st: _:CPPSimpleUnsignedType) #as T2::CPPType) => #if rank(T1) >Int rank(T2) #then T1 #else T2 #fi

     rule #usualArithmeticConversions(t(... st: _:CPPSimpleUnsignedType) #as T1::CPPType, t(... st: _:CPPSimpleSignedType) #as T2::CPPType) => #usualArithmeticConversions2(T1, T2)

     rule #usualArithmeticConversions(t(... st: _:CPPSimpleSignedType) #as T1::CPPType, t(... st: _:CPPSimpleUnsignedType) #as T2::CPPType) => #usualArithmeticConversions2(T2, T1)

     // 5:10.5.3
     rule #usualArithmeticConversions2(Unsigned::CPPType, Signed::CPPType) => Unsigned
          requires rank(Unsigned) >=Int rank(Signed)

     // 5:10.5.4
     rule #usualArithmeticConversions2(Unsigned::CPPType, Signed::CPPType) => Signed
          requires rank(Unsigned) <Int rank(Signed)
               andBool broaderTypeThan(Signed, Unsigned)

     // 5:10.5.5
     rule #usualArithmeticConversions2(_, Signed::CPPType) => correspondingUnsignedType(Signed)

     rule isNullPointerConstant(V::PRVal) => true
          requires isCPPNullPtrTType(type(V))

     rule isNullPointerConstant(V::PRVal) => false
          requires trace(V) =/=K noTrace [owise]

     rule isCompositePointerType(T::CPPType) => isCPPPointerType(T) orBool isCPPMemberPointerType(T) orBool isCPPNullPtrTType(T)

     // we only use the prval to check the type and to check if it's a null pointer constant,
     // which only uses the trace and type, so this should be safe.
     rule compositePointerType(E1::Expr, T1::CPPType, E2::Expr, T2::CPPType)
          => compositePointerType(prv(0, hasTrace(E1), T1), prv(0, hasTrace(E2), T2))

     //5:13.3
     rule compositePointerType(L::PRVal, R::PRVal) => type(nullptr_t)
          requires isNullPointerConstant(L) andBool isNullPointerConstant(R)

     //5:13.4
     rule compositePointerType(L::PRVal, R::PRVal) => type(L)
          requires notBool isNullPointerConstant(L) andBool isNullPointerConstant(R)

     rule compositePointerType(L::PRVal, R::PRVal) => type(R)
          requires notBool isNullPointerConstant(R) andBool isNullPointerConstant(L)

     rule compositePointerType(L::PRVal, R::PRVal) => #compositePointerType(type(L), type(R)) [owise]

     syntax CPPType ::= cvCombinedType(CPPType, CPPType) [function]

     syntax CPPType ::= #compositePointerType(CPPType, CPPType) [function]

     // 5:13.5
     rule #compositePointerType(t(_, Mods::Set, pointerType(t(Q'::Quals, Mods'::Set, void))),
                               t(_, Mods2::Set, pointerType(t(Q2'::Quals, Mods2'::Set, _))))
          => t(noQuals, Mods Mods2, pointerType(t(Q' +Quals Q2', Mods' Mods2', void)))

     rule #compositePointerType(t(_, Mods::Set, pointerType(t(Q'::Quals, Mods'::Set, _))),
                               t(_, Mods2::Set, pointerType(t(Q2'::Quals, Mods2'::Set, void))))
          => t(noQuals, Mods Mods2, pointerType(t(Q' +Quals Q2', Mods' Mods2', void)))

     // 5:13.6
     rule #compositePointerType(t(Q::Quals, Mods::Set, pointerType(C1::CPPType)), t(Q2::Quals, Mods2::Set, pointerType(C2::CPPType)))
          => cvCombinedType(t(Q, Mods, pointerType(C1)), t(Q2, Mods2, pointerType(C2)))
          requires isReferenceRelated(utype(C1), utype(C2))

     rule #compositePointerType(t(Q::Quals, Mods::Set, pointerType(C1::CPPType)), t(Q2::Quals, Mods2::Set, pointerType(C2::CPPType)))
          => cvCombinedType(t(Q2, Mods2, pointerType(C2)), t(Q, Mods, pointerType(C1)))
          requires isReferenceRelated(utype(C2), utype(C1))

     // 5:13.7
     rule #compositePointerType(t(Q::Quals, Mods::Set, memberPointerType(C1::CPPType, U1::CPPType)), t(Q2::Quals, Mods2::Set, memberPointerType(C2::CPPType, U2::CPPType)))
          => cvCombinedType(t(Q2, Mods2, memberPointerType(C2, U2)), t(Q, Mods, memberPointerType(C1, U1)))
          requires isReferenceRelated(C1, C2)

     rule #compositePointerType(t(Q::Quals, Mods::Set, memberPointerType(C1::CPPType, U1::CPPType)), t(Q2::Quals, Mods2::Set, memberPointerType(C2::CPPType, U2::CPPType)))
          => cvCombinedType(t(Q, Mods, memberPointerType(C1, U1)), t(Q2, Mods2, memberPointerType(C2, U2)))
          requires isReferenceRelated(C2, C1)

     // 5:13.8
     rule #compositePointerType(T1::CPPType, T2::CPPType)
          => cvCombinedType(T1, T2)
          requires isSimilar(T1, T2)

     rule cvQualificationSignature(t(Q::Quals, _, pointerType(T::CPPType))) => ListItem(Q) cvQualificationSignature(T)

     rule cvQualificationSignature(t(Q::Quals, _, memberPointerType(_, T::CPPType))) => ListItem(Q) cvQualificationSignature(T)

     rule cvQualificationSignature(t(Q::Quals, _, arrayType(T::CPPType, _))) => ListItem(Q) cvQualificationSignature(T)

     rule cvQualificationSignature(t(Q::Quals, _, incompleteArrayType(T::CPPType))) => ListItem(Q) cvQualificationSignature(T)

     rule cvQualificationSignature(t(Q::Quals, _, _)) => ListItem(Q) [owise]

     rule Qs1::List <=QualSig Qs2::List
          => computeLeQualSig(Qs1, Qs2, getDifferentCVOffset(Qs1, Qs2, 0, 0), 0)

     syntax Bool ::= computeLeQualSig(List, List, Int, Int) [function]

     rule computeLeQualSig((ListItem(Q1::Quals) => .List) _, (ListItem(Q2::Quals) => .List) _, J::Int, (K::Int => K +Int 1))
          requires K ==Int 0 orBool (Q1 <=Quals Q2          // 4.4:4.2
           andBool (J <=Int K orBool Const() inQuals Q2))   // 4.4:4.3

     rule computeLeQualSig(.List, .List, _, _) => true

     rule computeLeQualSig(_, _, _, _) => false [owise]


     rule cvCombinedType(T1::CPPType, T2::CPPType) => utype(#cvCombinedType(T1, cvQualificationSignature(T2), getDifferentCVOffset(cvQualificationSignature(T1), cvQualificationSignature(T2), 0, 0), 0))

     syntax CPPType ::= #cvCombinedType(CPPType, List, Int, Int) [function]

     syntax Int ::= getDifferentCVOffset(List, List, Int, Int) [function]

     rule getDifferentCVOffset(ListItem(Q::Quals) L1::List, ListItem(Q::Quals) L2::List, Idx::Int, Res::Int)
          => getDifferentCVOffset(L1, L2, Idx +Int 1, Res)

     rule getDifferentCVOffset(ListItem(Q1::Quals) L1::List, ListItem(Q2::Quals) L2::List, Idx::Int, Res::Int)
          => getDifferentCVOffset(L1, L2, Idx +Int 1, Idx)
          requires Q1 =/=K Q2

     rule getDifferentCVOffset(.List, _, _, Res::Int) => Res

     rule #cvCombinedType(t(Q::Quals, Mods::Set, pointerType(T::CPPType)), ListItem(Q'::Quals) L::List, J::Int, K::Int)
          => t((Q +Quals Q') +Qual Const(), Mods, pointerType(#cvCombinedType(T, L, J, K +Int 1)))
          requires K <Int J

     rule #cvCombinedType(t(Q::Quals, Mods::Set, pointerType(T::CPPType)), ListItem(Q'::Quals) L::List, J::Int, K::Int)
          => t(Q +Quals Q', Mods, pointerType(#cvCombinedType(T, L, J, K +Int 1)))
          requires J <=Int K

     rule #cvCombinedType(t(Q::Quals, Mods::Set, memberPointerType(C::CPPType, T::CPPType)), ListItem(Q'::Quals) L::List, J::Int, K::Int)
          => t((Q +Quals Q') +Qual Const(), Mods, memberPointerType(C, #cvCombinedType(T, L, J, K +Int 1)))
          requires K <Int J

     rule #cvCombinedType(t(Q::Quals, Mods::Set, memberPointerType(C::CPPType, T::CPPType)), ListItem(Q'::Quals) L::List, J::Int, K::Int)
          => t(Q +Quals Q', Mods, memberPointerType(C, #cvCombinedType(T, L, J, K +Int 1)))
          requires J <=Int K

     rule #cvCombinedType(t(Q::Quals, Mods::Set, arrayType(T::CPPType, N::Int)), ListItem(Q'::Quals) L::List, J::Int, K::Int)
          => t((Q +Quals Q') +Qual Const(), Mods, arrayType(#cvCombinedType(T, L, J, K +Int 1), N))
          requires K <Int J

     rule #cvCombinedType(t(Q::Quals, Mods::Set, arrayType(T::CPPType, N::Int)), ListItem(Q'::Quals) L::List, J::Int, K::Int)
          => t(Q +Quals Q', Mods, arrayType(#cvCombinedType(T, L, J, K +Int 1), N))
          requires J <=Int K

     rule #cvCombinedType(t(Q::Quals, Mods::Set, incompleteArrayType(T::CPPType)), ListItem(Q'::Quals) L::List, J::Int, K::Int)
          => t((Q +Quals Q') +Qual Const(), Mods, incompleteArrayType(#cvCombinedType(T, L, J, K +Int 1)))
          requires K <Int J

     rule #cvCombinedType(t(Q::Quals, Mods::Set, incompleteArrayType(T::CPPType)), ListItem(Q'::Quals) L::List, J::Int, K::Int)
          => t(Q +Quals Q', Mods, incompleteArrayType(#cvCombinedType(T, L, J, K +Int 1)))
          requires J <=Int K

     rule #cvCombinedType(t(Q::Quals, Mods::Set, T::CPPSimpleType), ListItem(Q'::Quals) L::List, J::Int, K::Int)
          => #if K <Int J #then t((Q +Quals Q') +Qual Const(), Mods, T) #else t(Q +Quals Q', Mods, T) #fi [owise]

endmodule
