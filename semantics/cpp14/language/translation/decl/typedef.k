module CPP-DECL-TYPEDEF
     imports C-CONFIGURATION
     imports COMPAT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule <k> TypedefDecl(X::CId, t(Q::Quals, Mods::Set, T::CPPSimpleType)) => .K ...</k>
          <curr-scope> namespaceScope(N::Namespace) </curr-scope>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <ntypes> Env::Map => Env[X <- t(Q, Mods, T)] </ntypes>

     rule <k> TypedefDecl(X::CId, t(Q::Quals, Mods::Set, T::CPPSimpleType)) => .K ...</k>
          <curr-scope> templateParameterScope </curr-scope>
          <types> Env::Map => Env[X <- t(Q, Mods, T)] </types>

endmodule
