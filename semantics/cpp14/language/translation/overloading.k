module CPP-OVERLOADING-SYNTAX
     imports COMPAT-SYNTAX

     syntax Val ::= CandidateSet
     syntax CandidateSet ::= cSet(Map)
     syntax Expr ::= resolveOverload(CandidateSet, StrictList, CId, CId)
     syntax Expr ::= resolveUniqueDecl(K, Expr) [strict(1)]

endmodule

module CPP-OVERLOADING
     imports CPP-OVERLOADING-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-DECL-TEMPLATE-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TEMPLATE-DEDUCTION-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports C-CONFIGURATION

     // no overloading
     rule <k> resolveOverload(cSet(T::CPPType |-> kpair(_, Base::SymBase)), Args::StrictList, X::CId, operator()) 
              => CallExpr(lv(lnew(Base, T), hasTrace(Name(NoNNS(), X)), T), Args) ...</k>
          <odr-uses>... .Set => SetItem(Base) ...</odr-uses>
          requires notBool isCPPClassType(T)
               andBool Base =/=K nonStatic

     rule resolveOverload(cSet((T:CPPFunctionTypeExpr => adjustFunctionType(T)) |-> _:TemplateInfo), _, _, _)
          requires notBool isAdjustedType(T)

     rule <k> (.K => deduceTemplateFromCall(T, Args, .List, Q)) ~> resolveOverload(cSet((T:CPPFunctionTypeExpr |-> templateInfo(Q::QualId, Decls::List, Types::Map, Defaults::Map, _, _) => .Map) _), list(Args::List), _, _) ...</k>
          <template-deduction> _ => .Map </template-deduction>

     rule (templateSpecialization(T:CPPType, I::TemplateInfo, Args::Map) => .K) ~> resolveOverload(cSet((.Map => T |-> templateSpecialization(T, I, Args)) _), _, _, _)

     rule (.K => instantiateObjectTemplate(Spec)) ~> resolveOverload(cSet(T::CPPType |-> Spec:TemplateSpecialization => .Map), _, _, _)

     rule (lv(loc(Base::SymBase, 0, _), _, T::CPPType) => .K) ~> resolveOverload(cSet(.Map => T |-> kpair(false, Base)), _, _, _)

     rule resolveUniqueDecl(cSet(T::CPPType |-> kpair(_, Base::SymBase)), E::Expr) => lv(lnew(Base, T), hasTrace(E), T)
          requires Base =/=K nonStatic
     rule resolveUniqueDecl(cSet(T::CPPType |-> kpair(_, nonStatic)), E::Expr) => le(E, hasTrace(E), T)
     rule resolveUniqueDecl(V:KResult, _) => V
          requires notBool isCandidateSet(V)

endmodule
