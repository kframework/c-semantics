module CPP-TRANSLATION-DECL-ENUM-SYNTAX
     imports BOOL-SYNTAX
     imports LIST
     imports COMMON-SORTS
     imports CPP-SORTS
     imports CPP-TYPING-SYNTAX
endmodule

module CPP-TRANSLATION-DECL-ENUM
     imports CPP-TRANSLATION-DECL-ENUM-SYNTAX
     imports C-CONFIGURATION
     imports COMMON-SYNTAX
     imports COMPAT-SYNTAX
     imports CPP-TRANSLATION-CONSTANT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TRANSLATION-ENV-SYNTAX
     imports CPP-ERROR-SYNTAX
     imports CPP-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports INT
     imports STRING

     rule <k> EnumDef(X::CId, NoNNS(), Scoped::Bool, Fixed::Bool, UT::CPPType, Enumerators::List)
          => enumContext(X, declareEnumName(createEnumName(X, Sc), UT, Scoped, Fixed), Enumerators, Fixed, UT, false) ...</k>
          <curr-tr-scope> Sc::Scope </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>

     syntax Enum ::= createEnumName(CId, Scope) [function]

     rule createEnumName(X::CId, namespaceScope(N::Namespace)) => N :: Enum(X)

     rule createEnumName(X::CId, classScope(C::Class, _)) => C :: Enum(X)

     rule createEnumName(X::CId, blockScope(_, _, _) #as B::BlockScope) => localQual(B) :: Enum(X)

     syntax CPPType ::= declareEnumName(Enum, ut: CPPType, scoped: Bool, fixed: Bool) [function]

     rule declareEnumName(E::Enum, UT::CPPType, false, Fixed:Bool) => t(noQuals, .Set, unscopedEnum(E, UT, Fixed))

     rule declareEnumName(E::Enum, UT::CPPType, true, true)  => t(noQuals, .Set, scopedEnum(E, UT))

     syntax NNSVal ::= getEnumQualifier(Enum) [function]

     rule getEnumQualifier(N:Namespace :: _) => N

     rule getEnumQualifier(C:Class :: _) => C

     rule getEnumQualifier(localQual(_) :: _) => NoNamespace()

     syntax KItem ::= addEnumToEnv(CId, CPPType)

     rule addEnumToEnv(X::CId, E::CPPType) => #addEnumToEnv(X, getEnumQualifier(getEnumId(E)), E)

     syntax KItem ::= #addEnumToEnv(CId, NNSVal, CPPType)

     rule <k> #addEnumToEnv(X::CId, N::Namespace, E::CPPType) => . ... </k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <ntypes> NT::Map => NT[X <- E] </ntypes>

     rule <k> #addEnumToEnv(X::CId, C::Class, E::CPPType) => . ... </k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <ctypes> NT::Map => NT[X <- E] </ctypes>

     rule <k> #addEnumToEnv(X::CId, NoNamespace(), E::CPPType) => . ... </k>
          <tr-types> NT::Map => NT[X <- E] </tr-types>


     syntax KItem ::= enumContext(CId, CPPType, List, fixed: Bool, ut: CPPType, opaque: Bool)

     rule enumContext(X::CId, E::CPPType, Enumerators:List, Fixed::Bool, _UT::CPPType, Opaque:Bool)
          => newEnum(getEnumId(E), E, Fixed, Opaque)
          ~> addEnumToEnv(X, E)
          ~> #if Opaque #then .K #else inEnumScope(E, declareEnumerators(E, 0, 0, 0, int, Enumerators, Fixed, true)) #fi

     syntax KItem ::= inEnumScope(CPPType, K)

     rule <k> inEnumScope(E::CPPType, K:K) => K ~> setScope(OldScope) ... </k>
          <curr-tr-scope> OldScope::Scope => enumScope(getEnumId(E))  </curr-tr-scope>


     syntax KItem ::= newEnum(Enum, CPPType, fixed: Bool, opaque: Bool)

     rule <k> newEnum(EI::Enum, cppEnumType #as E::CPPType, true, Opaque::Bool) => . ... </k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          (.Bag => <cppenum>...
               <enum-id> EI </enum-id>
               <enum-type> E </enum-type>
               <scoped> isEnumScoped(E) </scoped>
               <enum-complete> true </enum-complete>
               <enum-opaque> Opaque </enum-opaque>
               <enum-min> min(underlyingType(E)) </enum-min>
               <enum-max> max(underlyingType(E)) </enum-max>
           ...</cppenum>)
          requires getEnumInfo(E) ==K #incomplete

     rule <k> newEnum(EI::Enum, t(... st: _:CPPSimpleUnscopedEnumType) #as E::CPPType, false, false) => . ... </k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          (.Bag => <cppenum>...
               <enum-id> EI </enum-id>
               <enum-type> E </enum-type>
               <scoped> false </scoped>
               <enum-opaque> false </enum-opaque>
               <enum-complete> false </enum-complete>
           ...</cppenum>)

     // Redeclaration
     rule <k> newEnum(EI::Enum, cppEnumType #as E1::CPPType, true, Opaque:Bool) => . ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <enum-id> EI </enum-id>
          <enum-type> cppEnumType #as E2::CPPType </enum-type>
          <enum-opaque> OldOpaque:Bool => OldOpaque andBool Opaque </enum-opaque>
          requires E1 ==K E2

     rule <k> (.K => ILL("TDE5", "A scoped/unscoped enumeration shall not be later redeclared as unscoped/scoped or with a different underlying type")) ~>
               newEnum(EI::Enum, cppEnumType #as E1::CPPType, true, _) ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <enum-id> EI </enum-id>
          <enum-type> cppEnumType #as E2::CPPType </enum-type>
          requires E1 =/=K E2

     syntax DeclareEnumerators ::= declareEnumerators(CPPType, min: Int, max: Int, next: Int, prevType: CPPSimpleType, enums: List, fixed: Bool, first: Bool)

     rule (.K => C) ~> declareEnumerators(... enums: ListItem(DeclLoc(C::CabsLoc, D::Decl) => D) _)

     // First enumerator, fixed underlying type.
     rule declareEnumerators(E::CPPType, _, _, _, _, ListItem(Enumerator(_, NoExpression() => prv(0, noTrace, underlyingType(E)))) _::List, true, true)

     // First enumerator, underlying type not fixed
     rule (.K => UNSPEC("TDE2", "No initializer specified for the first enumerator, underlying type of enumerator is unspecified.")) ~> (
          declareEnumerators(E::CPPType, Min::Int, Max::Int, Next::Int, PrevType::CPPSimpleType, ListItem(Enumerator(X::CId, NoExpression())) L::List, false, true)
          => recoverFromError(
          declareEnumerators(E, Min, Max, Next, PrevType, ListItem(Enumerator(X, prv(0, noTrace, type(int)))) L, false, true)
          ))

     // Second or more enumerator, fixed underlying type
     rule declareEnumerators(E::CPPType, _, _, Next::Int, _,
               ListItem(Enumerator(_, NoExpression() => prv(Next, noTrace, underlyingType(E)))) _::List, true, false)

     // Second or more enumerator, underlying type not fixed, value fits.
     rule declareEnumerators(_, _, _, Next::Int, PrevType::CPPSimpleType,
               ListItem(Enumerator(_, NoExpression() => prv(Next, noTrace, type(PrevType)))) _::List, false, false)
          requires inRange(Next, type(PrevType))

     // Second or more enumerator, underlype type not fixed, value does not fit to previous type but fits to some.
     rule (.K => UNSPEC("TDE3", "Value does not fit to type of preceding enumerator.")) ~> (
          declareEnumerators(E::CPPType, Min::Int, Max::Int, Next::Int, PrevType::CPPSimpleType, ListItem(Enumerator(X::CId, NoExpression())) L::List, false, false)
          => recoverFromError(
          declareEnumerators(E, Min, Max, Next::Int, PrevType, ListItem(Enumerator(X, prv(Next, noTrace, type(firstSuitableType(Next, Next, allIntegralTypes))))) L, false, false)
          ))
          requires notBool inRange(Next, type(PrevType)) andBool firstSuitableType(Next, Next, allIntegralTypes) =/=K no-type

     rule (.K => ILL("TDE4", "Incremented enumerator value is not representable in any integer type.")) ~>
          declareEnumerators(_, _, _, Next::Int, PrevType::CPPSimpleType, ListItem(Enumerator(_, NoExpression())) _::List, false, false)
          requires notBool inRange(Next, type(PrevType)) andBool firstSuitableType(Next, Next, allIntegralTypes) ==K no-type

     rule declareEnumerators(_, _, _, _, _, ListItem(Enumerator(_, prv(_, _, t(... st: _:CPPSimpleUnscopedEnumType) #as T::CPPType => underlyingType(T)))) _::List, _, _)

     context declareEnumerators(_, _, _, _, _, ListItem(Enumerator(_, HOLE:Expr => reval(HOLE))) _::List, _, _) [result(PRVal)]

     context declareEnumerators(_, _, _, _, _, ListItem(Enumerator(_, HOLE:PRVal => evalCoreConstantExpressionUntil(reval(HOLE), isRevalDone))) _::List, _, _) [result(PRV)]

     syntax Predicate ::= "isRevalDone"

     rule isRevalDone(reval(prv(...))) => true

     rule isRevalDone(_) => false [owise]

     // Type of an enumerator inside the declaration is enum's underlying type
     // if it is fixed, and type of initializing expression otherwise,
     // Hence we need to store the type of underlying expression...
     rule declareEnumerators(T::CPPType, Min::Int, Max::Int, _Next::Int, _, ListItem(Enumerator(X::CId, prv(V::Int, _, t(_, _, EType:CPPSimpleType)) #as Pr::PRVal)) L::List, Fixed:Bool, First:Bool)
          => declareEnumerator(getEnumId(T), X, Pr, Fixed, underlyingType(T))
          ~> declareEnumerators(T, #if First #then V #else minInt(Min, V) #fi, #if First #then V #else maxInt(Max, V) #fi, V +Int 1, EType, L, Fixed, false)
     requires notBool isCPPSimpleUnscopedEnumType(EType)

     // Enums with fixed underlying type are finished by now.
     rule declareEnumerators(_::CPPType, _, _, _, _, .List, true, _) => .

     rule declareEnumerators(T::CPPType, Min::Int, Max::Int, _, _, .List, false, _) => calculateEnumValues(T, Min, Max)


     syntax KItem ::= declareEnumerator(Enum, CId, PRVal, fixed: Bool, ut: CPPType)

     // Not fixed
     rule declareEnumerator(E::Enum, X::CId, prv(_,_,_) #as Pr::PRVal, false, _) => addEnumerator(E, X, Pr)

     // Fixed enumerator.
     rule declareEnumerator(E::Enum, X::CId, prv(V::CPPValue, Tr::Trace, _), true, UT::CPPType) => addEnumerator(E, X, prv(V, Tr, UT))
     requires inRange(V, UT)

     rule (.K => ILL("TDE1", "Value of enumerator '" +String showCId(X) +String "' does not fit to fixed underlying type.")) ~> declareEnumerator(_, X::CId, prv(V::CPPValue, _, _), true, UT::CPPType)
          requires notBool inRange(V, UT)

     syntax KItem ::= addEnumerator(enum: Enum, id: CId, v: PRVal)

     rule <k> addEnumerator(E::Enum, X::CId, V::PRVal) => addEnumeratorToEnv(E, X) ... </k>
         <enum-id> E </enum-id>
         <enumerators> ES::Map => ES[X <- V] </enumerators>

     syntax KItem ::= addEnumeratorToEnv(Enum, CId)

     rule <k> addEnumeratorToEnv(E::Enum, _) => . ... </k>
          <enum-id> E </enum-id>
          <scoped> true </scoped>

     rule <k> addEnumeratorToEnv(Q::ClassQualifier :: Enum(_) #as EId::Enum, X::CId) => addUnscopedEnumerator(X, EId, Q) ...</k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <enum-id> EId </enum-id>
          <scoped> false </scoped>

     syntax KItem ::= addUnscopedEnumerator(CId, Enum, ClassQualifier)

     rule <k> addUnscopedEnumerator(X::CId, E::Enum, N::Namespace) => . ... </k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenums>... .Map => X |-> E ...</nenums>

     rule <k> addUnscopedEnumerator(X::CId, E::Enum, C::Class) => . ... </k>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <cenums>... .Map => X |-> E ...</cenums>

     rule <k> addUnscopedEnumerator(X::CId, E::Enum, localQual(_)) => . ... </k>
          <enums>... .Map => X |-> E ...</enums>

     // For unscoped enums without fixed type,
     // compute their minimal and maximal value
     // as well as their underlying type

     // Possible underlying types according to 7.2:7
     syntax List ::= "integralTypesGreaterThanInt" [function]

     rule integralTypesGreaterThanInt
          => ListItem(int)
             ListItem(unsigned)
             ListItem(long)
             ListItem(unsigned-long)
             ListItem(long-long)
             ListItem(oversized)
             ListItem(unsigned-long-long)
             ListItem(unsigned-oversized)

     syntax List ::= "allIntegralTypes" [function]

     rule allIntegralTypes
          => ListItem(signed-char)
             ListItem(unsigned-char)
             ListItem(short)
             ListItem(unsigned-short)
             integralTypesGreaterThanInt

     syntax CPPSimpleType ::= firstSuitableType(Int, Int, List) [function]

     rule firstSuitableType(Min::Int, Max::Int, ListItem(T::CPPSimpleType) _) => T
          requires Min >=Int min(type(T)) andBool Max <=Int max(type(T))

     rule firstSuitableType(_, _, .List) => no-type

     rule firstSuitableType(_, _, (ListItem(_) => .List) _) [owise]


     syntax CalculateEnumValues ::= calculateEnumValues(CPPType, min: Int, max: Int)

     syntax Int ::= calculateMaxEnumValue(emin: Int, emax: Int) [function]

     syntax Int ::= calculateMinEnumValue(emin: Int, emax: Int) [function]

     rule calculateMinEnumValue(EMin::Int, _) => 0
     requires EMin >=Int 0

     rule calculateMinEnumValue(EMin::Int, EMax::Int) => 0 -Int (calculateMaxEnumValue(EMin, EMax) +Int 1) [owise]

     rule calculateMaxEnumValue(EMin::Int, EMax::Int) => firstGreaterThanOrEqualTo(0, maxInt(absInt(EMin) -Int 1, absInt(EMax)))


     syntax Int ::= firstGreaterThanOrEqualTo(exp: Int, tresh: Int) [function]

     rule firstGreaterThanOrEqualTo(Exp::Int, Tresh::Int) => (1 <<Int Exp) -Int 1
     requires ((1 <<Int Exp) -Int 1) >=Int Tresh

     rule firstGreaterThanOrEqualTo(Exp::Int, Tresh::Int) => firstGreaterThanOrEqualTo(Exp +Int 1, Tresh) [owise]

     rule calculateEnumValues(T::CPPType, Min::Int, Max::Int) => computeEnumUt(T, calculateMinEnumValue(Min, Max), calculateMaxEnumValue(Min, Max))

     syntax ComputeEnumUt ::= computeEnumUt(CPPType, min: Int, max: Int)

     // TODO(h0nzZik): packed enums
     rule computeEnumUt(T::CPPType, Min::Int, Max::Int) => setEnumMinMaxUt(T, Min, Max, type(firstSuitableType(Min, Max, integralTypesGreaterThanInt)))

     syntax SetEnumMinMaxUt ::= setEnumMinMaxUt(CPPType, min: Int, max: Int, ut: CPPType)

     rule <k> setEnumMinMaxUt(t(_, _, unscopedEnum(_ :: Enum(X::CId) #as E::Enum, _, Fixed:Bool)) #as _::CPPType, Min::Int, Max::Int, cppIntegerType #as UT::CPPType)
          => addEnumToEnv(X, t(noQuals, .Set, unscopedEnum(E, UT, Fixed))) ... </k>
          <enum-id> E </enum-id>
          <enum-type> _ => t(noQuals, .Set, unscopedEnum(E, UT, Fixed)) </enum-type>
          <enum-min> _ => Min </enum-min>
          <enum-max> _ => Max </enum-max>
          <enum-complete> _ => true </enum-complete>


     // @ref n4296 7.2/3: ... An opaque-enum-declaration is either a redeclaration of an enumeration in the current scope...
     rule <k> OpaqueEnumDeclaration(X::CId, _Scoped::Bool, _UT::CPPType) => . ...</k>
          <curr-tr-scope> namespaceScope(N::Namespace) </curr-tr-scope>
          <enum-id> N::Namespace :: Enum(X) </enum-id>

     // @ref n4296 7.2/3 ... or a declaration of a new enumeration.
     rule <k> OpaqueEnumDeclaration(X::CId, Scoped::Bool, UT::CPPType)
     => enumContext(X, declareEnumName(createEnumName(X, Sc), UT, Scoped, true), .List, true, UT, true) ...</k>
          <curr-tr-scope> Sc::Scope </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>

endmodule

