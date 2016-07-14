module CPP-EXPR-NAME
     imports COMPAT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-OVERLOADING-SYNTAX
     imports CPP-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports C-CONFIGURATION

     rule CallExpr(Name(NoNamespace(), X::CId), Args::StrictList) => argDependentNameLookup(X, Args, Args, nameLookup(X))

     syntax Expr ::= argDependentNameLookup(CId, StrictList, StrictList, Expr) [strict(4)]
                   | #argDependentNameLookup(CId, StrictList, List, CandidateSet)
                   | nameLookup(CId)
                   | nameLookupInNamespace(CId, Namespace)

     context argDependentNameLookup(_, _, (HOLE:StrictList => types(HOLE)), _)

     rule <k> nameLookup(X::CId) => cSet(S) ...</k>
          <curr-scope> _:BlockScope </curr-scope>
          <env>... X |-> S::Map ...</env>

     rule <k> nameLookup(X::CId) => nameLookupInNamespace(X, N) ...</k>
          <curr-scope> blockScope(N::NormalizedNamespace :: _, _) </curr-scope>
          <env> Env::Map </env>
          requires notBool X in_keys(Env)

     rule <k> nameLookupInNamespace(X::CId, N::NormalizedNamespace) => cSet(S) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> S::Map ...</nenv>

     rule <k> nameLookupInNamespace(X::CId, N::NormalizedNamespace :: _) => nameLookupInNamespace(X, N) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv> Env::Map </nenv>
          requires notBool X in_keys(Env)

      syntax Bool ::= hasSpecialDeclInArgLookup(CId, Map, Map) [function]

      rule <k> argDependentNameLookup(X::CId, Args::StrictList, _, cSet(Y::Map)) => resolveOverload(cSet(Y), Args, operator()) ...</k>
           <env> Env::Map </env>
           requires hasSpecialDeclInArgLookup(X, Y, Env)

      // 3.4.2:3.2
      rule hasSpecialDeclInArgLookup(X::CId, _, _::Map (X |-> ((T:CPPFunctionType |-> kpair(false, _)) _))) => true
      rule hasSpecialDeclInArgLookup(_, T::CPPType |-> _, _) => true
           requires notBool isCPPFunctionType(T)
      rule hasSpecialDeclInArgLookup(_, _, _) => false [owise]

      rule argDependentNameLookup(X::CId, Args::StrictList, krlist(Types::List), cSet(Y::Map)) => #argDependentNameLookup(X, Args, getAssociatedNamespaces(Types), cSet(Y))

      syntax List ::= getAssociatedNamespaces(List) [function]

      rule getAssociatedNamespaces((ListItem(T:CPPBasicType) => .List) L::List)
      rule getAssociatedNamespaces(ListItem(T::CPPType => innerType(T)) L::List)
           requires isCPPPointerType(T) orBool isCPPArrayType(T)
      rule getAssociatedNamespaces(.List) => .List

      rule #argDependentNameLookup(_, Args::StrictList, .List, cSet(Y::Map)) => resolveOverload(cSet(Y), Args, operator())

endmodule
