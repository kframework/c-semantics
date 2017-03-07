module CPP-DECL-ENUM-SYNTAX
     imports BOOL-SYNTAX
     imports LIST
     imports COMMON-SORTS
     imports CPP-SORTS
     imports CPP-TYPING-SYNTAX
endmodule

module CPP-DECL-ENUM
     imports CPP-DECL-ENUM-SYNTAX
     imports C-CONFIGURATION
     imports COMMON-SYNTAX
     imports COMPAT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ENV-SYNTAX
     imports CPP-ERROR-SYNTAX
     imports CPP-SYNTAX
     imports CPP-BITSIZE-SYNTAX
     imports INT
     imports STRING

     rule <k> EnumDef(X::CId, NoNNS(), Scoped::Bool, Fixed::Bool, UT::CPPIntegerType, Enumerators::List)
          => enumContext(X, declareEnumName(createEnumName(X, Sc), UT, Scoped, Fixed), Enumerators, Fixed, UT) ...</k>
          <curr-scope> Sc::Scope </curr-scope>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>

     syntax Enum ::= createEnumName(CId, Scope) [function]
     rule createEnumName(X::CId, namespaceScope(N::Namespace)) => N :: Enum(X)
     rule createEnumName(X::CId, classScope(C::Class)) => C :: Enum(X)
     rule createEnumName(X::CId, blockScope(_, _, _) #as B::BlockScope) => localQual(B) :: Enum(X)

     syntax CPPEnumType ::= declareEnumName(Enum, ut: CPPIntegerType, scoped: Bool, fixed: Bool) [function]
     rule declareEnumName(E::Enum, UT::CPPIntegerType, false, Fixed:Bool) => t(noQuals, .Set, unscopedEnum(enumId(E), UT, false))
     rule declareEnumName(E::Enum, UT::CPPIntegerType, true, true)  => t(noQuals, .Set, scopedEnum(enumId(E), UT))

     syntax Scope ::= getEnumScope(EnumId) [function]
     rule getEnumScope(enumId(N:Namespace :: _)) => namespaceScope(N)
     rule getEnumScope(enumId(C:Class :: _)) => classScope(C)
     rule getEnumScope(enumId(localQual(B:BlockScope) :: _)) => B

     syntax KItem ::= addEnumToEnv(CId, CPPEnumType)
     rule addEnumToEnv(X::CId, E::CPPEnumType) => #addEnumToEnv(X, getEnumScope(getEnumId(E)), E)

     syntax KItem ::= #addEnumToEnv(CId, Scope, CPPEnumType)
     rule <k> #addEnumToEnv(X::CId, namespaceScope(N::Namespace), E::CPPEnumType) => . ... </k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <ntypes> NT::Map => NT[X, Enum() <- E] </ntypes>

     rule <k> #addEnumToEnv(X::CId, classScope(C::Class), E::CPPEnumType) => . ... </k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <ctypes> NT::Map => NT[X, Enum() <- E] </ctypes>

     rule <k> #addEnumToEnv(X::CId, blockScope(_, _, _), E::CPPEnumType) => . ... </k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <types> NT::Map => NT[X, Enum() <- E] </types>


     syntax KItem ::= enumContext(CId, CPPEnumType, List, fixed: Bool, ut: CPPIntegerType) [strict(2)]

     rule enumContext(X::CId, E::CPPEnumType, Enumerators:List, Fixed::Bool, UT::CPPIntegerType)
          => newEnum(E, Fixed)
          ~> addEnumToEnv(X, E)
          ~> inEnumScope(E, declareEnumerators(E, 0, 0, 0, int, Enumerators, Fixed, true))

     syntax KItem ::= inEnumScope(CPPEnumType, K)
     rule <k> inEnumScope(E::CPPEnumType, K:K) => K ~> setScope(OldScope) ... </k>
          <curr-scope> OldScope::Scope => enumScope(getEnumId(E))  </curr-scope>


     // second param -underlying type
     syntax KItem ::= newEnum(CPPEnumType, fixed: Bool)

     rule <k> newEnum(E:CPPEnumType, true) => . ... </k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          (.Bag => <cppenum>...
               <enum-id> getEnumId(E) </enum-id>
               <enum-type> E </enum-type>
               <scoped> getScoped(E) </scoped>
               <enum-complete> true </enum-complete>
               <enum-min> min(underlyingType(E)) </enum-min>
               <enum-max> max(underlyingType(E)) </enum-max>
           ...</cppenum>)

     rule <k> newEnum(E:CPPUnscopedEnumType, false) => . ... </k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          (.Bag => <cppenum>...
               <enum-id> getEnumId(E) </enum-id>
               <enum-type> E </enum-type>
               <scoped> false </scoped>
               <enum-complete> false </enum-complete>
           ...</cppenum>)

     syntax KItem ::= declareEnumerators(CPPEnumType, min: Int, max: Int, next: Int, prevType: CPPSimpleType, List, fixed: Bool, first: Bool)

     // First enumerator, fixed underlying type.
     rule declareEnumerators(E::CPPEnumType, _, _, _, _, ListItem(Enumerator(_, NoExpression() => prv(0, noTrace, underlyingType(E)))) _::List, true, true)

     // First enumerator, underlying type not fixed
     rule (.K => UNSPEC("TDE2", "No initializer specified for the first enumerator, underlying type of enumerator is unspecified")) ~> (
          declareEnumerators(E::CPPEnumType, Min::Int, Max::Int, Next::Int, PrevType::CPPSimpleType, ListItem(Enumerator(X::CId, NoExpression())) L::List, false, true)
          => recoverFromError(
          declareEnumerators(E, Min, Max, Next, PrevType, ListItem(Enumerator(X, prv(0, noTrace, type(int)))) L, false, true)
          ))

     // Second or more enumerator, fixed underlying type
     rule declareEnumerators(E::CPPEnumType, _, _, Next::Int, _,
               ListItem(Enumerator(_, NoExpression() => prv(Next, noTrace, underlyingType(E)))) _::List, true, false)

     // Second or more enumerator, underlying type not fixed, value fits.
     rule declareEnumerators(_, _, _, Next::Int, PrevType::CPPSimpleType,
               ListItem(Enumerator(_, NoExpression() => prv(Next, noTrace, type(PrevType)))) _::List, false, false)
          requires inRange(Next, type(PrevType))

     // Second or more enumerator, underlype type not fixed, value does not fit to previous type but fits to some.
     rule (.K => UNSPEC("TDE3", "Value does not fit to type of preceding enumerator")) ~> (
          declareEnumerators(E::CPPEnumType, Min::Int, Max::Int, Next::Int, PrevType::CPPSimpleType, ListItem(Enumerator(X::CId, NoExpression())) L::List, false, false)
          => recoverFromError(
          declareEnumerators(E, Min, Max, Next::Int, PrevType, ListItem(Enumerator(X, prv(Next, noTrace, type(firstSuitableType(Next, Next, allIntegralTypes))))) L, false, false)
          ))
          requires notBool inRange(Next, type(PrevType)) andBool firstSuitableType(Next, Next, allIntegralTypes) =/=K no-type

     rule (.K => ILL("TDE4", "Incremented enumerator value is not representable in any integer type")) ~>
          declareEnumerators(_, _, _, Next::Int, PrevType::CPPSimpleType, ListItem(Enumerator(_, NoExpression())) _::List, false, false)
          requires notBool inRange(Next, type(PrevType)) andBool firstSuitableType(Next, Next, allIntegralTypes) ==K no-type

     rule declareEnumerators(_, _, _, _, _, ListItem(Enumerator(_, prv(_, _, T:CPPUnscopedEnumType => underlyingType(T)))) _::List, _, _)
     context declareEnumerators(_, _, _, _, _, ListItem(Enumerator(_, HOLE:Expr)) _::List, _, _)

     // Type of an enumerator inside the declaration is enum's underlying type
     // if it is fixed, and type of initializing expression otherwise,
     // Hence we need to store the type of underlying expression...
     rule declareEnumerators(T::CPPEnumType, Min::Int, Max::Int, Next::Int, _, ListItem(Enumerator(X::CId, prv(V::Int, _, t(_, _, EType:CPPSimpleType)) #as Pr::PRVal)) L::List, Fixed:Bool, First:Bool)
          => declareEnumerator(getEnumId(T), X, Pr, Fixed, underlyingType(T))
          ~> declareEnumerators(T, #if First #then V #else minInt(Min, V) #fi, #if First #then V #else maxInt(Max, V) #fi, V +Int 1, EType, L, Fixed, false)
     requires notBool isCPPSimpleUnscopedEnumType(EType)

     // Enums with fixed underlying type are finished by now.
     rule declareEnumerators(T::CPPEnumType, _, _, _, _, .List, true, _) => .

     rule declareEnumerators(T::CPPUnscopedEnumType, Min::Int, Max::Int, _, _, .List, false, _) => calculateEnumValues(T, Min, Max)


     syntax KItem ::= declareEnumerator(EnumId, CId, PRVal, fixed: Bool, ut: CPPType)

     // Not fixed
     rule declareEnumerator(E::EnumId, X::CId, prv(_,_,_) #as Pr::PRVal, false, _) => addEnumerator(E, X, Pr)

     // Fixed enumerator.
     rule declareEnumerator(E::EnumId, X::CId, prv(V::CPPValue, Tr::Trace, _), true, UT::CPPIntegerType) => addEnumerator(E, X, prv(V, Tr, UT))
     requires inRange(V, UT)

     rule (.K => ILL("TDE1", "Value of enumerator '" +String idToString(X) +String "' does not fit to fixed underlying type.")) ~> declareEnumerator(_, X::CId, prv(V::CPPValue, _, _), true, UT::CPPIntegerType)
          requires notBool inRange(V, UT)

     syntax KItem ::= addEnumerator(enum: EnumId, id: CId, v: PRVal)
     rule <k> addEnumerator(E::EnumId, X::CId, V::PRVal) => addEnumeratorToEnv(E, X) ... </k>
         <enum-id> E </enum-id>
         <enumerators> ES::Map => ES[X <- V] </enumerators>

     syntax KItem ::= addEnumeratorToEnv(EnumId, CId)

     rule <k> addEnumeratorToEnv(E::EnumId, _) => . ... </k>
          <enum-id> E </enum-id>
          <scoped> true </scoped>

     rule <k> addEnumeratorToEnv(enumId(E::Enum) #as EId::EnumId, X::CId) => addUnscopedEnumeratorToEnv(X, E) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <enum-id> EId </enum-id>
          <scoped> false </scoped>

     syntax KItem ::= addUnscopedEnumeratorToEnv(CId, Enum)

     rule <k> addUnscopedEnumeratorToEnv(X::CId, (N:Namespace :: _) #as E::Enum) => . ... </k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <unscoped-enumerators> UE::Map (.Map => X |-> E ) </unscoped-enumerators>

     rule <k> addUnscopedEnumeratorToEnv(X::CId, (C:Class :: _) #as E::Enum) => . ... </k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <cl-unscoped-enumerators> UE::Map (.Map => X |-> E ) </cl-unscoped-enumerators>

     rule <k> addUnscopedEnumeratorToEnv(X::CId, (localQual(_:BlockScope) :: _) #as E::Enum) => . ... </k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <bl-unscoped-enumerators> UE::Map (.Map => X |-> E ) </bl-unscoped-enumerators>


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
             ListItem(unsigned-long-long)

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


     syntax KItem ::= calculateEnumValues(CPPEnumType, min: Int, max: Int)

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

     rule calculateEnumValues(T::CPPEnumType, Min::Int, Max::Int) => computeEnumUt(T, calculateMinEnumValue(Min, Max), calculateMaxEnumValue(Min, Max))

     syntax KItem ::= computeEnumUt(CPPEnumType, min: Int, max: Int)

     // TODO(h0nzZik): packed enums
     rule computeEnumUt(T::CPPEnumType, Min::Int, Max::Int) => setEnumMinMaxUt(T, Min, Max, type(firstSuitableType(Min, Max, integralTypesGreaterThanInt)))

     syntax KItem ::= setEnumMinMaxUt(CPPEnumType, min: Int, max: Int, ut: CPPType)

     rule <k> setEnumMinMaxUt(t(_, _, unscopedEnum(enumId(_ :: Enum(X::CId)) #as E::EnumId, _, _)), Min::Int, Max::Int, UT:CPPIntegerType)
          => addEnumToEnv(X, t(noQuals, .Set, unscopedEnum(E, UT, false))) ... </k>
          <enum-id> E </enum-id>
          <enum-type> _ => t(noQuals, .Set, unscopedEnum(E, UT, false)) </enum-type>
          <enum-min> _ => Min </enum-min>
          <enum-max> _ => Max </enum-max>
          <enum-complete> _ => true </enum-complete>


endmodule

