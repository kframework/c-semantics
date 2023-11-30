module LINKING-CPP-RESOLUTION-SYNTAX
     imports SET

     syntax KItem ::= resolveCPPReferences(Set)
     syntax Bool ::= hasCPPMain() [function]

endmodule

module LINKING-CPP-RESOLUTION
     imports LINKING-CPP-RESOLUTION-SYNTAX
     imports LINKING-C-RESOLUTION-SYNTAX
     imports C-CONFIGURATION
     imports STRING
     imports COMMON-TRANSLATION-UNIT-SYNTAX
     imports ERROR-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-SYMLOC-SYNTAX
     imports CPP-TYPE-MAP-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule (.K => resolveCPPReference(Base))
          ~> resolveCPPReferences((SetItem(Base::SymBase) => .Set) _::Set)
          [structural]
     rule resolveCPPReferences(.Set) => .K
          [structural]

     // used by local statics
     syntax KItem ::= resolveCPPReference(SymBase)
     rule <k> resolveCPPReference(OdrBase:DirectBase) ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(odrDecl(_Tu::String, QX::QualId, _, _, T::CPPType)) => .Set) _::Set
          ...</odr-decls>
          <odr-defs>... QX |-> (stripType(T) |-> _ _::Map) ...</odr-defs>

     rule <k> resolveCPPReference(Base::SymBase) => .K ...</k>
          <odr-decls>...
               Base::SymBase |-> .Set => .Map
          ...</odr-decls>

     rule <k> resolveCPPReference(OdrBase:LinkBase) ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(odrDecl(Tu::String, N:Namespace :: X::CId, _, _, T::CPPType)) => .Set) _::Set
          ...</odr-decls>
          <odr-defs>... N :: X |-> (stripType(T) |-> (_, Base'::SymBase) _::Map) ...</odr-defs>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> (stripType(T) |-> (_, envEntry(... base: Base::SymBase => Base')) _::Map) ...</nenv>
          <linkings>... .Map => Base |-> Base' ...</linkings>

     rule <k> resolveCPPReference(OdrBase::SymBase) ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(odrDecl(Tu::String, N:Namespace :: X::CId, _, _, T::CPPType)) => .Set) _::Set
          ...</odr-decls>
          <odr-defs>... N :: X |-> (stripType(T) |-> _ _::Map) ...</odr-defs>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> (stripType(T) |-> (_, envEntry(... base: _:DirectBase)) _::Map) ...</nenv>

     rule <k> resolveCPPReference(OdrBase::SymBase) ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(odrDecl(Tu::String, N::Namespace :: X::CId, Mangled::CId, _, T::CPPType)) => .Set) _::Set
          ...</odr-decls>
          <odr-defs> Defs::Map </odr-defs>
          <external-defs>... Mangled |-> Base':SymBase ...</external-defs>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> (stripType(T) |-> (_, envEntry(... base: Base:LinkBase => Base')) _::Map) ...</nenv>
          <linkings>... .Map => Base |-> Base' ...</linkings>
          requires notBool (N :: X, T in_keys(Defs))

     rule <k> resolveCPPReference(OdrBase::SymBase) ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(odrDecl(Tu::String, N::Namespace :: X::CId, Mangled::CId, _, T::CPPType)) => .Set) _::Set
          ...</odr-decls>
          <external-defs>... Mangled |-> _ ...</external-defs>
          <tu-id> Tu </tu-id>
          <ns-id> N </ns-id>
          <nenv>... X |-> (stripType(T) |-> (_, envEntry(... base: _:DirectBase)) _::Map) ...</nenv>

     rule <k> (.K => ILL("TDR3",
                    "No definition for function or variable which was odr-used: "
                    +String showSignature(N :: X, T) +String "."))
              ~> resolveCPPReference(OdrBase::SymBase)
          ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(odrDecl(_, N::Namespace :: X::CId, Mangled::CId, _, T::CPPType))) _::Set
          ...</odr-decls>
          <external-defs> CDefs::Map </external-defs>
          <odr-defs> Defs::Map </odr-defs>
          requires notBool (N :: X, T in_keys(Defs))
               andBool notBool (Mangled in_keys(CDefs))

     // this case arises when the C++ language directly references a symbol in
     // the standard library which is never declared at linking-time because
     // the user did not link against libstdc++.so (presumably because they
     // made the mistake of running kcc instead of k++)
     rule <k> (.K => ILL("TDR3",
                    "No definition for function or variable which was odr-used: "
                    +String Symbol +String "."))
              ~> resolveCPPReference(obj(_, _, builtinCppSymbol(Symbol::String)) #as OdrBase::SymBase)
          ...</k>
          <odr-decls> Decls::Map </odr-decls>
          requires notBool OdrBase in_keys(Decls)

     rule [[ hasCPPMain() => true ]]
          <odr-defs>... GlobalNamespace() :: Identifier("main") |-> _ ...</odr-defs>

     rule hasCPPMain() => false [owise]

     rule <k> resolveMain => .K ...</k>
          <main-tu>... (.Set => SetItem(MainTu)) </main-tu>
          <odr-defs>... GlobalNamespace() :: Identifier("main") |-> (_::CPPType |-> (_, obj(... d: static(MainTu:String)))) ...</odr-defs>

     // TODO(dwightguth): make this a better error message when we take the C++ semantics live
     // currently this error is both a C++ and a C error, since either C or C++ is allowed
     // to declare the main function. We need a special error category for this, but it's
     // low priority, so for now we just default to the C error message in order to not
     // confuse anyone using RV-Match for C.
     rule <k> (.K => setTranslationLoc(UnknownCabsLoc)
                  ~> EXT-UNDEF("TDR2", "No definition for symbol with external linkage: main."))
              ~> resolveMain
          ...</k>
          <external-defs> CDefs:Map </external-defs>
          <odr-defs> Defs::Map </odr-defs>
          requires notBool (Identifier("main") in_keys(CDefs))
               andBool notBool (GlobalNamespace() :: Identifier("main") in_keys(Defs))

     // Linking resolution for class members with static storage
     rule <k> resolveCPPReference(OdrBase::SymBase) ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(odrDecl(Tu::String, C:Class :: X::CId, _, _, T::CPPType)) => .Set) _::Set
          ...</odr-decls>
          <odr-defs>... C :: X |-> (stripType(T) |-> (_, Base'::SymBase) _::Map) ...</odr-defs>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <cenv>... X |-> (stripType(T) |-> (_, envEntry(... base: (Base:LinkBase => Base'))) _::Map) ...</cenv>
          <linkings>... .Map => Base |-> Base' ...</linkings>

     rule <k> resolveCPPReference(OdrBase::SymBase) ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(odrDecl(Tu::String, C:Class :: X::CId, _, _, T::CPPType)) => .Set) _::Set
          ...</odr-decls>
          <odr-defs>... C :: X |-> (stripType(T) |-> _ _::Map) ...</odr-defs>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <cenv>... X |-> (stripType(T) |-> (_, envEntry(... base: _:DirectBase)) _::Map) ...</cenv>

endmodule
