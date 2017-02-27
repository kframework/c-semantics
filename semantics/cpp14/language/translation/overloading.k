module CPP-OVERLOADING-SYNTAX
     imports COMPAT-SYNTAX
     imports CPP-TYPING-EXPR-SYNTAX

     syntax ValResult ::= CandidateSet
     syntax CandidateSet ::= cSet(Map)
                           | classSet(Class, CId, Map)
                           | wrapInThis(CandidateSet)

     syntax Expr ::= wrapInThis(TypeExpr) [strict]

     syntax ImpliedObjArg ::= impliedObjArg(Class)
     syntax Expr ::= ImpliedObjArg

     syntax Expr ::= resolveOverload(CandidateSet, StrictList, StrictList, StrictList, CId, CId)
     syntax Expr ::= resolveUniqueDecl(K, Expr) [strict(1)]
     syntax Expr ::= cSetUnion(K, K) [strict]

endmodule

module CPP-OVERLOADING
     imports CPP-OVERLOADING-SYNTAX
     imports C-CONFIGURATION
     imports INT
     imports K-EQUAL
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DECL-TEMPLATE-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-REFERENCE-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TEMPLATE-DEDUCTION-SYNTAX
     imports CPP-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-VALUE-CATEGORY-SYNTAX
     imports CPP-CLASS-SYNTAX
     imports CPP-DECL-CLASS-SYNTAX

     rule cSetUnion(notFound(_), E::Expr) => E
     rule cSetUnion(E::Expr, notFound(_)) => E
     rule cSetUnion(cSet(M1::Map), cSet(M2::Map)) => cSet(M1 M2)

     context resolveOverload(_, _, (HOLE:StrictList => types(HOLE)), _, _, _)
     context resolveOverload(_, _, _, (HOLE:StrictList => cats(HOLE)), _, _)
     rule resolveOverload(cSet((T:CPPFunctionType |-> _ => .Map) _), list(Args::List), krlist(Types::List), krlist(Cats::List), _, _)
          requires (size(Args) >Int size(getRealParams(T)) andBool notBool isVariadicFunction(T)) orBool notViableTypes(getParams(T), Types, Cats)

     syntax Bool ::= notViableTypes(List, List, List) [function]
                   | viableType(CPPType, CPPType, ValueCategory) [function]

     rule notViableTypes(ListItem(P:CPPType) Ps::List, ListItem(A::CPPType) As::List, ListItem(C::ValueCategory) Cs::List) => notBool viableType(P, A, C) orBool notViableTypes(Ps, As, Cs)
     rule notViableTypes(ListItem(variadic), _, _) => false
     rule notViableTypes(.List, .List, .List) => false

     rule viableType(P::CPPType, A::CPPType, C::ValueCategory) => conversionSequence(P, A, C) =/=K cannot-convert

     rule canConvertWithStandardConversion(P::CPPType, A::CPPType, C::ValueCategory) => computeSCS(P, A, C) =/=K cannot-convert

     syntax ConversionSequence ::= CannotConvert
                                 | conversionSequence(CPPType, CPPType, ValueCategory) [function]
                                 | "ellipsisConversionSequence"
                                 | computeSCS(CPPType, CPPType, ValueCategory) [function]
                                 | computeSCS2(Conversion, CPPType, CPPType) [function]
                                 | computeSCS3(Conversion, Conversion, CPPType, CPPType) [function]
                                 | standardConversionSequence(Conversion, Conversion, Conversion)


     rule conversionSequence(P:CPPLVRefType, A::CPPType, lvalue) => standardConversionSequence(identity, identity, identity)
          requires notBool isCPPBitfieldType(A) andBool isReferenceCompatible(innerType(P), A) andBool notBool (isCPPClassType(innerType(P)) andBool isCPPClassType(A))
     rule conversionSequence(P:CPPRVRefType, A::CPPType, xvalue) => standardConversionSequence(identity, identity, identity)
          requires notBool isCPPBitfieldType(A) andBool isReferenceCompatible(innerType(P), A) andBool notBool (isCPPClassType(innerType(P)) andBool isCPPClassType(A))
     rule conversionSequence(P:CPPLVRefType, A::CPPType, _:RValueCategory) => cannot-convert
          requires notBool isCPPClassType(A) andBool getQuals(innerType(P)) =/=K quals(SetItem(Const()))

     rule conversionSequence(P:CPPType, A::CPPType, C::ValueCategory) => computeSCS(P, A, C)
          requires notBool isCPPRefType(P) andBool notBool isCPPClassType(P)
     rule computeSCS(P::CPPType, A::CPPType, _:GLValueCategory) => computeSCS2(lvalueConversion, P, prvalType(A))
          requires notBool isCPPFunctionType(A) andBool notBool isCPPArrayType(A)
     rule computeSCS(P::CPPType, A::CPPType, _:GLValueCategory) => computeSCS2(arrayConversion, P, type(pointerType(innerType(A))))
          requires isCPPArrayType(A)
     rule computeSCS(P::CPPType, A::CPPType, _:LValueCategory) => computeSCS2(functionConversion, P, type(pointerType(A)))
          requires isCPPFunctionType(A)
     rule computeSCS(P::CPPType, A::CPPType, prvalue) => computeSCS2(identity, P, A)
          requires notBool isCPPArrayType(A)
     rule computeSCS(_, _, _) => cannot-convert [owise]
     rule computeSCS2(C::Conversion, P:CPPIntegerType, A:CPPIntegerType) => computeSCS3(C, integralPromotion, P, A)
          requires promote(A) ==Type P
     rule computeSCS2(C::Conversion, P:CPPIntegerType, A:CPPUnscopedEnumType) => computeSCS3(C, integralPromotion, P, A)
          requires promote(A) ==Type P
     rule computeSCS2(C::Conversion, t(... st: double) #as P::CPPType, t(... st: float)) => computeSCS3(C, floatingPromotion, P, P)
     rule computeSCS2(C::Conversion, P:CPPIntegerType, A:CPPIntegerType) => computeSCS3(C, integralConversion, P, P)
          requires promote(A) =/=Type P andBool notBool isCPPBoolType(P)
     rule computeSCS2(C::Conversion, P:CPPIntegerType, A:CPPUnscopedEnumType) => computeSCS3(C, integralConversion, P, P)
          requires promote(A) =/=Type P andBool notBool isCPPBoolType(P)
     rule computeSCS2(C::Conversion, P:CPPFloatingType, A:CPPFloatingType) => computeSCS3(C, floatingConversion, P, P)
          requires notBool (simpleType(P) ==K double andBool simpleType(P) ==K float)
     rule computeSCS2(C::Conversion, P:CPPIntegerType, A:CPPFloatingType) => computeSCS3(C, floatingIntegralConversion, P, P)
     rule computeSCS2(C::Conversion, P:CPPFloatingType, A:CPPIntegerType) => computeSCS3(C, floatingIntegralConversion, P, P)
     rule computeSCS2(C::Conversion, P:CPPFloatingType, A:CPPUnscopedEnumType) => computeSCS3(C, floatingIntegralConversion, P, P)
     rule computeSCS2(C::Conversion, P:CPPPointerType, A:CPPIntegerType) => computeSCS3(C, pointerConversion, P, P)
     rule computeSCS2(C::Conversion, P:CPPPointerType, A:CPPNullPtrTType) => computeSCS3(C, pointerConversion, P, P)
     rule computeSCS2(C::Conversion, P:CPPNullPtrTType, A:CPPIntegerType) => computeSCS3(C, pointerConversion, P, P)
     rule computeSCS2(C::Conversion, t(... st: pointerType(t(... st: void))) #as P::CPPType, t(Q::Quals, Mods::Set, pointerType(t(Q'::Quals, Mods'::Set, _)))) 
          => computeSCS3(C, pointerConversion, P, t(Q, Mods, pointerType(t(Q', Mods', void))))
     rule computeSCS2(C::Conversion, t(... st: pointerType(t(... st: T:CPPSimpleClassType) #as B::CPPClassType)) #as P::CPPType, t(Q::Quals, Mods::Set, pointerType(t(Q'::Quals, Mods'::Set, _) #as D:CPPClassType)))
          => computeSCS3(C, pointerConversion, P, t(Q, Mods, pointerType(t(Q', Mods', T))))
          requires B =/=K D andBool isBaseClassOf(B, D)
     rule computeSCS2(C::Conversion, P:CPPMemberPointerType, A:CPPIntegerType) => computeSCS3(C, memberPointerConversion, P, P)
     rule computeSCS2(C::Conversion, P:CPPMemberPointerType, A:CPPNullPtrTType) => computeSCS3(C, memberPointerConversion, P, P)
     rule computeSCS2(C::Conversion, t(... st: memberPointerType(D:CPPClassType, t(... st: T::CPPSimpleType))) #as P::CPPType, t(Q::Quals, Mods::Set, memberPointerType(B:CPPClassType, t(Q'::Quals, Mods'::Set, T))))
          => computeSCS3(C, memberPointerConversion, P, t(Q, Mods, memberPointerType(D, t(Q', Mods', T))))
     rule computeSCS2(C::Conversion, P:CPPBoolType, A:CPPIntegerType) => computeSCS3(C, booleanConversion, P, P)
     rule computeSCS2(C::Conversion, P:CPPBoolType, A:CPPUnscopedEnumType) => computeSCS3(C, booleanConversion, P, P)
     rule computeSCS2(C::Conversion, P:CPPBoolType, A:CPPPointerType) => computeSCS3(C, booleanConversion, P, P)
     rule computeSCS2(C::Conversion, P:CPPBoolType, A:CPPMemberPointerType) => computeSCS3(C, booleanConversion, P, P)
     // this case includes the case when A is a BraceInit
     rule computeSCS2(C::Conversion, P::CPPType, A::CPPType)
          => computeSCS3(C, identity, P, A)
          requires utype(P) ==Type utype(A) orBool simpleType(A) ==K no-type
     rule computeSCS2(_, _, _) => cannot-convert [owise]
     rule computeSCS3(C1::Conversion, C2::Conversion, P::CPPType, A::CPPType)
          => standardConversionSequence(C1, C2, identity)
          requires cvQualificationSignature(P) ==K cvQualificationSignature(A)
     rule computeSCS3(C1::Conversion, C2::Conversion, P::CPPType, A::CPPType)
          => standardConversionSequence(C1, C2, qualificationConversion)
          requires cvQualificationSignature(A) <=QualSig cvQualificationSignature(P)
     rule computeSCS3(_, _, _, _) => cannot-convert [owise]

     syntax Conversion ::= "identity"
                         | "lvalueConversion" 
                         | "arrayConversion" 
                         | "functionConversion" 
                         | "qualificationConversion"
                         | "integralPromotion"
                         | "floatingPromotion"
                         | "integralConversion"
                         | "floatingConversion"
                         | "floatingIntegralConversion"
                         | "pointerConversion"
                         | "memberPointerConversion"
                         | "booleanConversion"

     // no overloading
     rule <k> resolveOverload(cSet(T::CPPType |-> kpair(_, Base::SymBase)), Args::StrictList, _, _, X::CId, operator()) 
              => CallExpr(lv(lnew(Base), hasTrace(Name(NoNNS(), X)), T), Args) ...</k>
          <odr-uses>... .Set => SetItem(Base) ...</odr-uses>
          requires notBool isCPPClassType(T)
               andBool Base =/=K nonStatic

     // no overloading -- static-method
     rule <k> resolveOverload(classSet(C::Class, X::CId, T::CPPType |-> kpair(_, Base::SymBase)), list(ListItem(impliedObjArg(_)) Args::List), _, _, _, operator()) 
              => CallExpr(lv(lnew(Base), hasTrace(Name(C, X)), T), list(Args)) ...</k>
          <odr-uses>... .Set => SetItem(Base) ...</odr-uses>
          requires notBool isCPPClassType(T)
               andBool Base =/=K nonStatic

     // no overloading -- non-static-method
     rule <k> resolveOverload(classSet(C::Class, X::CId, T::CPPFunctionType |-> kpair(_, Base::SymBase)), list(ListItem(Obj::Expr) Args::List), _, _, _, operator()) 
              => MethodCallExpr(& Obj, lv(lnew(Base), hasTrace(Name(C, X)), T), list(Args)) ...</k>
          <odr-uses>... .Set => SetItem(Base) ...</odr-uses>
          <class-id> C </class-id>
          <virtual-function-members> S::Set </virtual-function-members>
          requires notBool isCPPClassType(T)
               andBool Base =/=K nonStatic
               andBool notBool isImpliedObjArg(Obj)
               andBool notBool (kpair(X,T) in S)

      rule resolveOverload(cSet((T:CPPFunctionTypeExpr => adjustFunctionType(T)) |-> _:TemplateInfo), _, _, _, _, _)
          requires notBool isAdjustedType(T)

     rule <k> (.K => deduceTemplateFromCall(T, Args, .List, Q)) ~> resolveOverload(cSet((T:CPPFunctionTypeExpr |-> templateInfo(... id: Q::QualId) => .Map) _), list(Args::List), _, _, _, _) ...</k>
          <template-deduction> _ => .Map </template-deduction>

     syntax Conversion ::= "identity"
                         | "lvalueConversion" 
                         | "arrayConversion" 
                         | "functionConversion" 
                         | "qualificationConversion"
                         | "pointerConversion"

     // no overloading
     rule <k> resolveOverload(cSet(T::CPPType |-> kpair(_, Base::SymBase)), Args::StrictList, _, _, X::CId, operator()) 
              => CallExpr(lv(lnew(Base), hasTrace(Name(NoNNS(), X)), T), Args) ...</k>
          <odr-uses>... .Set => SetItem(Base) ...</odr-uses>
          requires notBool isCPPClassType(T)
               andBool Base =/=K nonStatic

     rule resolveOverload(cSet((T:CPPFunctionTypeExpr => adjustFunctionType(T)) |-> _:TemplateInfo), _, _, _, _, _)
          requires notBool isAdjustedType(T)

     rule <k> (.K => deduceTemplateFromCall(T, Args, .List, Q)) ~> resolveOverload(cSet((T:CPPFunctionTypeExpr |-> templateInfo(... id: Q::QualId) => .Map) _), list(Args::List), _, _, _, _) ...</k>
          <template-deduction> _ => .Map </template-deduction>
          requires isAdjustedType(T)

     rule (templateSpecialization(T:CPPType, I::TemplateInfo, Args::Map) => .K) ~> resolveOverload(cSet((.Map => T |-> templateSpecialization(T, I, Args)) _), _, _, _, _, _)

     rule (.K => instantiateObjectTemplate(Spec)) ~> resolveOverload(cSet(T::CPPType |-> Spec:TemplateSpecialization => .Map), _, _, _, _, _)

     rule (lv(loc(Base::SymBase, 0), _, T::CPPType) => .K) ~> resolveOverload(cSet(.Map => T |-> kpair(false, Base)), _, _, _, _, _)

     rule <k> resolveUniqueDecl(cSet(T::CPPType |-> kpair(_, Base::SymBase)), E::Expr) => lv(lnew(Base), hasTrace(E), T) ...</k>
          <odr-uses>... .Set => SetItem(Base) ...</odr-uses>
          requires Base =/=K nonStatic andBool notBool isCPPRefType(T)
     rule resolveUniqueDecl(cSet(T::CPPType |-> kpair(_, nonStatic)), E::Expr) => le(E, hasTrace(E), T)

     rule resolveUniqueDecl(wrapInThis(classSet(C::Class, X::CId, T::CPPType |-> classOffset(_))), E::Expr) => le((*This()) . no-template Name(C, X), hasTrace(E), T)
     rule resolveUniqueDecl(wrapInThis(classSet(_, _, (_ |-> kpair(_, _)) #as S::Map)) => cSet(S), _)
     rule resolveUniqueDecl(classSet(C::Class, X::CId, T::CPPType |-> _:ClassOffset), E::Expr)
       => dataMemberValue(memberPointer(C, X, T), hasTrace(E), T)
     rule resolveUniqueDecl(classSet(_, _, (_ |-> kpair(_, _)) #as S::Map) => cSet(S), _)

     rule <k> resolveUniqueDecl(cSet(T:CPPRefType |-> kpair(_, Base::SymBase)), E::Expr) => le(E, hasTrace(E), T) ...</k>
          <references> Refs::Map </references>
          requires notBool loc(Base, 0) in_keys(Refs)
     rule <k> resolveUniqueDecl(cSet(T:CPPRefType |-> kpair(_, Base::SymBase)), E::Expr) => lv(lnew(Base), hasTrace(E), T) ...</k>
          <references>... loc(Base, 0) |-> _ ...</references>

     rule resolveUniqueDecl(V:KResult, _) => V
          requires notBool isCandidateSet(V)

     rule wrapInThis(T:CPPType) => T
     rule catof(impliedObjArg(_) => prvalue)
     rule <k> typeof(impliedObjArg(C::Class) 
                  => #if isBaseClassOf(C, C') andBool notBool kpair(X, T) in S
                     #then t(getCVSQuals(T), .Set, classType(C'))
                     #else t(noQuals, .Set, classType(C))
                     #fi)
          ...</k>
          <curr-scope> blockScope(C'::Class :: X::CId, Base::SymBase, _) </curr-scope>
          <class-id> C' </class-id>
          <cenv>... X |-> ((T:CPPFunctionType |-> kpair(_, Base)) _::Map) ...</cenv>
          <static-function-members> S::Set </static-function-members>

     rule <k> typeof(impliedObjArg(C::Class) 
                  => t(noQuals, .Set, classType(C)))
          ...</k>
          <curr-scope> blockScope(N::Namespace :: X::CId, _, _) </curr-scope>

     rule <k> typeof(impliedObjArg(C::Class) 
                  => t(noQuals, .Set, classType(C)))
          ...</k>
          <curr-scope> Scope::Scope </curr-scope>
          requires notBool isBlockScope(Scope)



endmodule
