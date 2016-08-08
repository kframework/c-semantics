module CPP-DECL-NAMESPACE
     imports C-CONFIGURATION
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ENV-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TRANSLATION-INIT-SYNTAX

     syntax Decl ::= NamespaceNameDecl(Expr, Bool, List) [strict(1)]

     rule NamespaceDecl(X::CId, IsInline::Bool, Decls::List) => NamespaceNameDecl(Name(NoNNS(), X), IsInline, Decls)

     rule <k> NamespaceNameDecl(nsRef(N::Namespace), false, Decls::List)
              => setScope(namespaceScope(N))
              ~> listToK(Decls)
              ~> setScope(OldScope)
          ...</k>
          <curr-scope> OldScope:NamespaceScope </curr-scope>

     rule <k> (.K => makeNs(N :: Namespace(X))) 
              ~> NamespaceNameDecl((notFound(X::CId) => nsRef(N :: Namespace(X))), false, Decls::List)
          ...</k>
          <curr-scope> namespaceScope(N::Namespace) </curr-scope>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv> Env::Map => Env[X <- nsRef(N :: Namespace(X))] </nenv>

endmodule
