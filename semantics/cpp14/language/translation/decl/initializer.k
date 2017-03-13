module CPP-DECL-INITIALIZER-SYNTAX
     imports BASIC-K
     imports LIST
     imports SYMLOC-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-SORTS
     imports CPP-TYPING-SORTS

     syntax Expr ::= figureInit(base: Expr, destT: CPPTypeExpr, init: Init, type: InitType)
     syntax Expr ::= valueInit(base: Expr, CPPType)
                   | defaultInit(base: Expr, CPPTypeExpr)
                   | constructorInit(LVal, InitType, Class, List)
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
     imports CPP-OVERLOADING-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-TYPING-EXPR-SYNTAX
     imports CPP-VALUE-CATEGORY-SYNTAX

     rule figureInit(Base::Expr, DestT::CPPTypeExpr, Init::Init, Type::InitType) => #figureInit(Base, DestT, Type, Init, Init, Init)
     syntax Expr ::= #figureInit(base: Expr, destT: CPPTypeExpr, type: InitType, init: Init, srcT: K, srcCat: K)

     context #figureInit(... base: HOLE:Expr) [result(LVal)]
     context valueInit(... base: HOLE:Expr) [result(LVal)]
     context defaultInit(... base: HOLE:Expr) [result(LVal)]

     context #figureInit(... srcT: HOLE:TypeExpr => typeof(HOLE)) [result(CPPType)]

     context #figureInit(... srcCat: HOLE:CatExpr => catof(HOLE)) [result(ValueCategory)]

     rule <k> #figureInit(... init: ExprLoc(L::CabsLoc, I::Init) => I) ...</k>
          <curr-program-loc> _ => L </curr-program-loc>

     // 8.5:6.1
     rule zeroInit(Base:LVal, T:CPPScalarType) => le(Base, trace(Base), T) := interpret(prv(0, noTrace, T))

     // 8.5:12
     rule #figureInit(Base:LVal, DestT::CPPType, _, NoInit(), _, _)
          => defaultInit(Base, DestT)
     // 8.5:7.1 (class type)
     rule defaultInit(Base:LVal, t(... st: classType(C::Class))) => constructorInit(Base, DirectInit(), C, .List)

     // 8.5:7.2 (array of classes)
     rule defaultInit(Base:LVal, T:CPPArrayType) => initEachElement(Base, T, #klabel(`defaultInit`), 0, .K)
          requires isCPPClassType(getMostDerivedArrayElement(T))
     // 8.5:7.2-7.3 (non-class, non-array-of-classes)
     rule defaultInit(Base:LVal, T::CPPType) => Base
          requires notBool isCPPClassType(getMostDerivedArrayElement(T))

     // 8.5:8.4 (non-class, non-array)
     rule valueInit(Base:LVal, T::CPPType) => zeroInit(Base, T)
          requires notBool isCPPClassType(T)
               andBool notBool isCPPArrayType(T)

     // 8.5:8.3 (array)
     rule valueInit(Base:LVal, T:CPPArrayType) => initEachElement(Base, T, #klabel(`valueInit`), 0, .K)

     syntax Expr ::= initEachElement(LVal, CPPArrayType, K, Int, initExp: K)
     rule (.K => Lbl(Base[prv(I, noTrace, t(noQuals, .Set, size_t))], T)) 
          ~> initEachElement(Base::LVal, t(... st: arrayType(T::CPPType, N::Int)), #klabel(Lbl:KLabel), I::Int => I +Int 1, Res:K)
          requires I <Int N
     rule (V:Val => .K) ~> initEachElement(... initExp: E::Expr => compoundInit(E, V))
     rule initEachElement(Base::LVal, t(... st: arrayType(_, N::Int)), _, N, Res::Expr) => compoundInit(Res, Base)

     // 8.5:17.1 (list initializer)
     rule #figureInit(Base:LVal, DestT::CPPType, Type::InitType, BraceInit(L::List), _, _)
          => listInit(Base, DestT, Type, L)

     // 8.5:17.2 (reference destination type)
     rule #figureInit(Base:LVal, DestT:CPPRefType, _, E:Expr, _, _)
          => bindReference(le(Base, trace(Base), DestT), E)

     // 8.5:17.3 (string literal)
     rule #figureInit(Base:LVal, DestT:CPPArrayType, _, StringLiteral(Kind::CharKind, S::String), _, _)
          => strInit(Base, DestT, Kind, S, 0, .K)
          requires isCPPCharType(innerType(DestT)) 
               orBool simpleType(innerType(DestT)) ==K wchar_t 
               orBool simpleType(innerType(DestT)) ==K char16_t
               orBool simpleType(innerType(DestT)) ==K char32_t

     // expression initializer, non-class type
     rule #figureInit(Base:LVal, DestT::CPPType, _, E:Expr, SrcT:CPPType, SrcCat:ValueCategory)
          => #if canConvertWithStandardConversion(DestT, SrcT, SrcCat) #then le(Base, trace(Base), DestT) := E #else ill-formed #fi
          requires notBool isCPPRefType(DestT) andBool notBool isCPPArrayType(DestT) andBool notBool isCPPClassType(DestT) andBool notBool isCPPClassType(SrcT) 

     rule #figureInit(... base: lv(loc(Base::SymBase, _), _, _), init: S:Stmt)
          => functionDef(Base, S)

     syntax KItem ::= listInit(LVal, CPPType, InitType, List)
                    | aggInit(LVal, CPPType, List)
                    | arrayInit(LVal, CPPType, Int, List, K)
                    | strInit(LVal, CPPType, CharKind, String, Int, K)
                    | zeroInit(LVal, CPPType)

     // TODO(dwightguth): all the cases for class type
     rule listInit(Base::LVal, T::CPPType, _, L::List)
          => aggInit(Base, T, L)
          requires isAggregateType(T)

     // see comment below about narrowing conversions in classAggInit
     rule listInit(Base::LVal, T::CPPType, Type::InitType, L::List)
          => figureInit(Base, T, {L[0]}:>Init, Type)
          requires notBool isAggregateType(T)
               andBool notBool isCPPClassType(T)
               andBool notBool isCPPRefType(T)
               andBool size(L) ==Int 1

     rule aggInit(_, (t(Q::Quals, Mods::Set, incompleteArrayType(T::CPPType)) => t(Q, Mods, arrayType(T, size(L)))), L::List)
     rule aggInit(Base::LVal, t(Q::Quals, Mods::Set, arrayType(T::CPPType, N::Int)), L::List)
          => arrayInit(Base, t(Q, Mods, arrayType(T, N)), 0, L, .K)

     rule <k> aggInit(Base::LVal, t(_, _, classType(C::Class)), L::List)
           => classAndUnionAggInit(getTag(C), Base, NSDM, L, Inits, C, .K)
          ...</k>
          <class-id> C </class-id>
          <non-static-data-members> NSDM::List </non-static-data-members>
          <initializers> Inits::Map </initializers>

     syntax Expr ::= classAndUnionAggInit(tag: Tag, base: LVal, fields: List, initList: List, initializers: Map, class: Class, initExp: Expr) [function]

     rule classAndUnionAggInit(Union(), Base::LVal, ListItem(X:K) _, ListItem(XInit::Init), InitMap::Map, C::Class, Init::Expr)
       => classAggInit(Base, ListItem(X), ListItem(XInit), InitMap, C, Init)

     rule classAndUnionAggInit(... tag: Union(),
                                   fields: (ListItem(kpair(X::CId, _)) => .List) _,
                                   initList: .List,
                                   initializers: (X |-> (_ |-> NoInit())) _)

     rule classAndUnionAggInit(Union(), Base::LVal, ListItem(kpair(X::CId, T::CPPType)) _::List, .List, (X |-> (_ |-> XInit::Init) _) #as InitMap::Map, C::Class, Init::Expr)
       => classAggInit(Base, ListItem(kpair(X, T)), .List, InitMap, C, Init)
       requires XInit =/=K NoInit()

     rule classAndUnionAggInit(T::Tag, Base::LVal, Fields::List, InitL::List, InitMap::Map, C::Class, Init::Expr)
       => classAggInit(Base, Fields, InitL, InitMap, C, Init)
       requires T =/=K Union()

     syntax KItem ::= classAggInit(base: LVal, fields: List, initList: List, initializers: Map, class: Class, initExp: Expr)

     rule classAggInit(... base: Base::LVal,
                           fields: .List,
                           initList: .List,
                           initExp: E::Expr)
       => compoundInit(E, Base)
     // technically this should reject programs where Init is a narrowing
     // conversion on T. However, in this case the initialization is
     // ill-formed. The only case in the semantics so far where we care whether
     // an initialization is well formed within a well-formed program is the
     // case where an initializer is part of a static cast. In this case we are
     // not performing list initialization and therefore cannot reach this rule.
     // as such, whether or not an initializer is a narrowing conversion should
     // only affect the behavior of programs by triggering an error at compile
     // time that the program is ill-formed. However, this error should be
     // emitted by the clang frontend when we parse the program, and therefore
     // semantics for narrowing conversions are not currently needed.
     // thus we elide them for now in order to avoid having to implement
     // semantics for constant expressions.
     rule (.K => figureInit(Base . no-template Name(C, F), T, Init, CopyInit()))
       ~> classAggInit(... base: Base::LVal,
                           fields: (ListItem(kpair(F:CId, _)) => .List) _,
                           initList: (ListItem(Init::Expr) => .List) _,
                           initializers: (F |-> (T::CPPType |-> _)) _,
                           class: C::Class)

     rule (V:Val => .K) ~> classAggInit(... initExp: (E::Expr => compoundInit(E, V)))

     rule (.K => figureInit(Base . no-template Name(C, F), T, evalBraceOrEqualInitializer(C, Base, Init), CopyInit()))
       ~> classAggInit(... base: Base::LVal,
                           fields: (ListItem(kpair(F:CId, _)) => .List) _,
                           initList: .List,
                           initializers: (F |-> (T::CPPType |-> Init::Expr)) _,
                           class: C::Class)

     syntax List ::= getNonStaticDataMembers(ClassInfo) [function]
     rule getNonStaticDataMembers(<class>... <non-static-data-members> L::List </non-static-data-members> ...</class>) => L
     syntax Map ::= getDataMembersInitializers(ClassInfo) [function]
     rule getDataMembersInitializers(<class>... <initializers> M::Map </initializers> ...</class>) => M

     rule (.K => figureInit(Base[prv(I, noTrace, t(noQuals, .Set, size_t))], T, Init, CopyInit()))
          ~> arrayInit(Base::LVal, t(_, _, arrayType(T::CPPType, _)), (I::Int => I +Int 1), (ListItem(Init::Init) => .List) _, _)
          requires notBool isAggregateType(T) orBool isBraceInit(Init)
     rule (V:Val => .K)
          ~> arrayInit(_, _, _, _, (E::Expr => compoundInit(E, V)))
     rule arrayInit(Base::LVal, t(Q::Quals, Mods::Set, arrayType(T::CPPType, Size::Int)), Size::Int, .List, E::Expr)
          => compoundInit(E, Base)

     rule <k> (.K => resolveOverload(cSet(M, C :: ConstructorId(X), .K), list(L), constructorInit(Base, DirectInit(), C, L))) ~> constructorInit(Base::LVal, DirectInit(), _ :: Class(_, X::CId, _) #as C::Class, L::List) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <cenv>... ConstructorId(X) |-> M::Map ...</cenv>

     rule V:Val ~> constructorInit(Base::LVal, _, _, _) => compoundInit(compoundInit(le(beginConstruction(Base), trace(Base), type(Base)), V), le(endConstruction(Base), trace(Base), type(Base)))

     rule (.K => figureInit(Base[prv(I, noTrace, t(noQuals, .Set, size_t))], innerType(T), CharacterLiteral(C, ordChar(firstChar(S))), CopyInit())) ~> strInit(Base:LVal, T::CPPArrayType, C::CharKind, (S::String => butFirstChar(S)), (I::Int => I +Int 1), _)
          requires S =/=String ""
     rule (.K => figureInit(Base[prv(I, noTrace, t(noQuals, .Set, size_t))], T, CharacterLiteral(C, 0), CopyInit())) ~> strInit(Base:LVal, t(_, _, arrayType(T::CPPType, N::Int)), C::CharKind, "", (I::Int => I +Int 1), _)
          requires I <Int N
     rule (V:Val => .K)
          ~> strInit(_, _, _, _, _, (E::Expr => compoundInit(E, V)))
     rule strInit(Base:LVal, t(Q::Quals, Mods::Set, arrayType(T::CPPType, N::Int)), _, "", N, E::Expr)
          => compoundInit(E, Base)

     rule compoundInit(.K, E::Expr) => E
     rule compoundInit(V:TExpr, LV:LVal) => le(compoundInit(stripCompoundInit(V), LV), noTrace, type(LV))
     rule compoundInit(V:TExpr, XV:XVal) => xe(compoundInit(stripCompoundInit(V), XV), noTrace, type(XV))
     rule compoundInit(V:TExpr, PRV:PRVal) => pre(compoundInit(stripCompoundInit(V), PRV), noTrace, type(PRV))
     rule compoundInit(V:Val, E::Expr) => E
          requires notBool isTExpr(V)
     syntax Val ::= stripCompoundInit(Val) [function]
     rule stripCompoundInit(le(compoundInit(E1::Expr, E2::Expr), _, _)) => compoundInit(E1, E2)
     rule stripCompoundInit(V::Val) => V [owise]

endmodule
