module C-LINKING-RESOLUTION-SYNTAX
     imports BASIC-K

     syntax KItem ::= "resolveReferences"
     syntax KItem ::= "removeUnusedIdentifiers"
     syntax Bool ::= isCLinkage(K) [function]
endmodule

module C-LINKING-RESOLUTION
     imports C-LINKING-RESOLUTION-SYNTAX

     imports COMPAT-SYNTAX
     imports ERROR-SYNTAX
     imports SYMLOC-SYNTAX

     imports C-CONFIGURATION

     // Add the real location at which an external reference is defined to the
     // environment of every TU where it appears.

     syntax KItem ::= resolveReference(CId)
                    | resolveCPPReference(SymBase)
                    | "resolveMain"

     rule <k> (.K => resolveReference(X)) ~> resolveReferences ...</k>
          <external-uses> (SetItem(X:CId) => .Set) ...</external-uses>
          [structural]

     rule <k> (.K => resolveCPPReference(Base)) ~> resolveReferences ...</k>
          <odr-uses> (SetItem(Base::SymBase) => .Set) ...</odr-uses>

     rule <k> resolveReference(X:CId) ...</k>
          <external-decls>...
               X |-> (SetItem(Tu:String) => .Set) _::Set
          ...</external-decls>
          <external-defs>... X |-> Base':SymBase ...</external-defs>
          <tu-id> Tu </tu-id>
          <genv>... X |-> (Base:SymBase => Base') ...</genv>
          <linkings>... (.Map => Base |-> Base') ...</linkings>
          requires isLinkerLoc(Base)
          [structural]

     rule <k> resolveReference(X:CId) ...</k>
          <external-decls>...
               X |-> (SetItem(Tu:String) => .Set) _::Set
          ...</external-decls>
          <external-defs>... X |-> _ ...</external-defs>
          <tu-id> Tu </tu-id>
          <genv>... X |-> Base:SymBase ...</genv>
          requires notBool isLinkerLoc(Base)
          [structural]

     rule <k> resolveReference(X:CId) => .K  ...</k>
          <external-decls>...
               (X:CId |-> .Set => .Map)
          ...</external-decls>
          <external-defs>... X |-> _ ...</external-defs>
          <external-types>... X |-> _ ...</external-types>
          [structural]

     rule <k> resolveCPPReference(OdrBase::SymBase) ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(ktriple(Tu::String, N::Namespace :: X::CId, T:K)) => .Set) _::Set
          ...</odr-decls>
          <odr-defs>... N :: X |-> (T |-> Base'::SymBase _::Map) ...</odr-defs>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> (T |-> kpair(_, (Base::SymBase => Base')) _::Map) ...</nenv>
          <linkings>... (.Map => Base |-> Base') ...</linkings>
          requires isLinkerLoc(Base)

     rule <k> resolveCPPReference(OdrBase::SymBase) ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(ktriple(Tu::String, N::Namespace :: X::CId, T:K)) => .Set) _::Set
          ...</odr-decls>
          <odr-defs>... N :: X |-> (T |-> _ _::Map) ...</odr-defs>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> (T |-> kpair(_, Base::SymBase) _::Map) ...</nenv>
          requires notBool isLinkerLoc(Base)

     rule <k> resolveCPPReference(OdrBase::SymBase) ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(ktriple(Tu::String, N::Namespace :: X::CId, T:K)) => .Set) _::Set
          ...</odr-decls>
          <external-defs>... X |-> Base'::SymBase ...</external-defs>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> (T |-> kpair(_, (Base::SymBase => Base')) _::Map) ...</nenv>
          <linkings>... (.Map => Base |-> Base') ...</linkings>
          requires isLinkerLoc(Base) andBool isCLinkage(T)

     rule <k> resolveCPPReference(OdrBase::SymBase) ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(ktriple(Tu::String, N::Namespace :: X::CId, T:K)) => .Set) _::Set
          ...</odr-decls>
          <external-defs>... X |-> _ ...</external-defs>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> (T |-> kpair(_, Base::SymBase) _::Map) ...</nenv>
          requires notBool isLinkerLoc(Base) andBool isCLinkage(T)

     rule <k> resolveCPPReference(Base::SymBase) => .K ...</k>
          <odr-decls>...
               (Base::SymBase |-> .Set => .Map)
          ...</odr-decls>

     rule <k> (.K => UNDIAG("TDR3",
                    "No definition for function or variable which was odr-used: "
                    +String idToString(N :: X) +String ".",
                    "3.2:4"))
              ~> resolveCPPReference(OdrBase::SymBase) ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(ktriple(_, N::Namespace :: X::CId, T:K))) _::Set
          ...</odr-decls>
          <external-defs> CDefs::Map </external-defs>
          <odr-defs> Defs::Map </odr-defs>
          requires notBool (T in_keys(Defs[N :: X]:>Map))
               andBool notBool (X in_keys(CDefs))

     rule <k> (.K => EXT-UNDEF("TDR2",
                    "No definition for symbol with external linkage: "
                     +String idToString(X) +String ".",
                    "C11", "6.9:5, J.2:1 item 84"))
              ~> resolveReference(X:CId)
          ...</k>
          <external-defs> Defs:Map </external-defs>
          <external-types> Types:Map </external-types>
          requires notBool (X in_keys(Defs))
               orBool notBool (X in_keys(Types))
          [structural]

     // Now everything left in <external-uses> should be an unresolved
     // reference.
     rule <k> resolveReferences => resolveMain ...</k>
          <external-uses> .Set </external-uses>
          <odr-uses> .Set </odr-uses>

     // Remember which TU has the definition of main.
     rule <k> resolveMain => .K ...</k>
          <main-tu>... (.Set => SetItem(MainTu)) </main-tu>
          (<linking-state>... .Bag ...</linking-state> => .Bag)
          <external-defs>...
               Identifier("main") |-> _ @ static(MainTu:String)
          ...</external-defs>
          <external-types>...
               Identifier("main") |-> _
          ...</external-types>
          [structural]

     rule <k> resolveMain => .K ...</k>
          <main-tu>... (.Set => SetItem(MainTu)) </main-tu>
          (<linking-state>... .Bag ...</linking-state> => .Bag)
          <odr-defs>... GlobalNamespace() :: Identifier("main") |-> (_ |-> _ @ static(MainTu:String)) ...</odr-defs>

     // TODO(dwightguth): make this a better error message when we take the C++ semantics live
     rule <k> (.K => EXT-UNDEF("TDR2",
                    "No definition for symbol with external linkage: main.",
                    "C11", "6.9:5, J.2:1 item 84"))
              ~> resolveMain
          ...</k>
          <external-defs> CDefs:Map </external-defs>
          <odr-defs> Defs::Map </odr-defs>
          requires notBool (Identifier("main") in_keys(CDefs))
               andBool notBool (GlobalNamespace() :: Identifier("main") in_keys(Defs))

     syntax KItem ::= removeFromExternalDecls(List)

     rule <k> removeUnusedIdentifiers => removeFromExternalDecls(Set2List(keys(Env) -Set Uses)) ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <genv> Env:Map => removeAll(Env, (keys(Env) -Set Uses)) </genv>
          <gtypes> Types:Map => removeAll(Types, (keys(Types) -Set Uses)) </gtypes>
          (<tu-linking-state>...
               <uses> Uses:Set </uses>
          ...</tu-linking-state> => .Bag)

     rule <k> removeFromExternalDecls((ListItem(X:CId) => .List) _) ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <external-decls>... X |-> (SetItem(Tu) => .Set) _::Set ...</external-decls>
     rule <k> removeFromExternalDecls((ListItem(X:CId) => .List) _) ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <external-decls> Decls:Map </external-decls>
          requires notBool (X in_keys(Decls))
     rule removeFromExternalDecls(.List) => .K


endmodule
