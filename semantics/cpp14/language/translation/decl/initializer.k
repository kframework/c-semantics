module CPP-DECL-INITIALIZER-SYNTAX
     imports BASIC-K
     imports CPP-TYPING-SORTS
     imports CPP-SORTS

     syntax KResult ::= initializer(K)

     syntax KItem ::= figureInit(Expr, CPPType, Init, K) [strict(1)]

endmodule

module CPP-DECL-INITIALIZER
     imports CPP-DECL-INITIALIZER-SYNTAX
     imports STRING
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ELABORATOR-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-TYPING-EXPR-SYNTAX

     context figureInit(_, _, _, (HOLE:KItem => typeof(HOLE)))
             requires isExpr(HOLE) [result(CPPType)]
     syntax KItem ::= figureInitAux(LVal, CPPType, K)

     // expression initializer, non-class type
     rule figureInit(Base:LVal, DestT::CPPType, E:Expr, SrcT:CPPType)
          => figureInitAux(Base, DestT, initializer(ExpressionStmt(le(Base, trace(Base), DestT) := E)))
          requires notBool isCPPRefType(DestT) andBool notBool isCPPArrayType(DestT) andBool notBool isCPPClassType(DestT) andBool notBool isCPPClassType(SrcT)

     // 8.5:17.1 (list initializer)
     rule figureInit(Base:LVal, DestT::CPPType, BraceInit(L::List), _)
          => listInit(Base, DestT, L)

     // 8.5:17.3
     rule figureInit(Base:LVal, DestT:CPPArrayType, StringLiteral(Kind::CharKind, S::String), _)
          => strInit(Base, DestT, Kind, S, 0, .K)
          requires isCPPCharType(innerType(DestT)) 
               orBool simpleType(innerType(DestT)) ==K wchar_t 
               orBool simpleType(innerType(DestT)) ==K char16_t
               orBool simpleType(innerType(DestT)) ==K char32_t

     // functions
     rule figureInit(Base:LVal, T::CPPType, S:Stmt, _)
          => initValue(Base, T, initializer(S))

     rule figureInitAux(Base::LVal, T::CPPType, initializer(K:K))
          => elaborate(K) ~> initValue(Base, T, .K)
     rule (elaborateDone(K:K) => .K) ~> initValue(_, _, (.K => K))

     syntax KItem ::= listInit(LVal, CPPType, List)
                    | aggInit(LVal, CPPType, List)
                    | arrayInit(LVal, CPPType, Int, List, K)
                    | strInit(LVal, CPPType, CharKind, String, Int, K)

     rule listInit(Base::LVal, T::CPPType, L::List) => aggInit(Base, T, L)
          requires notBool isCPPClassType(T) 
               andBool notBool (isCPPArrayType(T) andBool isCPPCharType(innerType(T)))
               andBool isAggregateType(T)

     rule aggInit(_, (t(Q::Quals, Mods::Set, incompleteArrayType(T::CPPType)) => t(Q, Mods, arrayType(T, size(L)))), L::List)
     rule aggInit(Base::LVal, t(Q::Quals, Mods::Set, arrayType(T::CPPType, N::Int)), L::List)
          => arrayInit(Base, t(Q, Mods, arrayType(T, N)), 0, L, .K)
          requires notBool isAggregateType(T)
     //TODO(dwightguth): subaggregates
     rule (.K => figureInit(Base[prv(I, noTrace, t(noQuals, .Set, size_t))], T, Init, Init))
          ~> arrayInit(Base::LVal, t(_, _, arrayType(T::CPPType, _)), (I::Int => I +Int 1), (ListItem(Init::Init) => .List) _, _)
     rule (initValue(_, _, K:K) => .K)
          ~> arrayInit(_, _, _, _, _:K ~> (.K => K))
     rule arrayInit(Base::LVal, t(Q::Quals, Mods::Set, arrayType(T::CPPType, Size::Int)), Size::Int, .List, K:K)
          => initValue(Base, t(Q, Mods, arrayType(T, Size)), K)

     rule (.K => figureInit(Base[prv(I, noTrace, t(noQuals, .Set, size_t))], innerType(T), CharacterLiteral(C, ordChar(firstChar(S))), CharacterLiteral(C, ordChar(firstChar(S))))) ~> strInit(Base:LVal, T::CPPArrayType, C::CharKind, (S::String => butFirstChar(S)), (I::Int => I +Int 1), _)
          requires S =/=String ""
     rule (.K => figureInit(Base[prv(I, noTrace, t(noQuals, .Set, size_t))], T, CharacterLiteral(C, 0), CharacterLiteral(C, 0))) ~> strInit(Base:LVal, t(_, _, arrayType(T::CPPType, N::Int)), C::CharKind, "", (I::Int => I +Int 1), _)
          requires I <Int N
     rule (initValue(_, _, K:K) => .K)
          ~> strInit(_, _, _, _, _, _ ~> (.K => K))
     rule strInit(Base:LVal, t(Q::Quals, Mods::Set, arrayType(T::CPPType, N::Int)), _, "", N, K:K)
          => initValue(Base, t(Q,  Mods, arrayType(T, N)), K)

endmodule
