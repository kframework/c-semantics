module CPP-OVERLOADING-SYNTAX
     imports COMPAT-SYNTAX
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-EXPR-SYNTAX

     syntax ValResult ::= CandidateSet
     syntax CandidateSet ::= cSet(candidates: Map, id: QualId, this: K)

     syntax Expr ::= resolveOverload(CandidateSet, StrictList, Expr)
                   | resolveUniqueDecl(K, Expr) [strict(1)]
                   | cSetUnion(K, K) [strict]
                   | checkAccess(Expr)

     // not a real expression, but getArgs understands it.
     syntax Expr ::= "constructor"

     syntax CandidateSet ::= cSetUnion2(CandidateSet, CandidateSet) [function]

     syntax BuiltinOp ::= builtinOp(Expr)

endmodule

module CPP-OVERLOADING
     imports CPP-OVERLOADING-SYNTAX
     imports C-CONFIGURATION
     imports COMPAT
     imports INT
     imports STRING
     imports K-EQUAL
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DECL-INITIALIZER-SYNTAX
     imports CPP-DECL-TEMPLATE-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ENV-SYNTAX
     imports CPP-REFERENCE-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TEMPLATE-DEDUCTION-SYNTAX
     imports CPP-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-VALUE-CATEGORY-SYNTAX
     imports CPP-CLASS-SYNTAX
     imports CPP-DECL-CLASS-SYNTAX
     imports ERROR-SYNTAX

     // access checking stub (not implemented yet)
     rule checkAccess(E::Expr) => E

     rule resolveOverload(notFound(X::CId), _, _) => notFound(X)

     rule <k> resolveOverload(cSet(... id: Q::QualId) #as C::CandidateSet, list(Args::List), E::Expr)
              => #resolveOverload(C,
                   list(getArgs(Args, Q, E, Obj)),
                   list(getArgs(Args, Q, E, Obj)),
                   list(getArgs(Args, Q, E, Obj)),
                   E)
          ...</k>
          <this> Obj:K </this>

     syntax Expr ::= #resolveOverload(CandidateSet, StrictList, StrictList, StrictList, Expr)
     syntax List ::= getArgs(List, QualId, Expr, K) [function]
     // 13.3.1.1.1:2
     rule getArgs(Args::List, C:Class :: _, Obj::Expr . no-template _, _) 
          => ListItem(Obj) Args
     // 13.3.1.1.1:3 case (1)
     rule getArgs(Args::List, N:Namespace :: _, _, _) => Args
     // 13.3.1.1.1:3 case (2) when this is in scope
     rule getArgs(Args::List, C:Class :: _, _:Name, Obj:PRVal)
          => ListItem(* Obj) Args
          requires isBaseClassOf(type(classType(C)), {innerType(type(Obj))}:>CPPClassType)
     // 13.3.1.1.1:3 case (2) when this is not in scope
     rule getArgs(Args::List, C:Class :: _, _:Name, Obj::PRVal)
          => ListItem(contrivedObject(type(classType(C)))) Args
          requires Obj ==K .K orBool notBool isBaseClassOf(type(classType(C)), {innerType(type(Obj))}:>CPPClassType)
     // 13.3.1.2:6
     rule getArgs(Args::List, _, UnaryOperator(...), _) => Args
     rule getArgs(Args::List, _, BinaryOperator(...), _) => Args
     // 13.3.1.3:1
     rule getArgs(Args::List, _, constructor, _) => Args

     // strict version
     rule cSetUnion(notFound(_), E::Expr) => E
     rule cSetUnion(E::Expr, notFound(_)) => E
     rule cSetUnion(cSet(M1::Map, QX::QualId, Obj:K), cSet(M2::Map, QX, Obj)) => cSet(M1 M2, QX, Obj)

     // function version
     rule cSetUnion2(notFound(_), E::CandidateSet) => E
     rule cSetUnion2(E::CandidateSet, notFound(_)) => E
     rule cSetUnion2(cSet(M1::Map, QX::QualId, Obj:K), cSet(M2::Map, QX, Obj)) => cSet(M1 M2, QX, Obj)

     context #resolveOverload(_, _, (HOLE:StrictList => types(HOLE)), _, _)
     context #resolveOverload(_, _, _, (HOLE:StrictList => cats(HOLE)), _)
     rule #resolveOverload(cSet(... candidates: (T:CPPFunctionType |-> Entry:EnvEntry => .Map) _), list(Args::List), krlist(Types::List), krlist(Cats::List), _)
          requires notBool acceptsNArgs(size(Args), T, getDefaultArgs(Entry))
            orBool notViableTypes(T, getDefaultArgs(Entry), Types, Cats)

     syntax Bool ::= #notViableTypes(params: List, defaultArgs: List, types: List, cats: List, isNonStaticRefNone: Bool) [function]
                   | notViableTypes(CPPType, List, List, List) [function]
                   | viableType(CPPType, CPPType, ValueCategory) [function]
                   | viableImplicitObjectParameter(CPPType, CPPType, ValueCategory, isNonStaticRefNone: Bool) [function]

     rule notViableTypes(T::CPPFunctionType, DArgs::List, Types::List, Cats::List)
          => #notViableTypes(getParams(T), DArgs, Types, Cats, isFunctionMember(T) andBool notBool isMethodStatic(T) andBool getRefQualifier(T) ==K RefNone())
    
     rule #notViableTypes(ListItem(P:CPPType) Ps::List, ListItem(_) Args::List, ListItem(A::CPPType) As::List, ListItem(C::ValueCategory) Cs::List, B::Bool)
     => notBool viableType(P, A, C) orBool #notViableTypes(Ps, Args, As, Cs, B)
     rule #notViableTypes(ListItem(implicitObjectParameter(P:CPPType))  Ps::List, Args::List, ListItem(A::CPPType) As::List, ListItem(C::ValueCategory) Cs::List, B::Bool) 
     => notBool viableImplicitObjectParameter(P, A, C, B) orBool #notViableTypes(Ps, Args, As, Cs, B)
     rule #notViableTypes(... params: ListItem(variadic)) => false
     rule #notViableTypes(... params: .List, types: .List, cats: .List) => false
     // default arguments
     rule #notViableTypes(ListItem(P:CPPType) _, ListItem(Arg:Val) _, .List, .List, _) => false

     rule viableType(P::CPPType, A::CPPType, C::ValueCategory) => conversionSequence(P, A, C, false, false) =/=K cannot-convert

     rule viableImplicitObjectParameter(P:CPPRefType, A::CPPType, C::ValueCategory, B::Bool)
          => conversionSequence(P, A, C, B, true) =/=K cannot-convert
     rule viableImplicitObjectParameter(t(... st: no-type), _, _, _) => true

     rule canConvertWithStandardConversion(P::CPPType, A::CPPType, C::ValueCategory) => computeSCS(P, A, C, false) =/=K cannot-convert

     syntax ConversionSequence ::= CannotConvert
                                 | conversionSequence(CPPType, CPPDType, ValueCategory, isNonStaticRefNone: Bool, isImplicit: Bool) [function]
                                 | "ellipsisConversionSequence"
                                 | computeSCS(CPPType, CPPType, ValueCategory, isOverload: Bool) [function]
                                 | computeSCS2(Conversion, CPPType, CPPType, isOverload: Bool) [function]
                                 | computeSCS3(Conversion, Conversion, CPPType, CPPType) [function]
                                 | standardConversionSequence(Conversion, Conversion, Conversion)


     // 13.3.3.1.4:1 (identity conversion)
     rule conversionSequence(P:CPPRefType, A:CPPType, C::ValueCategory, B::Bool, _)
          => standardConversionSequence(identity, identity, identity)
          requires bindsDirectlyToExp(P, A, C, B)
               andBool notBool (isCPPClassType(innerType(P)) andBool isCPPClassType(A) 
                    andBool isBaseClassOf({innerType(P)}:>CPPClassType, {A}:>CPPClassType))
     rule conversionSequence(P:CPPRefType, A:CPPClassType, C::ValueCategory, B::Bool, _)
          => standardConversionSequence(identity, derivedToBaseConversion, identity)
          requires bindsDirectlyToExp(P, A, C, B) andBool isCPPClassType(innerType(P))
               andBool isBaseClassOf({innerType(P)}:>CPPClassType, A)
     rule conversionSequence(P:CPPRefType, A:CPPType, C::ValueCategory, false, false)
          => conversionSequence(innerType(P), A, C, false, false)
          requires notBool bindsDirectlyToExp(P, A, C, false)
               andBool notBool bindsDirectlyToConversion(P, A, C)
               andBool isValidReferenceType(P)
     rule conversionSequence(P:CPPRefType, A:CPPType, C::ValueCategory, false, false)
          => cannot-convert
          requires notBool bindsDirectlyToExp(P, A, C, false)
               andBool notBool bindsDirectlyToConversion(P, A, C)
               andBool notBool isValidReferenceType(P)
     // 13.3.1:5.1-5.2
     rule conversionSequence(P:CPPRefType, A:CPPType, C::ValueCategory, B::Bool, true)
          => cannot-convert
          requires notBool bindsDirectlyToExp(P, A, C, B)

     rule conversionSequence(P::CPPType, initListType(ListItem(A::CPPType)), initListCat(ListItem(C::ValueCategory)), false, false)
          => conversionSequence(P, A, C, false, false)
          requires notBool isCPPRefType(P) andBool notBool isCPPClassType(P) andBool notBool isCPPArrayType(P)
     rule conversionSequence(P::CPPType, initListType(.List), _, false, false)
          => standardConversionSequence(identity, identity, identity)
          requires notBool isCPPRefType(P) andBool notBool isCPPClassType(P) andBool notBool isCPPArrayType(P)
     rule conversionSequence(P::CPPType, initListType(L::List), _, false, false)
          => cannot-convert
          requires notBool isCPPRefType(P) andBool notBool isCPPClassType(P) andBool notBool isCPPArrayType(P)
               andBool size(L) >Int 1
          
     syntax Bool ::= bindsDirectlyToExp(CPPRefType, CPPType, ValueCategory, isNonStaticRefNone: Bool) [function]
                   | bindsDirectlyToConversion(CPPRefType, CPPType, ValueCategory) [function]

     rule bindsDirectlyToExp(t(... st: lvRefType(T1::CPPType)), T2::CPPType, lvalue, _) => true
          requires isReferenceCompatible(T1, T2)
     rule bindsDirectlyToExp(T::CPPRefType, T2::CPPType, xvalue, _) => true
          requires isReferenceCompatible(innerType(T), T2) andBool isValidReferenceType(T)
     rule bindsDirectlyToExp(T::CPPRefType, T2:CPPClassType, prvalue, _) => true
          requires isReferenceCompatible(innerType(T), T2) andBool isValidReferenceType(T)
     rule bindsDirectlyToExp(T::CPPRefType, T2:CPPArrayType, prvalue, _) => true
          requires isReferenceCompatible(innerType(T), T2) andBool isValidReferenceType(T)
     rule bindsDirectlyToExp(T::CPPRefType, T2:CPPFunctionType, lvalue, _) => true
          requires isReferenceCompatible(innerType(T), T2) andBool isValidReferenceType(T)
     rule bindsDirectlyToExp(t(... st: lvRefType(t(... q: Q::Quals => Q +Qual Const()))), _, _:RValueCategory, true => false)
     rule bindsDirectlyToExp(t(... st: rvRefType(t(... q: Q::Quals => Q +Qual Const()))), _, _:RValueCategory, true => false)
     rule bindsDirectlyToExp(...) => false [owise]

     rule bindsDirectlyToConversion(T::CPPRefType, T2::CPPType, C::ValueCategory) => false
          requires notBool (isCPPClassType(T2) andBool notBool isReferenceRelated(innerType(T), T2))
               orBool bindsDirectlyToExp(T, T2, C, false)

     rule conversionSequence(P::CPPType, A:CPPType, C::ValueCategory, false, false) => computeSCS(utype(P), utype(A), C, true)
          requires notBool isCPPRefType(P) 
               andBool ((notBool isCPPClassType(P) andBool notBool isCPPClassType(A))
                    orBool utype(A) ==Type utype(P)
                    orBool (isCPPClassType(A) andBool isCPPClassType(P) andBool isBaseClassOf({P}:>CPPClassType, {A}:>CPPClassType)))
     rule computeSCS(P::CPPType, A::CPPType, _:GLValueCategory, B::Bool) => computeSCS2(lvalueConversion, P, prvalType(A), B)
          requires notBool isCPPFunctionType(A) andBool notBool isCPPArrayType(A)
     rule computeSCS(P::CPPType, A::CPPType, _:GLValueCategory, B::Bool) => computeSCS2(arrayConversion, P, type(pointerType(innerType(A))), B)
          requires isCPPArrayType(A)
     rule computeSCS(P::CPPType, A::CPPType, _:LValueCategory, B::Bool) => computeSCS2(functionConversion, P, type(pointerType(A)), B)
          requires isCPPFunctionType(A)
     rule computeSCS(P::CPPType, A::CPPType, prvalue, B::Bool) => computeSCS2(identity, P, A, B)
          requires notBool isCPPArrayType(A)
     rule computeSCS(...) => cannot-convert [owise]
     rule computeSCS2(C::Conversion, P:CPPIntegerType, A:CPPIntegerType, _) => computeSCS3(C, integralPromotion, P, A)
          requires promote(A) ==Type P
     rule computeSCS2(C::Conversion, P:CPPIntegerType, A:CPPUnscopedEnumType, _) => computeSCS3(C, integralPromotion, P, A)
          requires promote(A) ==Type P
     rule computeSCS2(C::Conversion, t(... st: double) #as P::CPPType, t(... st: float), _) => computeSCS3(C, floatingPromotion, P, P)
     rule computeSCS2(C::Conversion, P:CPPIntegerType, A:CPPIntegerType, _) => computeSCS3(C, integralConversion, P, P)
          requires promote(A) =/=Type P andBool notBool isCPPBoolType(P)
     rule computeSCS2(C::Conversion, P:CPPIntegerType, A:CPPUnscopedEnumType, _) => computeSCS3(C, integralConversion, P, P)
          requires promote(A) =/=Type P andBool notBool isCPPBoolType(P)
     rule computeSCS2(C::Conversion, P:CPPFloatingType, A:CPPFloatingType, _) => computeSCS3(C, floatingConversion, P, P)
          requires notBool (simpleType(P) ==K double andBool simpleType(P) ==K float)
     rule computeSCS2(C::Conversion, P:CPPIntegerType, A:CPPFloatingType, _) => computeSCS3(C, floatingIntegralConversion, P, P)
     rule computeSCS2(C::Conversion, P:CPPFloatingType, A:CPPIntegerType, _) => computeSCS3(C, floatingIntegralConversion, P, P)
     rule computeSCS2(C::Conversion, P:CPPFloatingType, A:CPPUnscopedEnumType, _) => computeSCS3(C, floatingIntegralConversion, P, P)
     rule computeSCS2(C::Conversion, P:CPPPointerType, A:CPPIntegerType, _) => computeSCS3(C, pointerConversion, P, P)
     rule computeSCS2(C::Conversion, P:CPPPointerType, A:CPPNullPtrTType, _) => computeSCS3(C, pointerConversion, P, P)
     rule computeSCS2(C::Conversion, P:CPPNullPtrTType, A:CPPIntegerType, _) => computeSCS3(C, pointerConversion, P, P)
     rule computeSCS2(C::Conversion, t(... st: pointerType(t(... st: void))) #as P::CPPType, t(Q::Quals, Mods::Set, pointerType(t(Q'::Quals, Mods'::Set, _))), _) 
          => computeSCS3(C, pointerConversion, P, t(Q, Mods, pointerType(t(Q', Mods', void))))
     rule computeSCS2(C::Conversion, t(... st: pointerType(t(... st: T:CPPSimpleClassType) #as B::CPPClassType)) #as P::CPPType, t(Q::Quals, Mods::Set, pointerType(t(Q'::Quals, Mods'::Set, _) #as D:CPPClassType)), _)
          => computeSCS3(C, pointerConversion, P, t(Q, Mods, pointerType(t(Q', Mods', T))))
          requires B =/=K D andBool isBaseClassOf(B, D)
     rule computeSCS2(C::Conversion, P:CPPMemberPointerType, A:CPPIntegerType, _) => computeSCS3(C, memberPointerConversion, P, P)
     rule computeSCS2(C::Conversion, P:CPPMemberPointerType, A:CPPNullPtrTType, _) => computeSCS3(C, memberPointerConversion, P, P)
     rule computeSCS2(C::Conversion, t(... st: memberPointerType(D:CPPClassType, t(... st: T::CPPSimpleType))) #as P::CPPType, t(Q::Quals, Mods::Set, memberPointerType(B:CPPClassType, t(Q'::Quals, Mods'::Set, T))), _)
          => computeSCS3(C, memberPointerConversion, P, t(Q, Mods, memberPointerType(D, t(Q', Mods', T))))
     rule computeSCS2(C::Conversion, P:CPPBoolType, A:CPPIntegerType, _) => computeSCS3(C, booleanConversion, P, P)
     rule computeSCS2(C::Conversion, P:CPPBoolType, A:CPPUnscopedEnumType, _) => computeSCS3(C, booleanConversion, P, P)
     rule computeSCS2(C::Conversion, P:CPPBoolType, A:CPPPointerType, _) => computeSCS3(C, booleanConversion, P, P)
     rule computeSCS2(C::Conversion, P:CPPBoolType, A:CPPMemberPointerType, _) => computeSCS3(C, booleanConversion, P, P)
     rule computeSCS2(C::Conversion, P::CPPType, A::CPPType, _)
          => computeSCS3(C, identity, P, A)
          requires utype(P) ==Type utype(A)
     rule computeSCS2(C::Conversion, P:CPPClassType, A:CPPClassType, true)
          => computeSCS3(C, derivedToBaseConversion, P, A)
          requires isBaseClassOf(P, A)
     rule computeSCS2(...) => cannot-convert [owise]
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
                         | "derivedToBaseConversion"

     // do not actually perform overload resolution, this was a function call
     // in which the postfix expression was a function pointer
     rule <k> #resolveOverload(cSet(... candidates: T:CPPPointerType |-> envEntry(... base: Base::SymBase)), list(Args::List), _, _, E::Expr)
              => checkAccess(CallExpr(lv(lnew(Base), hasTrace(E), T), list(Args), emptyDefaultArguments(innerType(T)))) ...</k>
          <odr-uses>... .Set => SetItem(Base) ...</odr-uses>
          requires isCPPFunctionType(innerType(T)) andBool Base =/=K nonStatic
     rule #resolveOverload(cSet(... candidates: T:CPPPointerType |-> envEntry(... base: nonStatic)), list(Args::List), _, _, E::Expr)
          => checkAccess(CallExpr(le(E, hasTrace(E), T), list(Args), emptyDefaultArguments(innerType(T))))
          requires isCPPFunctionType(innerType(T))

     // only one viable candidate
     rule <k> #resolveOverload(cSet(... candidates: T:CPPFunctionType |-> envEntry(... base: Base::SymBase, defaultArgs: krlist(DArgs::List))), list(Args::List), krlist(Types::List), krlist(Cats::List), E::Expr) 
              => checkAccess(CallExpr(lv(lnew(Base), hasTrace(E), T), list(Args), krlist(DArgs))) ...</k>
          <odr-uses>... .Set => SetItem(Base) ...</odr-uses>
          requires Base =/=K nonStatic
               andBool acceptsNArgs(size(Args), T, DArgs)
               andBool notBool notViableTypes(T, DArgs, Types, Cats)

     rule #resolveOverload(cSet(... candidates: T:CPPFunctionType |-> builtinOp(E::Expr)), list(Args::List), krlist(Types::List), krlist(Cats::List), _) => E
          requires acceptsNArgs(size(Args), T, Args) andBool notBool notViableTypes(T, Args, Types, Cats)

      // no viable candidates
      // normally this is ill formed, but it can be well formed in some cases such as operator overloading of certain operators
      rule #resolveOverload(cSet(... candidates: .Map, id: X::QualId), _, _, _, _) => notFound(getId(X))

      rule #resolveOverload(cSet(... candidates: (T:CPPFunctionTypeExpr => adjustFunctionType(T)) |-> _:TemplateInfo), _, _, _, _)
          requires notBool isAdjustedType(T)

     rule <k> (.K => deduceTemplateFromCall(T, Args, .List, Q)) ~> #resolveOverload(cSet(... candidates: (T:CPPFunctionTypeExpr |-> templateInfo(... id: Q::QualId) => .Map) _), list(Args::List), _, _, _) ...</k>
          <template-deduction> _ => .Map </template-deduction>
          requires isAdjustedType(T)

     rule (templateSpecialization(T:CPPType, I::TemplateInfo, Args::Map) => .K) ~> #resolveOverload(cSet(... candidates: (.Map => T |-> templateSpecialization(T, I, Args)) _), _, _, _, _)

     rule (.K => instantiateObjectTemplate(Spec)) ~> #resolveOverload(cSet(... candidates: T::CPPType |-> Spec:TemplateSpecialization => .Map), _, _, _, _)

     // TODO(traiansf): properly resolve default arguments for templates
     rule (lv(loc(Base::SymBase, 0), _, T::CPPType) => .K) ~> #resolveOverload(cSet(... candidates: .Map => T |-> envEntry(Base, false, emptyDefaultArguments(T))), _, _, _, _)

     rule <k> resolveUniqueDecl(cSet(... candidates: T::CPPType |-> envEntry(... base: Base::SymBase)), E::Expr) => lv(lnew(Base), hasTrace(E), T) ...</k>
          <odr-uses>... .Set => SetItem(Base) ...</odr-uses>
          requires Base =/=K nonStatic
           andBool notBool isCPPRefType(T)
           andBool notBool isMemberBase(Base)
     rule resolveUniqueDecl(cSet(... candidates: T::CPPType |-> envEntry(... base: nonStatic)), E::Expr) => le(E, hasTrace(E), T)
     // resolve anonymous union member lookup
     rule resolveUniqueDecl(cSet(... candidates: _ |-> envEntry(... base: memberBase(unnamedObject(C::Class), X::CId, _))), _) => Name(NoNNS(), unnamedObject(C)) . no-template Name(NoNNS(), X)

     rule resolveUniqueDecl(cSet(T::CPPType |-> classOffset(_), C:Class :: X::CId, This()), E::Expr) => le((*This()) . no-template Name(C, X), hasTrace(E), T)
     rule resolveUniqueDecl(cSet(T::CPPType |-> _:ClassOffset, C:Class :: X::CId, .K), E::Expr)
       => dataMemberValue(memberPointer(C, X, T), hasTrace(E), T)

     rule <k> resolveUniqueDecl(cSet(... candidates: T:CPPRefType |-> envEntry(... base: Base::SymBase)), E::Expr) => le(E, hasTrace(E), T) ...</k>
          <references> Refs::Map </references>
          requires notBool loc(Base, 0) in_keys(Refs)
     rule <k> resolveUniqueDecl(cSet(... candidates: T:CPPRefType |-> envEntry(... base: Base::SymBase)), E::Expr) => lv(lnew(Base), hasTrace(E), T) ...</k>
          <references>... loc(Base, 0) |-> _ ...</references>

     rule resolveUniqueDecl(V:KResult, _) => V
          requires notBool isCandidateSet(V) andBool notBool isNotFoundNameRef(V)

     rule (.K => ILL("TOL1", "No declaration found for name '" +String idToString(X) +String "'.")) ~> resolveUniqueDecl(notFound(X::CId), _)

     // NOTE: the category of the contrivedObject is defaulted to lvalue as its value does not matter, as  the conversion sequence for the implicit object parameter will be ignored in this case 
     // See also 13.3.3.1.4:3 http://www.open-std.org/jtc1/sc22/wg21/docs/cwg_active.html#1278
     rule catof(contrivedObject(_) => lvalue)
     rule typeof(contrivedObject(T::CPPType) => T)

     rule contrivedObject(T::CPPType) => noObject()
endmodule
