module CPP-OVERLOADING-SYNTAX
     imports COMPAT-SYNTAX

     syntax ValResult ::= CandidateSet
     syntax CandidateSet ::= cSet(Map)
     syntax Expr ::= resolveOverload(CandidateSet, StrictList, StrictList, StrictList, CId, CId)
     syntax Expr ::= resolveUniqueDecl(K, Expr) [strict(1)]

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
     rule computeSCS2(C::Conversion, P::CPPType, A::CPPType) => computeSCS3(C, identity, P, A)
          requires cvQualificationSignature(P) ==K cvQualificationSignature(A)
     rule computeSCS2(C::Conversion, P:CPPPointerType, A:CPPPointerType) => computeSCS3(C, qualificationConversion, P, A)
          requires cvQualificationSignature(A) <=QualSig cvQualificationSignature(P)
     // this case includes the case when A is a BraceInit
     rule computeSCS3(C1::Conversion, C2::Conversion, P::CPPType, A::CPPType)
          => standardConversionSequence(C1, C2, identity)
          requires P ==Type A orBool simpleType(A) ==K no-type
     rule computeSCS3(C1::Conversion, C2::Conversion, t(_, _, pointerType(t(_, _, void))), t(_, _, pointerType(t(_, _, _))))
          => standardConversionSequence(C1, C2, pointerConversion)
     rule computeSCS3(C1::Conversion, C2::Conversion, P:CPPIntegerType, A:CPPIntegerType)
          => standardConversionSequence(C1, C2, integralConversion)
          requires promote(A) =/=Type P
     rule computeSCS3(C1::Conversion, C2::Conversion, P:CPPIntegerType, A:CPPIntegerType)
          => standardConversionSequence(C1, C2, integralPromotion)
          requires promote(A) ==Type P

     syntax Conversion ::= "identity"
                         | "lvalueConversion" 
                         | "arrayConversion" 
                         | "functionConversion" 
                         | "qualificationConversion"
                         | "integralPromotion"
                         | "integralConversion"
                         | "pointerConversion"

     // no overloading
     rule <k> resolveOverload(cSet(T::CPPType |-> kpair(_, Base::SymBase)), Args::StrictList, _, _, X::CId, operator()) 
              => CallExpr(lv(lnew(Base, T), hasTrace(Name(NoNNS(), X)), T), Args) ...</k>
          <odr-uses>... .Set => SetItem(Base) ...</odr-uses>
          requires notBool isCPPClassType(T)
               andBool Base =/=K nonStatic

     rule resolveOverload(cSet((T:CPPFunctionTypeExpr => adjustFunctionType(T)) |-> _:TemplateInfo), _, _, _, _, _)
          requires notBool isAdjustedType(T)

     rule <k> (.K => deduceTemplateFromCall(T, Args, .List, Q)) ~> resolveOverload(cSet((T:CPPFunctionTypeExpr |-> templateInfo(Q::QualId, Decls::List, Types::Map, Defaults::Map, _, _) => .Map) _), list(Args::List), _, _, _, _) ...</k>
          <template-deduction> _ => .Map </template-deduction>

     syntax Conversion ::= "identity"
                         | "lvalueConversion" 
                         | "arrayConversion" 
                         | "functionConversion" 
                         | "qualificationConversion"
                         | "pointerConversion"

     // no overloading
     rule <k> resolveOverload(cSet(T::CPPType |-> kpair(_, Base::SymBase)), Args::StrictList, _, _, X::CId, operator()) 
              => CallExpr(lv(lnew(Base, T), hasTrace(Name(NoNNS(), X)), T), Args) ...</k>
          <odr-uses>... .Set => SetItem(Base) ...</odr-uses>
          requires notBool isCPPClassType(T)
               andBool Base =/=K nonStatic

     rule resolveOverload(cSet((T:CPPFunctionTypeExpr => adjustFunctionType(T)) |-> _:TemplateInfo), _, _, _, _, _)
          requires notBool isAdjustedType(T)

     rule <k> (.K => deduceTemplateFromCall(T, Args, .List, Q)) ~> resolveOverload(cSet((T:CPPFunctionTypeExpr |-> templateInfo(Q::QualId, Decls::List, Types::Map, Defaults::Map, _, _) => .Map) _), list(Args::List), _, _, _, _) ...</k>
          <template-deduction> _ => .Map </template-deduction>
          requires isAdjustedType(T)

     rule (templateSpecialization(T:CPPType, I::TemplateInfo, Args::Map) => .K) ~> resolveOverload(cSet((.Map => T |-> templateSpecialization(T, I, Args)) _), _, _, _, _, _)

     rule (.K => instantiateObjectTemplate(Spec)) ~> resolveOverload(cSet(T::CPPType |-> Spec:TemplateSpecialization => .Map), _, _, _, _, _)

     rule (lv(loc(Base::SymBase, 0, _), _, T::CPPType) => .K) ~> resolveOverload(cSet(.Map => T |-> kpair(false, Base)), _, _, _, _, _)

     rule <k> resolveUniqueDecl(cSet(T::CPPType |-> kpair(_, Base::SymBase)), E::Expr) => lv(lnew(Base, T), hasTrace(E), T) ...</k>
          <odr-uses>... .Set => SetItem(Base) ...</odr-uses>
          requires Base =/=K nonStatic andBool notBool isCPPRefType(T)
     rule resolveUniqueDecl(cSet(T::CPPType |-> kpair(_, nonStatic)), E::Expr) => le(E, hasTrace(E), T)
     rule <k> resolveUniqueDecl(cSet(T:CPPRefType |-> kpair(_, Base::SymBase)), E::Expr) => le(E, hasTrace(E), T) ...</k>
          <references> Refs::Map </references>
          requires notBool loc(Base, 0) in_keys(Refs)
     rule <k> resolveUniqueDecl(cSet(T:CPPRefType |-> kpair(_, Base::SymBase)), E::Expr) => lv(lnew(Base, T), hasTrace(E), T) ...</k>
          <references>... loc(Base, 0) |-> _ ...</references>
     rule resolveUniqueDecl(V:KResult, _) => V
          requires notBool isCandidateSet(V)

endmodule
