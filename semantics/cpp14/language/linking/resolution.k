module CPP-LINKING-RESOLUTION
     imports C-LINKING-RESOLUTION-SYNTAX
     imports COMMON-RESOLUTION-SYNTAX
     imports C-CONFIGURATION
     imports COLLECTIONS
     imports LIST
     imports MAP
     imports STRING
     imports COMPAT-SYNTAX
     imports ERROR-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-TYPE-MAP-SYNTAX

     // used by local statics
     rule <k> resolveCPPReference(OdrBase::SymBase) ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(ktriple(Tu::String, QX::QualId, T::CPPType)) => .Set) _::Set
          ...</odr-decls>
          <odr-defs>... QX |-> (T |-> _ _::TypeMap) ...</odr-defs>
          requires notBool isLinkerLoc(OdrBase)

     rule <k> resolveCPPReference(Base::SymBase) => .K ...</k>
          <odr-decls>...
               (Base::SymBase |-> .Set => .Map)
          ...</odr-decls>

     rule <k> resolveCPPReference(OdrBase::SymBase) ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(ktriple(Tu::String, N:Namespace :: X::CId, T::CPPType)) => .Set) _::Set
          ...</odr-decls>
          <odr-defs>... N :: X |-> (T |-> Base'::SymBase _::TypeMap) ...</odr-defs>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> (T |-> envEntry(... base: Base::SymBase => Base') _::TypeMap) ...</nenv>
          <linkings>... (.Map => Base |-> Base') ...</linkings>
          requires isLinkerLoc(Base)

     rule <k> resolveCPPReference(OdrBase::SymBase) ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(ktriple(Tu::String, N:Namespace :: X::CId, T::CPPType)) => .Set) _::Set
          ...</odr-decls>
          <odr-defs>... N :: X |-> (T |-> _ _::TypeMap) ...</odr-defs>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> (T |-> envEntry(... base: Base::SymBase) _::TypeMap) ...</nenv>
          requires notBool isLinkerLoc(Base)

     rule <k> resolveCPPReference(OdrBase::SymBase) ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(ktriple(Tu::String, N::Namespace :: X::CId, T::CPPType)) => .Set) _::Set
          ...</odr-decls>
          <external-defs>... X |-> Base':SymBase ...</external-defs>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> (T |-> envEntry(... base: Base::SymBase => Base') _::TypeMap) ...</nenv>
          <linkings>... (.Map => Base |-> Base') ...</linkings>
          requires isLinkerLoc(Base) andBool isCLinkage(T)

     rule <k> resolveCPPReference(OdrBase::SymBase) ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(ktriple(Tu::String, N::Namespace :: X::CId, T::CPPType)) => .Set) _::Set
          ...</odr-decls>
          <external-defs>... X |-> _ ...</external-defs>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> (T |-> envEntry(... base: Base::SymBase) _::TypeMap) ...</nenv>
          requires notBool isLinkerLoc(Base) andBool isCLinkage(T)

     rule <k> (.K => ILL("TDR3",
                    "No definition for function or variable which was odr-used: "
                    +String signatureToString(N :: X, T) +String "."))
              ~> resolveCPPReference(OdrBase::SymBase) ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(ktriple(_, N::Namespace :: X::CId, T::CPPType))) _::Set
          ...</odr-decls>
          <external-defs> CDefs::Map </external-defs>
          <odr-defs> Defs::Map </odr-defs>
          requires notBool (N :: X, T in_keys(Defs))
               andBool notBool (X in_keys(CDefs))

     // this case arises when the C++ language directly references a symbol in
     // the standard library which is never declared at linking-time because
     // the user did not link against libstdc++.so (presumably because they
     // made the mistake of running kcc instead of k++)
     rule <k> (.K => ILL("TDR3",
                    "No definition for function or variable which was odr-used: "
                    +String Symbol +String "."))
              ~> resolveCPPReference(obj(_, _, builtinSymbol(Symbol::String)) #as OdrBase::SymBase) ...</k>
          <odr-decls> Decls::Map </odr-decls>
          requires notBool OdrBase in_keys(Decls)

     rule <k> resolveMain => .K ...</k>
          <main-tu>... (.Set => SetItem(MainTu)) </main-tu>
          (<linking-state>... .Bag ...</linking-state> => .Bag)
          <odr-defs>... GlobalNamespace() :: Identifier("main") |-> (_::CPPType |-> obj(... d: static(MainTu:String))) ...</odr-defs>


     // TODO(dwightguth): make this a better error message when we take the C++ semantics live
     // currently this error is both a C++ and a C error, since either C or C++ is allowed
     // to declare the main function. We need a special error category for this, but it's
     // low priority, so for now we just default to the C error message in order to not
     // confuse anyone using RV-Match for C.
     rule <k> (.K => EXT-UNDEF("TDR2",
                    "No definition for symbol with external linkage: main."))
              ~> resolveMain
          ...</k>
          <external-defs> CDefs:Map </external-defs>
          <odr-defs> Defs::Map </odr-defs>
          requires notBool (Identifier("main") in_keys(CDefs))
               andBool notBool (GlobalNamespace() :: Identifier("main") in_keys(Defs))

     // Linking resolution for class members with static storage
     rule <k> resolveCPPReference(OdrBase::SymBase) ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(ktriple(Tu::String, C:Class :: X::CId, T::CPPType)) => .Set) _::Set
          ...</odr-decls>
          <odr-defs>... C :: X |-> (T |-> Base'::SymBase _::TypeMap) ...</odr-defs>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <cenv>... X |-> (T |-> envEntry(... base: (Base::SymBase => Base')) _::TypeMap) ...</cenv>
          <linkings>... (.Map => Base |-> Base') ...</linkings>
          requires isLinkerLoc(Base)

     rule <k> resolveCPPReference(OdrBase::SymBase) ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(ktriple(Tu::String, C:Class :: X::CId, T::CPPType)) => .Set) _::Set
          ...</odr-decls>
          <odr-defs>... C :: X |-> (T |-> _ _::TypeMap) ...</odr-defs>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <cenv>... X |-> (T |-> envEntry(... base: Base::SymBase) _::TypeMap) ...</cenv>
          requires notBool isLinkerLoc(Base)

endmodule
