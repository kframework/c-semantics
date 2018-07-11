module CPP-TRANSLATION-DECL-TYPEDEF
     imports C-CONFIGURATION
     imports COMPAT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule <k> TypedefDecl(X::CId, t(Q::Quals, Mods::Set, T::CPPSimpleType)) => .K ...</k>
          <curr-tr-scope> namespaceScope(N::Namespace) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <ntypes> Env::Map => Env[X <- t(Q, Mods, T)] </ntypes>

     rule <k> TypedefDecl(X::CId, t(Q::Quals, Mods::Set, T::CPPSimpleType)) => .K ...</k>
          <curr-tr-scope> templateParameterScope </curr-tr-scope>
          <tr-types> Env::Map => Env[X <- t(Q, Mods, T)] </tr-types>

endmodule
