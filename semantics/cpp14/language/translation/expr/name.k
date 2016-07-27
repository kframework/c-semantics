module CPP-EXPR-NAME
     imports COMPAT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-OVERLOADING-SYNTAX
     imports CPP-TYPING-EXPR-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports C-CONFIGURATION

     rule CallExpr(Name(NoNNS(), X::CId), Args::StrictList) => argDependentNameLookup(X, Args, Args, nameLookup(X))

     rule Name(NoNNS(), X::CId) => resolveUniqueDecl(nameLookup(X), Name(NoNNS(), X))

     rule (.K => nsRef(GlobalNamespace())) ~> Name(GlobalNamespace(), _)
     rule (.K => nameLookup(X)) ~> Name(NNS(X::CId), _)
     rule nsRef(N::Namespace) ~> Name(_, X::CId) => qualifiedNameLookup(X, N)

     syntax Expr ::= argDependentNameLookup(CId, StrictList, StrictList, Expr) [strict(4)]
                   | #argDependentNameLookup(CId, StrictList, List, CandidateSet)
                   | nameLookup(CId)
                   | nameLookupInNamespace(CId, Namespace)
                   | qualifiedNameLookup(CId, Namespace)

     rule <k> nameLookup(X::CId) => cSet(S) ...</k>
          <curr-scope> _:BlockScope </curr-scope>
          <env>... X |-> S::Map ...</env>

     rule <k> nameLookup(X::CId) => nameLookupInNamespace(X, N) ...</k>
          <curr-scope> namespaceScope(N::Namespace) </curr-scope>

     rule <k> nameLookup(X::CId) => nameLookupInNamespace(X, N) ...</k>
          <curr-scope> blockScope(N::Namespace :: _, _, _) </curr-scope>
          <env> Env::Map </env>
          requires notBool X in_keys(Env)

     rule <k> nameLookupInNamespace(X::CId, N::Namespace) => cSet(S) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> S:Map ...</nenv>

     rule <k> nameLookupInNamespace(X::CId, N::Namespace) => NS ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> NS:NSRef ...</nenv>

     rule <k> nameLookupInNamespace(X::CId, N::Namespace) => T ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> T:CPPType ...</nenv>

     rule <k> nameLookupInNamespace(X::CId, N::Namespace :: S::NamespaceSpecifier) => nameLookupInNamespace(X, N) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N :: S </ns-id>
          <nenv> Env::Map </nenv>
          <using-namespaces> .Set </using-namespaces>
          requires notBool X in_keys(Env)

     rule <k> nameLookupInNamespace(X::CId, GlobalNamespace()) => notFound(X) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> GlobalNamespace() </ns-id>
          <nenv> Env::Map </nenv>
          <using-namespaces> .Set </using-namespaces>
          requires notBool X in_keys(Env)


     context argDependentNameLookup(_, _, (HOLE:StrictList => types(HOLE)), _)

     rule <k> argDependentNameLookup(X::CId, Args::StrictList, _, cSet(Y::Map)) => resolveOverload(cSet(Y), Args, operator()) ...</k>
           <env> Env::Map </env>
           requires hasSpecialDeclInArgLookup(X, Y, Env)

     syntax Bool ::= hasSpecialDeclInArgLookup(CId, Map, Map) [function]
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

     rule <k> qualifiedNameLookup(X::CId, N::Namespace) => T ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> T:CPPType ...</nenv>
          <inline-namespaces> .Set </inline-namespaces>

endmodule
