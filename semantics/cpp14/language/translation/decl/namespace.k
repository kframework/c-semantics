module CPP-DECL-NAMESPACE
     imports C-CONFIGURATION
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-ENV-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TRANSLATION-INIT-SYNTAX

     syntax Decl ::= NamespaceNameDecl(Expr, Bool, List) [strict(1)]

     rule NamespaceDecl(X::CId, IsInline::Bool, Decls::List) => NamespaceNameDecl(Name(NoNNS(), X), IsInline, Decls)
          requires X =/=K #NoName

     rule <k> NamespaceNameDecl(nsRef(N::Namespace), false, Decls::List)
              => setScope(namespaceScope(N))
              ~> listToK(Decls)
              ~> setScope(OldScope)
          ...</k>
          <curr-scope> OldScope:NamespaceScope </curr-scope>

     rule <k> (.K => addInlineNamespace(N, N) ~> addUsingDirective(N))
              ~> NamespaceNameDecl(nsRef(N::Namespace), (true => false), _)
          ...</k>
          <ns-id> N </ns-id>
          <is-inline> _ => true </is-inline>

     rule <k> (.K => makeNs(N :: Namespace(X))) 
              ~> NamespaceNameDecl((notFound(X::CId) => nsRef(N :: Namespace(X))), _, _)
          ...</k>
          <curr-scope> namespaceScope(N::Namespace) </curr-scope>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nested-namespaces> Env::Map => Env[X <- N :: Namespace(X)] </nested-namespaces>

      syntax KItem ::= addInlineNamespace(Namespace, Namespace)
                     | addUsingDirective(Namespace)
      // the global namespace cannot be inline, because it's implicitly declared
      rule <k> addInlineNamespace((Enclosing::Namespace :: _) => Enclosing, N::Namespace) ...</k>
           <ns-id> Enclosing </ns-id>
           <inline-namespaces>... .Set => SetItem(N) ...</inline-namespaces>
           <is-inline> true </is-inline>
      rule <k> addInlineNamespace(Enclosing::Namespace :: _, N::Namespace) => .K ...</k>
           <ns-id> Enclosing </ns-id>
           <inline-namespaces>... .Set => SetItem(N) ...</inline-namespaces>
           <is-inline> false </is-inline>

      // transitivity is handled in expr/name.k because if namespace A uses namespace B and namespace B uses namespace C, and namespace C is later redefined to use namespace D, then namespaces A and B need to use namespace D. If we tried to handle it here, then we would
      // need to track some kind of "used-by".
      rule <k> addUsingDirective(N::Namespace) => .K ...</k>
           <curr-scope> namespaceScope(Enclosing::Namespace) </curr-scope>
           <ns-id> Enclosing </ns-id>
           <using-namespaces>... .Set => SetItem(N) ...</using-namespaces>

endmodule
