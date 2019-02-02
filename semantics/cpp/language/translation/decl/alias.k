module CPP-TRANSLATION-DECL-ALIAS
     imports C-CONFIGURATION
     imports COMPAT-SYNTAX
     imports CPP-ABSTRACT-SYNTAX
     imports CPP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule <k> TypeAliasDecl(X::CId, t(Q::Quals, Mods::Set, T::CPPSimpleType)) => .K ...</k>
          <curr-tr-scope> namespaceScope(N::Namespace) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <ntypes> Env::Map => Env[X <- t(Q, Mods, T)] </ntypes>

     rule <k> TypeAliasDecl(X::CId, t(Q::Quals, Mods::Set, T::CPPSimpleType)) => .K ...</k>
          <curr-tr-scope> classScope(C::Class, _) </curr-tr-scope>
          <curr-tr-tu> Tu::String </curr-tr-tu> 
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <ctypes> Env::Map => Env[X <- t(Q, Mods, T)] </ctypes>
endmodule
