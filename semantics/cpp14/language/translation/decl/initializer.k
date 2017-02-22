module CPP-DECL-INITIALIZER-SYNTAX
     imports BASIC-K
     imports SYMLOC-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-SORTS
     imports CPP-TYPING-SORTS

     syntax Expr ::= figureInit(Expr, CPPTypeExpr, Duration, Init)
     syntax Expr ::= valueInit(LVal, CPPType)
     syntax KResult ::= functionDef(SymBase, Stmt)
     syntax KResult ::= "ill-formed"
endmodule

module CPP-DECL-INITIALIZER
     imports CPP-DECL-INITIALIZER-SYNTAX
     imports C-CONFIGURATION
     imports K-REFLECTION
     imports STRING
     imports COMMON-SYNTAX
     imports SYMLOC-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-CLASS-SYNTAX
     imports CPP-CONVERSION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ELABORATOR-SYNTAX
     imports CPP-MEMORY-READING-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-TYPING-EXPR-SYNTAX
     imports CPP-VALUE-CATEGORY-SYNTAX

     rule figureInit(Base::Expr, DestT::CPPTypeExpr, Duration::Duration, Init::Init) => #figureInit(Base, DestT, Duration, Init, Init, Init)
     syntax Expr ::= #figureInit(Expr, CPPTypeExpr, Duration, Init, K, K)

     context #figureInit(HOLE:Expr, _, _, _, _, _) [result(LVal)]

     context #figureInit(_, _, _, _, (HOLE:TypeExpr => typeof(HOLE)), _) [result(CPPType)]
     context #figureInit(_, _, _, _, _, (HOLE:CatExpr => catof(HOLE))) [result(ValueCategory)]

     rule <k> #figureInit(_, _, _, (ExprLoc(L::CabsLoc, I::Init) => I), _, _) ...</k>
          <curr-program-loc> _ => L </curr-program-loc>

     // expression initializer, non-class type
     rule #figureInit(Base:LVal, DestT::CPPType, _, E:Expr, SrcT:CPPType, SrcCat:ValueCategory)
          => #if canConvertWithStandardConversion(DestT, SrcT, SrcCat) #then le(Base, trace(Base), DestT) := E #else ill-formed #fi
          requires notBool isCPPRefType(DestT) andBool notBool isCPPArrayType(DestT) andBool notBool isCPPClassType(DestT) andBool notBool isCPPClassType(SrcT) 

     rule #figureInit(Base:LVal, DestT:CPPRefType, _, E:Expr, _, _)
          => bindReference(le(Base, trace(Base), DestT), E)

     // 8.5:12
     rule #figureInit(Base:LVal, DestT::CPPType, StaticStorage, NoInit(), _, _)
          => zeroInit(Base, DestT, StaticStorage)
     rule #figureInit(Base:LVal, DestT::CPPType, AutoStorage, NoInit(), _, _)
          => defaultInit(Base, DestT)
     rule #figureInit(Base:LVal, DestT::CPPTypeExpr, DynamicStorage, NoInit(), _, _)
          => defaultInit(Base, DestT)
     // 8.5:6.1, 6.4 (scalar type or array of scalars, initialized implicitly by memory read)
     rule zeroInit(Base:LVal, T::CPPType, StaticStorage) => Base
          requires notBool isCPPClassType(T)
           andBool (notBool isCPPArrayType(T) orBool notBool isCPPClassType(innerType(T))) andBool notBool isCPPRefType(T)
     // 8.5:7.2-7.3 (non-class, non-array-of-classes, initialized implicitly by memory read)
     rule defaultInit(Base:LVal, T::CPPType) => Base
          requires notBool isCPPClassType(T) andBool (notBool isCPPArrayType(T) orBool notBool isCPPClassType(innerType(T)))
     // 8.5:6.1 for non-statically declared scalars
     rule zeroInit(Base:LVal, T:CPPScalarType, D::Duration) => le(Base, trace(Base), T) := interpret(prv(0, noTrace, T))
          requires D =/=K StaticStorage

     // 8.5:8.4
     rule valueInit(Base:LVal, T::CPPType) => zeroInit(Base, T, AutoStorage)
          requires notBool isCPPClassType(T)
           andBool notBool isCPPArrayType(T)
           andBool notBool isCPPRefType(T)


     // 8.5:17.1 (list initializer)
     rule #figureInit(Base:LVal, DestT::CPPType, D::Duration, BraceInit(L::List), _, _)
          => listInit(Base, DestT, D, L)

     // 8.5:17.3
     rule #figureInit(Base:LVal, DestT:CPPArrayType, D::Duration, StringLiteral(Kind::CharKind, S::String), _, _)
          => strInit(Base, DestT, D, Kind, S, 0, .K)
          requires isCPPCharType(innerType(DestT)) 
               orBool simpleType(innerType(DestT)) ==K wchar_t 
               orBool simpleType(innerType(DestT)) ==K char16_t
               orBool simpleType(innerType(DestT)) ==K char32_t

     rule #figureInit(lv(loc(Base::SymBase, _), _, _), _, _, S:Stmt, _, _)
          => functionDef(Base, S)

     syntax KItem ::= listInit(LVal, CPPType, Duration, List)
                    | aggInit(LVal, CPPType, Duration, List)
                    | arrayInit(LVal, CPPType, Duration, Int, List, K)
                    | strInit(LVal, CPPType, Duration, CharKind, String, Int, K)
                    | zeroInit(LVal, CPPType, Duration)
                    | defaultInit(LVal, CPPTypeExpr)

     // TODO(dwightguth): all the cases for class type
     rule listInit(Base::LVal, T::CPPType, D::Duration, L::List)
          => #if isAggregateType(T) #then aggInit(Base, T, D, L)
             #else #if size(L) ==Int 1 andBool notBool isCPPRefType(T) #then figureInit(Base, T, D, {L[0]}:>Init) #else ill-formed #fi #fi
          requires notBool isCPPClassType(T) 
               andBool notBool (isCPPArrayType(T) andBool isCPPCharType(innerType(T)) andBool size(L) ==Int 1 andBool getKLabel(L[0]) ==K #klabel(`StringLiteral`))

     // 8.5.4:3.1
     rule listInit(Base::LVal, T::CPPType, D::Duration, L::List)
          => aggInit(Base, T, D, L)
          requires isCPPClassType(T) andBool isAggregateType(T)

     rule aggInit(_, (t(Q::Quals, Mods::Set, incompleteArrayType(T::CPPType)) => t(Q, Mods, arrayType(T, size(L)))), _, L::List)
     rule aggInit(Base::LVal, t(Q::Quals, Mods::Set, arrayType(T::CPPType, N::Int)), D::Duration, L::List)
          => arrayInit(Base, t(Q, Mods, arrayType(T, N)), D, 0, L, .K)

     rule <k> aggInit(Base::LVal, t(_, _, classType(C::Class)), D::Duration, L::List)
           => classAggInit(Base, NSDM, L, Inits, D, C, .K)
          ...</k>
          <class-id> C </class-id>
          <non-static-data-members> NSDM::List </non-static-data-members>
          <initializers> Inits::Map </initializers>


     syntax KItem ::= classAggInit(base: LVal, fields: List, initList: List, initializers: Map, duration: Duration, class: Class, initExp: Expr)

     rule classAggInit(... base: Base::LVal,
                           fields: .List,
                           initList: .List,
                           initExp: E::Expr)
       => compoundInit(E, Base)
     rule (.K => figureNarrowInit(le(Base . no-template Name(NoNNS(), F), noTrace, T), T, D, Init, Init))
       ~> classAggInit(... base: Base::LVal,
                           fields: (ListItem(F:CId) => .List) FL::List,
                           initList: (ListItem(Init::Expr) => .List) _,
                           initializers: (F |-> (T::CPPType |-> _)) _,
                           duration: D::Duration)
     rule (V:Val => .K) ~> classAggInit(... initExp: (E::Expr => compoundInit(E, V)))

     rule (.K => figureInit(le(Base . no-template Name(NoNNS(), F), noTrace, T), T, D, evalBraceOrEqualInitializer(C, Base, Init)))
       ~> classAggInit(... base: Base::LVal,
                           fields: (ListItem(F:CId) => .List) _,
                           initList: .List,
                           initializers: (F |-> (T::CPPType |-> Init::Expr)) _,
                           duration: D::Duration,
                           class: C::Class)

     syntax Expr ::= figureNarrowInit(Expr, CPPTypeExpr, Duration, Init, K)
     context figureNarrowInit(_, _, _, _, (HOLE:TypeExpr => typeof(HOLE))) [result(CPPType)]
     rule figureNarrowInit(Base::Expr, DestT::CPPType, D::Duration, Init::Init, SrcT:CPPType)
          => figureInit(Base, DestT, D, Init)
          requires notBool isNarrowingConversion(DestT, SrcT, Init)

     syntax Bool ::= isNarrowingConversion(dest: CPPType, src: CPPType, Init) [function]
     // 8.5.4:7.1
     rule isNarrowingConversion(DestT:CPPIntegerType, SrcT:CPPFloatingType, _) => true
     rule isNarrowingConversion(T1::CPPType, T2::CPPType, _) => false
          requires T1 ==Type T2

     syntax List ::= getNonStaticDataMembers(ClassInfo) [function]
     rule getNonStaticDataMembers(<class>... <non-static-data-members> L::List </non-static-data-members> ...</class>) => L
     syntax Map ::= getDataMembersInitializers(ClassInfo) [function]
     rule getDataMembersInitializers(<class>... <initializers> M::Map </initializers> ...</class>) => M

     rule (.K => figureInit(Base[prv(I, noTrace, t(noQuals, .Set, size_t))], T, D, Init))
          ~> arrayInit(Base::LVal, t(_, _, arrayType(T::CPPType, _)), D::Duration, (I::Int => I +Int 1), (ListItem(Init::Init) => .List) _, _)
          requires notBool isAggregateType(T) orBool isBraceInit(Init)
     rule (V:Val => .K)
          ~> arrayInit(_, _, _, _, _, (E::Expr => compoundInit(E, V)))
     rule arrayInit(Base::LVal, t(Q::Quals, Mods::Set, arrayType(T::CPPType, Size::Int)), _, Size::Int, .List, E::Expr)
          => compoundInit(E, Base)

     rule (.K => figureInit(Base[prv(I, noTrace, t(noQuals, .Set, size_t))], innerType(T), D, CharacterLiteral(C, ordChar(firstChar(S))))) ~> strInit(Base:LVal, T::CPPArrayType, D::Duration, C::CharKind, (S::String => butFirstChar(S)), (I::Int => I +Int 1), _)
          requires S =/=String ""
     rule (.K => figureInit(Base[prv(I, noTrace, t(noQuals, .Set, size_t))], T, D, CharacterLiteral(C, 0))) ~> strInit(Base:LVal, t(_, _, arrayType(T::CPPType, N::Int)), D::Duration, C::CharKind, "", (I::Int => I +Int 1), _)
          requires I <Int N
     rule (V:Val => .K)
          ~> strInit(_, _, _, _, _, _, (E::Expr => compoundInit(E, V)))
     rule strInit(Base:LVal, t(Q::Quals, Mods::Set, arrayType(T::CPPType, N::Int)), _, _, "", N, E::Expr)
          => compoundInit(E, Base)

     rule compoundInit(.K, E::Expr) => E
     rule compoundInit(V:TExpr, LV:LVal) => le(compoundInit(stripCompoundInit(V), LV), noTrace, type(LV))
     rule compoundInit(V:Val, E::Expr) => E
          requires notBool isTExpr(V)
     syntax Val ::= stripCompoundInit(Val) [function]
     rule stripCompoundInit(le(compoundInit(E1::Expr, E2::Expr), _, _)) => compoundInit(E1, E2)
     rule stripCompoundInit(V::Val) => V [owise]

endmodule
