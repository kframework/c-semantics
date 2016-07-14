module CPP-DECL-INITIALIZER-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-ABSTRACT-SYNTAX

     syntax KResult ::= initializer(K)

     syntax KItem ::= figureInit(Expr, CPPType, Init, K) [strict(1)]
     syntax KResult ::= initValue(LVal, CPPType, K)

endmodule

module CPP-DECL-INITIALIZER
     imports CPP-DECL-INITIALIZER-SYNTAX
     imports CPP-ELABORATOR-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-TYPING-EXPR-SYNTAX

     context figureInit(_, _, _, (HOLE:KItem => typeof(HOLE)))
             requires isExpr(HOLE) [result(CPPType)]
     syntax KItem ::= figureInitAux(LVal, CPPType, K)

     rule figureInit(Base:LVal, DestT::CPPType, E:Expr, SrcT:CPPType)
          => figureInitAux(Base, DestT, initializer(ExpressionStmt(le(Base, DestT) := E)))
          requires notBool isCPPRefType(DestT) andBool notBool isCPPArrayType(DestT) andBool notBool isCPPClassType(DestT) andBool notBool isCPPClassType(SrcT)

     rule figureInitAux(Base::LVal, T::CPPType, initializer(K:K))
          => elaborate(K) ~> initValue(Base, T, .K)
     rule (elaborateDone(K:K) => .K) ~> initValue(_, _, (.K => K))

     rule figureInit(Base:LVal, T::CPPType, S:Stmt, _)
          => initValue(Base, T, initializer(S))

endmodule
