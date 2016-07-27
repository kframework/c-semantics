module CPP-DECL-TYPEDEF
     imports C-CONFIGURATION
     imports CPP-TYPING-SYNTAX

     rule <k> TypedefDecl(X::CId, t(Q::Quals, Mods::Set, T::CPPSimpleType)) => .K ...</k>
          <curr-scope> namespaceScope(N::Namespace) </curr-scope>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv> Env::Map => Env[X <- t(Q, Mods, T)] </nenv>

endmodule
