module CPP-EXPR-NAME-SYNTAX
     imports COMMON-SORTS
     imports CPP-SORTS
     syntax Expr ::= nameLookup(CId, Tag)
endmodule

module CPP-EXPR-NAME
     imports CPP-EXPR-NAME-SYNTAX
     imports C-CONFIGURATION
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-SYNTAX
     imports K-EQUAL

     syntax Expr ::= nameLookupInNamespace(CId, Namespace, Tag)

     syntax Namespace ::= getInnermostNamespace(Scope) [function, klabel(getInnermostNamespace1)]
     rule getInnermostNamespace(blockScope(N:Namespace :: _, _, _)) => N
     rule getInnermostNamespace(classScope(N:Namespace :: _)) => N
     rule getInnermostNamespace(namespaceScope(N::Namespace)) => N

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, NoTag()) => nsRef(NS) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nested-namespaces>... X |-> NS::Namespace ...</nested-namespaces>

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, Tag::Tag) => T ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <ntypes>... X |-> (_ Tag |-> T::CPPType) ...</ntypes>

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, NoTag()) => T ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <ntypes>... X |-> (_ |-> T::CPPType) ...</ntypes>

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, NoTag()) => templateRef(N :: X, T) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <templates>... N :: X |-> (_ T:CPPClassTypeExpr |-> _) ...</templates>

     rule <k> nameLookupInNamespace(X::CId, N::Namespace, Tag::Tag) => templateRef(N :: X, T) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <templates>... N :: X |-> (_ T:CPPClassTypeExpr |-> _) ...</templates>
          requires getTag(T) ==K Tag

     rule <k> nameLookupInNamespace(X::CId, N::Namespace :: S::NamespaceSpecifier, T::Tag) => nameLookupInNamespace(X, N, T) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N :: S </ns-id>
          <nenv> NE::Map </nenv>
          <ntypes> NT::Map </ntypes>
          <nested-namespaces> NN::Map </nested-namespaces>
          <templates> TP::Map </templates>
          <using-namespaces> .Set </using-namespaces>
          requires notBool X in_keys(NE) andBool notBool X in_keys(NT) andBool notBool X in_keys(NN)
               andBool notBool N :: S :: X in_keys(TP)

     rule <k> nameLookupInNamespace(X::CId, GlobalNamespace(), _) => notFound(X) ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> GlobalNamespace() </ns-id>
          <nenv> NE::Map </nenv>
          <ntypes> NT::Map </ntypes>
          <nested-namespaces> NN::Map </nested-namespaces>
          <templates> T::Map </templates>
          <using-namespaces> .Set </using-namespaces>
          requires notBool X in_keys(NE) andBool notBool X in_keys(NT) andBool notBool X in_keys(NN)
               andBool notBool GlobalNamespace() :: X in_keys(T)


endmodule
