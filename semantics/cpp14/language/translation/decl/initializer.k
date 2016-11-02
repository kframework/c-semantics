module CPP-DECL-INITIALIZER-SYNTAX
     imports BASIC-K
     imports SYMLOC-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-SORTS
     imports CPP-TYPING-SORTS

     syntax Expr ::= figureInit(Expr, CPPTypeExpr, Duration, Init, K)
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
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ELABORATOR-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-TYPING-EXPR-SYNTAX

     context figureInit(HOLE:Expr, _, _, _, _) [result(LVal)]

     context figureInit(_, _, _, _, (HOLE:TypeExpr => typeof(HOLE))) [result(CPPType)]

     rule <k> figureInit(_, _, _, (ExprLoc(L::CabsLoc, I::Init) => I), _) ...</k>
          <curr-program-loc> _ => L </curr-program-loc>

     // expression initializer, non-class type
     rule figureInit(Base:LVal, DestT::CPPType, _, E:Expr, SrcT:CPPType)
          => le(Base, trace(Base), DestT) := E
          requires notBool isCPPRefType(DestT) andBool notBool isCPPArrayType(DestT) andBool notBool isCPPClassType(DestT) andBool notBool isCPPClassType(SrcT)

     rule figureInit(Base:LVal, DestT:CPPRefType, _, E:Expr, _)
          => bindReference(le(Base, trace(Base), DestT), E)

     // 8.5:12
     rule figureInit(Base:LVal, DestT::CPPType, StaticStorage, NoInit(), _)
          => zeroInit(Base, DestT)
     rule figureInit(Base:LVal, DestT::CPPType, AutoStorage, NoInit(), _)
          => defaultInit(Base, DestT)
     rule figureInit(Base:LVal, DestT::CPPTypeExpr, DynamicStorage, NoInit(), _)
          => defaultInit(Base, DestT)
     // 8.5:6.1, 6.4 (scalar type or array of scalars, initialized implicitly by memory read)
     rule zeroInit(Base:LVal, T::CPPType) => Base
          requires notBool isCPPClassType(T) andBool (notBool isCPPArrayType(T) orBool notBool isCPPClassType(innerType(T))) andBool notBool isCPPRefType(T)
     // 8.5:7.2-7.3 (non-class, non-array-of-classes, initialized implicitly by memory read)
     rule defaultInit(Base:LVal, T::CPPType) => Base
          requires notBool isCPPClassType(T) andBool (notBool isCPPArrayType(T) orBool notBool isCPPClassType(innerType(T)))

     // 8.5:17.1 (list initializer)
     rule figureInit(Base:LVal, DestT::CPPType, D::Duration, BraceInit(L::List), _)
          => listInit(Base, DestT, D, L)

     // 8.5:17.3
     rule figureInit(Base:LVal, DestT:CPPArrayType, D::Duration, StringLiteral(Kind::CharKind, S::String), _)
          => strInit(Base, DestT, D, Kind, S, 0, .K)
          requires isCPPCharType(innerType(DestT)) 
               orBool simpleType(innerType(DestT)) ==K wchar_t 
               orBool simpleType(innerType(DestT)) ==K char16_t
               orBool simpleType(innerType(DestT)) ==K char32_t

     rule figureInit(lv(loc(Base::SymBase, _, _), _, _), _, _, S:Stmt, _)
          => functionDef(Base, S)

     syntax KItem ::= listInit(LVal, CPPType, Duration, List)
                    | aggInit(LVal, CPPType, Duration, List)
                    | arrayInit(LVal, CPPType, Duration, Int, List, K)
                    | strInit(LVal, CPPType, Duration, CharKind, String, Int, K)
                    | zeroInit(LVal, CPPType)
                    | defaultInit(LVal, CPPTypeExpr)

     // TODO(dwightguth): all the cases for class type
     rule listInit(Base::LVal, T::CPPType, D::Duration, L::List)
          => #if isAggregateType(T) #then aggInit(Base, T, D, L)
             #else #if size(L) ==Int 1 andBool notBool isCPPRefType(T) #then figureInit(Base, T, D, {L[0]}:>Init, {L[0]}:>Init) #else ill-formed #fi #fi
          requires notBool isCPPClassType(T) 
               andBool notBool (isCPPArrayType(T) andBool isCPPCharType(innerType(T)) andBool size(L) ==Int 1 andBool getKLabel(L[0]) ==K #klabel(`StringLiteral`))

     rule aggInit(_, (t(Q::Quals, Mods::Set, incompleteArrayType(T::CPPType)) => t(Q, Mods, arrayType(T, size(L)))), _, L::List)
     rule aggInit(Base::LVal, t(Q::Quals, Mods::Set, arrayType(T::CPPType, N::Int)), D::Duration, L::List)
          => arrayInit(Base, t(Q, Mods, arrayType(T, N)), D, 0, L, .K)
     rule (.K => figureInit(Base[prv(I, noTrace, t(noQuals, .Set, size_t))], T, D, Init, Init))
          ~> arrayInit(Base::LVal, t(_, _, arrayType(T::CPPType, _)), D::Duration, (I::Int => I +Int 1), (ListItem(Init::Init) => .List) _, _)
          requires notBool isAggregateType(T) orBool isBraceInit(Init)
     rule (V:Val => .K)
          ~> arrayInit(_, _, _, _, _, (E::Expr => compoundInit(E, V)))
     rule arrayInit(Base::LVal, t(Q::Quals, Mods::Set, arrayType(T::CPPType, Size::Int)), _, Size::Int, .List, E::Expr)
          => E

     rule (.K => figureInit(Base[prv(I, noTrace, t(noQuals, .Set, size_t))], innerType(T), D, CharacterLiteral(C, ordChar(firstChar(S))), CharacterLiteral(C, ordChar(firstChar(S))))) ~> strInit(Base:LVal, T::CPPArrayType, D::Duration, C::CharKind, (S::String => butFirstChar(S)), (I::Int => I +Int 1), _)
          requires S =/=String ""
     rule (.K => figureInit(Base[prv(I, noTrace, t(noQuals, .Set, size_t))], T, D, CharacterLiteral(C, 0), CharacterLiteral(C, 0))) ~> strInit(Base:LVal, t(_, _, arrayType(T::CPPType, N::Int)), D::Duration, C::CharKind, "", (I::Int => I +Int 1), _)
          requires I <Int N
     rule (V:Val => .K)
          ~> strInit(_, _, _, _, _, _, (E::Expr => compoundInit(E, V)))
     rule strInit(Base:LVal, t(Q::Quals, Mods::Set, arrayType(T::CPPType, N::Int)), _, _, "", N, E::Expr)
          => E

     rule compoundInit(.K, E::Expr) => E
     rule compoundInit(V:TExpr, LV:LExpr) => le(compoundInit(stripCompoundInit(V), LV), noTrace, type(LV))
     rule compoundInit(V:Val, E::Expr) => E
          requires notBool isTExpr(V)
     syntax Val ::= stripCompoundInit(Val) [function]
     rule stripCompoundInit(le(compoundInit(E1::Expr, E2::Expr), _, _)) => compoundInit(E1, E2)
     rule stripCompoundInit(V::Val) => V [owise]

endmodule
