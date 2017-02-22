module C-LINKING-RESOLUTION-SYNTAX
     imports COMMON-RESOLUTION-SYNTAX

     syntax KItem ::= "resolveReferences"
     syntax KItem ::= "removeUnusedIdentifiers"
     syntax Bool ::= isCLinkage(K) [function]
endmodule

module C-LINKING-RESOLUTION
     imports C-LINKING-RESOLUTION-SYNTAX
     imports C-CONFIGURATION
     imports COLLECTIONS
     imports LIST
     imports MAP
     imports STRING
     imports COMMON-SORTS
     imports COMPAT-SYNTAX
     imports ERROR-SYNTAX
     imports SYMLOC-SYNTAX

     // Add the real location at which an external reference is defined to the
     // environment of every TU where it appears.

     syntax KItem ::= resolveReference(CId)
                    | resolveReferences(Map)
                    | "resolveMain"

     rule <k> resolveReferences => resolveReferences(Uses) ...</k>
          <external-uses> Uses:Map => .Map </external-uses>

     rule <k> (.K => resolveReference(X))
               ~> resolveReferences((X:CId |-> L:CabsLoc => .Map) _)
          ...</k>
          <curr-program-loc> _ => L </curr-program-loc>
          [structural]

     rule <k> (.K => resolveCPPReference(Base)) ~> resolveReferences(_) ...</k>
          <odr-uses> SetItem(Base::SymBase) => .Set ...</odr-uses>

     rule <k> resolveReference(X:CId) ...</k>
          <external-decls>...
               X |-> (SetItem(Tu:String) => .Set) _::Set
          ...</external-decls>
          <external-defs>... X |-> Base':SymBase ...</external-defs>
          <tu-id> Tu </tu-id>
          <genv>... X |-> (Base:SymBase => Base') ...</genv>
          <linkings>... .Map => Base |-> Base' ...</linkings>
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
               X:CId |-> .Set => .Map
          ...</external-decls>
          <external-defs>... X |-> _ ...</external-defs>
          <external-types>... X |-> _ ...</external-types>
          [structural]

     rule <k> resolveCPPReference(OdrBase::SymBase) ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(ktriple(Tu::String, N:Namespace :: X::CId, T:K)) => .Set) _::Set
          ...</odr-decls>
          <odr-defs>... N :: X |-> (T |-> Base'::SymBase _::Map) ...</odr-defs>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> (T |-> kpair(_, (Base::SymBase => Base')) _::Map) ...</nenv>
          <linkings>... (.Map => Base |-> Base') ...</linkings>
          requires isLinkerLoc(Base)

     // used by local statics
     rule <k> resolveCPPReference(OdrBase::SymBase) ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(ktriple(Tu::String, QX::QualId, T:K)) => .Set) _::Set
          ...</odr-decls>
          <odr-defs>... QX |-> (T |-> _ _::Map) ...</odr-defs>
          requires notBool isLinkerLoc(OdrBase)

     rule <k> resolveCPPReference(OdrBase::SymBase) ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(ktriple(Tu::String, N:Namespace :: X::CId, T:K)) => .Set) _::Set
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
          <external-defs>... X |-> Base':SymBase ...</external-defs>
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

     rule <k> (.K => ILL("TDR3",
                    "No definition for function or variable which was odr-used: "
                    +String signatureToString(N :: X, T) +String "."))
              ~> resolveCPPReference(OdrBase::SymBase) ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(ktriple(_, N::Namespace :: X::CId, T:K))) _::Set
          ...</odr-decls>
          <external-defs> CDefs::Map </external-defs>
          <odr-defs> Defs::Map </odr-defs>
          requires notBool (N :: X, T in_keys(Defs))
               andBool notBool (X in_keys(CDefs))

     rule <k> (.K => EXT-UNDEF("TDR2",
                    "No definition for symbol with external linkage: "
                     +String idToString(X) +String "."))
              ~> resolveReference(X:CId)
          ...</k>
          <external-defs> Defs:Map </external-defs>
          <external-types> Types:Map </external-types>
          requires notBool (X in_keys(Defs))
               orBool notBool (X in_keys(Types))
          [structural]

     // Now everything left in <external-uses> should be an unresolved
     // reference.
     rule <k> resolveReferences(.Map) => resolveMain ...</k>
          <external-uses> .Map </external-uses>
          <odr-uses> .Set </odr-uses>
          <curr-program-loc> _ => UnknownCabsLoc </curr-program-loc>

     // Remember which TU has the definition of main.
     rule <k> resolveMain => .K ...</k>
          <main-tu>... .Set => SetItem(MainTu) </main-tu>
          (<linking-state>... .Bag ...</linking-state> => .Bag)
          <external-defs>...
               Identifier("main") |-> obj(... d: static(MainTu:String))
          ...</external-defs>
          <external-types>...
               Identifier("main") |-> _
          ...</external-types>
          [structural]

     rule <k> resolveMain => .K ...</k>
          <main-tu>... (.Set => SetItem(MainTu)) </main-tu>
          (<linking-state>... .Bag ...</linking-state> => .Bag)
          <odr-defs>... GlobalNamespace() :: Identifier("main") |-> (_ |-> obj(... d: static(MainTu:String))) ...</odr-defs>

     // TODO(dwightguth): make this a better error message when we take the C++ semantics live
     rule <k> (.K => EXT-UNDEF("TDR2",
                    "No definition for symbol with external linkage: main."))
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
          <external-decls>... X |-> (SetItem(Tu) S::Set => S) ...</external-decls>
          requires S =/=K .Set
     rule <k> removeFromExternalDecls((ListItem(X:CId) => .List) _) ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <external-decls>... X |-> SetItem(Tu) => .Map ...</external-decls>
     rule <k> removeFromExternalDecls((ListItem(X:CId) => .List) _) ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <external-decls> Decls:Map </external-decls>
          requires notBool (X in_keys(Decls))
     rule removeFromExternalDecls(.List) => .K

endmodule
