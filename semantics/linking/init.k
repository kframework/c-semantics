module LINKING-INIT-SYNTAX
     imports BASIC-K
     imports STRING-SYNTAX

     syntax KItem ::= load(K) [symbol]
     syntax KItem ::= linkProgram(entrypoint: String)

endmodule

module LINKING-INIT
     imports LINKING-INIT-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports K-REFLECTION
     imports STRING
     imports C-TYPING-SORTS
     imports COMMON-BUILTIN-SYNTAX
     imports COMMON-INIT-SYNTAX
     imports COMMON-LINKING-DEPS-SYNTAX
     imports COMMON-TRANSLATION-UNIT-SYNTAX
     imports COMPAT-SYNTAX
     imports ERROR-SYNTAX
     imports LIBC-TYPES-SYNTAX
     imports OPTIONS-SYNTAX
     imports CPP-BUILTIN-SYNTAX
     imports C-TYPING-COMMON-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports CPP-TRANSLATION-IMPLICIT-SYNTAX
     imports LINKING-C-RESOLUTION-SYNTAX
     imports LINKING-CPP-RESOLUTION-SYNTAX
     imports LINKING-C-BUILTIN-SYNTAX
     imports LINKING-CPP-BUILTIN-SYNTAX
     imports CPP-TYPE-MAP-SYNTAX
     imports SYMLOC-SYNTAX

     rule <k> linkProgram(Entrypoint::String)
               => cBuiltinTu("builtin")
               ~> cppBuiltinTu("cpp-builtin")
               ~> nativeTu("native")
               ~> resolveReferences(Entrypoint)
               ~> reportSuccess
          ...</k>
          <options>... SetItem(Link()) ...</options>

     rule <k> linkProgram(_) => reportSuccess ...</k>
          <options> Opts::Set </options>
          requires notBool Link() in Opts

     syntax KItem ::= cBuiltinTu(tu: String)
     rule <k> cBuiltinTu(Tu::String)
               => makeTu(Tu)
            // ~> checkExtTypes(.K, keys(builtins), builtins, keys(Types), Types, DeclLocs)
               ~> checkExtDefs(.K, keys(builtins), builtins, keys(Defs), Types, Locs)
               ~> addCBuiltins(Tu, builtins)
               ~> removeUnusedIdentifiers(Tu)
          ...</k>
          <external-types> Types:Map </external-types>
          <external-decls-loc> DeclLocs:Map </external-decls-loc>
          <external-defs> Defs:Map </external-defs>
          <external-defs-loc> Locs:Map </external-defs-loc>

     syntax KItem ::= cppBuiltinTu(tu: String)
     rule cppBuiltinTu(Tu::String)
          => makeTu(Tu)
          ~> makeNs(Tu, GlobalNamespace())
          ~> implicitDecls
          ~> addCppBuiltins(cppBuiltins, true)
          ~> removeUnusedIdentifiers(Tu)

     syntax KItem ::= nativeTu(tu: String)
     rule nativeTu(Tu::String)
          => makeTu(Tu)
          ~> addNativeSymbols(Tu, nativeDefinedBuiltins)
          ~> addCppBuiltins(weakCppBuiltins, false)
          ~> removeUnusedIdentifiers(Tu)

     // returns a map from
     syntax Map ::= reachableSymbols(entrypoint: String) [function]
                  | #reachableSymbols(Map, Map) [function]

     rule reachableSymbols(Entrypoint::String)
          => #reachableSymbols(.Map,
               (linkdepNode(Identifier(Entrypoint), external()) |-> UnknownCabsLoc)
               (notAFunction() |-> UnknownCabsLoc)
               )

     rule #reachableSymbols(Result, .Map) => Result

     rule [[ #reachableSymbols(Result::Map, M::Map)
          => #fun(Curr =>
               #reachableSymbols(
                    Result[Curr <- M[Curr]],
                    removeAll(updateMap(M, {Deps[Curr] orDefault .Map}:>Map), keys(Result) SetItem(Curr))
               )
             )(choice(M)) ]]
          <linking-deps> Deps </linking-deps>
          requires size(M) >=Int 1

     syntax Map ::= onlyExternal(Map) [function]

     rule onlyExternal(.Map) => .Map

     rule onlyExternal(M::Map)
          => #fun (Curr =>
               #if linkdepNode(_, external()) :=K Curr #then
                 linkdepNodeId(Curr) |-> M[Curr]
               #else .Map #fi
               onlyExternal(M[Curr <- undef])
             )(choice(M))
          requires size(M) >=Int 1

     syntax CId ::= linkdepNodeId(LinkdepNode) [function]
     rule linkdepNodeId(linkdepNode(X, _)) => X

     syntax KItem ::= resolveReferences(entrypoint: String)
     rule <k> resolveReferences(Entrypoint::String)
               => resolveMain
               ~> resolveCPPReferences(OdrUses)
               ~> #if hasCPPMain() #then
                    resolveCReferences(Uses)
                  #else
                    resolveCReferences(onlyExternal(reachableSymbols(Entrypoint)))
                  #fi
               ~> clearLinkingState()
          ...</k>
          <odr-uses> OdrUses::Set => .Set </odr-uses>
          <external-uses> Uses::Map => .Map </external-uses>

     syntax KItem ::= clearLinkingState()
     rule <k> clearLinkingState() => .K ...</k>
          (<linking-state>... .Bag ...</linking-state> => .Bag)

     syntax KItem ::= makeNs(tu: String, Namespace)
     rule <k> makeNs(Tu::String, N::Namespace) => .K ...</k>
          <tu-id> Tu </tu-id>
          <namespaces>...
               (.Bag => <ns>...
                             <ns-id> N </ns-id>
                        ...</ns>)
          ...</namespaces>

     rule load(Obj1:KItem ~> Obj2:KItem ~> Objs:K)
               => load(Objs ~> mergeObj(Obj1, Obj2))
               ~> checkMerge(Obj1, Obj2)

     rule <k> load(Merged:KItem)
               => loadObj(mergeObj(Merged, ThisObj))
               ~> checkMerge(Merged, ThisObj)
          ...</k>
          ThisObj:GlobalCell

     rule load(.K) => .K

     syntax KItem ::= checkMerge(K, K)
     rule checkMerge(_, .K) => .K
     rule checkMerge(.K, _) => .K
     rule checkMerge(
          (<global>...
               <external-types> Types:Map </external-types>
               <external-decls-loc> DeclLocs:Map </external-decls-loc>
               <external-defs> Defs:Map </external-defs>
               <external-defs-loc> Locs:Map </external-defs-loc>
          ...</global>),
          (<global>...
               <external-types> Types':Map </external-types>
               <external-decls-loc> DeclLocs':Map </external-decls-loc>
               <external-defs> Defs':Map </external-defs>
               <external-defs-loc> Locs':Map </external-defs-loc>
          ...</global>))
          => checkExtTypes(.K, keys(Types), Types, keys(Types'), Types', updateMap(DeclLocs, DeclLocs'))
          ~> checkExtDefs(.K, keys(Defs), Types, keys(Defs'), Types', updateMap(Locs, Locs'))

     syntax KItem ::= checkExtTypes(K, Set, Map, Set, Map, Map)
     syntax KItem ::= checkExtType(Bool)
     rule checkExtTypes(.K => X, (SetItem(X::CId) => .Set) _, _, _, _, _)
     rule checkExtTypes(X:KItem => .K, _, _, Ids':Set, _, _)
          requires notBool (X in Ids')
     rule (.K => setTranslationLoc(L) ~> checkExtType(areDeclCompat(T, T'))) ~> checkExtTypes(X:KItem,
               _, X |-> T:Type _,
               _, X |-> T':Type _,
               X |-> L::CabsLoc _)
     rule (.K => setTranslationLoc(UnknownCabsLoc) ~> checkExtType(areDeclCompat(T, T'))) ~> checkExtTypes(X:KItem,
               _, X |-> T:Type _,
               _, X |-> T':Type _,
               Locs::Map)
          requires notBool (X in_keys(Locs))
     rule (checkExtType(true) => .K) ~> checkExtTypes(X:KItem => .K, _, _, _, _, _)
     rule (.K => setTranslationLoc(L) ~> EXT-UNDEF("TIN1",
               "Identifier " +String showCId({X}:>CId) +String " declared with incompatible types in different translation units."))
               ~> checkExtType(false) ~> checkExtTypes(X:KItem, _, _, _, _, X |-> L::CabsLoc _)
     rule checkExtTypes(.K, .Set, _, _, _, _) => setTranslationLoc(UnknownCabsLoc)

     syntax K ::= checkExtDefs(K, Set, Map, Set, Map, Map) [function]
     syntax KItem ::= errorMultipleDefs(CId)
     rule checkExtDefs(.K => X, (SetItem(X::CId) => .Set) _, _, _, _, _)
     rule checkExtDefs(X:KItem => .K, _, _, Defs':Set, _, _)
          requires notBool (X in Defs')
     rule checkExtDefs(.K, .Set, _, _, _, _) => .K
     rule checkExtDefs(X:CId, Ids::Set, X |-> T::Type Types::Map, SetItem(X) Ids'::Set, X |-> T'::Type Types'::Map, X |-> L::CabsLoc Locs::Map)
          => setTranslationLoc(L)
          ~> EXT-UNDEF("TIN2", "Multiple external definitions for " +String showCId({X}:>CId) +String ".")
          ~> errorMultipleDefs(X)
          ~> checkExtDefs(.K, Ids, Types, Ids', Types', Locs)
          [owise]

     syntax Map ::= mergeDecls(Map, Map) [function]
                  | #mergeDecls(Map, Map, Set) [function]
     rule mergeDecls(M1:Map, M2:Map) => #mergeDecls(M1:Map, updateMap(M1, M2), intersectSet(keys(M1), keys(M2)))
     rule #mergeDecls(OldValues:Map, NewValues:Map, SetItem(Key:KItem) CommonKeys:Set)
          => #mergeDecls(OldValues, NewValues[Key <- {{OldValues[Key]}<:KItem}:>Set {{NewValues[Key]}<:KItem}:>Set], CommonKeys)
     rule #mergeDecls(_, NewValues:Map, .Set) => NewValues

     syntax Map ::= mergeDefs(Map, Map) [function]
                  | #mergeDefs(Map, Map, Set) [function]
     rule mergeDefs(M1::Map, M2::Map) => #mergeDefs(M1, updateMap(M1, M2), intersectSet(keys(M1), keys(M2)))
     rule #mergeDefs(OldValues::Map, NewValues::Map, SetItem(Key:KItem) CommonKeys::Set)
          => #mergeDefs(OldValues, NewValues[Key <- updateMap({{OldValues[Key] orDefault .Map::Map}<:KItem}:>Map, {{NewValues[Key] orDefault .Map::Map}<:KItem}:>Map)], CommonKeys)
     rule #mergeDefs(_, NewValues::Map, .Set) => NewValues

     // Allows definitions to be overridden in the Match extensions.
     syntax K ::= mergeObj(K, K) [function]
     rule mergeObj(Obj1:K, Obj2:K) => mergeObj'(Obj1, Obj2) [owise]

     syntax K ::= "mergeObj'" "(" K "," K ")" [function]
     rule mergeObj'(B:K, .K) => B
     rule mergeObj'(.K, B:K) => B
     rule mergeObj'(
          (<global>
               <mem> M1:Map </mem>
               <references> R1:Map </references>
               <functions> F1:Map </functions>
               <goto-map> GM1:Map </goto-map>

               <external-types> ExtTypes1:Map </external-types>
               <external-defs> ExtDefs1:Map </external-defs>
               <odr-defs> OdrDefs1:Map </odr-defs>
               <linkings> Links1:Map </linkings>
               <function-tus> Funcs1:Map </function-tus>

               <linking-state>
                    <external-decls> ExtDecls1:Map </external-decls>
                    <external-decls-loc> ExtDeclsLoc1:Map </external-decls-loc>
                    <external-uses> ExtUses1:Map </external-uses>
                    <linking-deps> Linkdep1 </linking-deps>
                    <external-defs-loc> ExtDefsLoc1:Map </external-defs-loc>
                    <odr-decls> OdrDecls1:Map </odr-decls>
                    <odr-uses> OdrUses1:Set </odr-uses>
               </linking-state>

               <tags> Structs1:Map </tags>
               <unnamed-locs> Locs1:Map </unnamed-locs>
               <main-tu> Main1:Set </main-tu>
               <dynamic-init> Init1:K </dynamic-init>
               <constexpr-symbase> CS1::Set</constexpr-symbase>

               <translation-units> TUs1::Bag </translation-units>
          </global>),
          (<global>
               <mem> M2:Map </mem>
               <references> R2:Map </references>
               <functions> F2:Map </functions>
               <goto-map> GM2:Map </goto-map>

               <external-types> ExtTypes2:Map </external-types>
               <external-defs> ExtDefs2:Map </external-defs>
               <odr-defs> OdrDefs2:Map </odr-defs>
               <linkings> Links2:Map </linkings>
               <function-tus> Funcs2:Map </function-tus>

               <linking-state>
                    <external-decls> ExtDecls2:Map </external-decls>
                    <external-decls-loc> ExtDeclsLoc2:Map </external-decls-loc>
                    <external-uses> ExtUses2:Map </external-uses>
                    <linking-deps> Linkdep2 </linking-deps>
                    <external-defs-loc> ExtDefsLoc2:Map </external-defs-loc>
                    <odr-decls> OdrDecls2:Map </odr-decls>
                    <odr-uses> OdrUses2:Set </odr-uses>
               </linking-state>

               <tags> Structs2:Map </tags>
               <unnamed-locs> Locs2:Map </unnamed-locs>
               <main-tu> Main2:Set </main-tu>
               <dynamic-init> Init2:K </dynamic-init>
               <constexpr-symbase> CS2::Set </constexpr-symbase>

               <translation-units> TUs2::Bag </translation-units>
          </global>))
          =>
          <global>
               <mem> updateMap(M1, M2) </mem>
               <references> updateMap(R1, R2) </references>
               <functions> updateMap(F1, F2) </functions>
               <goto-map> updateMap(GM1, GM2) </goto-map>

               <external-types> updateMap(ExtTypes1, ExtTypes2) </external-types>
               <external-defs> updateMap(
                    // Override attribute: override external definitions.
                    removeAll(ExtDefs1, keys(getOverridden(ExtDefs1, ExtTypes2))),
                    removeAll(ExtDefs2, keys(getOverridden(ExtDefs2, ExtTypes1))))
               </external-defs>
               <odr-defs> mergeDefs(OdrDefs1, OdrDefs2) </odr-defs>
               <linkings> updateMap(Links1, Links2) </linkings>
               <function-tus> updateMap(Funcs1, Funcs2) </function-tus>

               <linking-state>
                    <external-decls> mergeDecls(ExtDecls1, ExtDecls2) </external-decls>
                    <external-decls-loc> updateMap(ExtDeclsLoc1, ExtDeclsLoc2) </external-decls-loc>
                    <external-uses> updateMap(ExtUses1, ExtUses2) </external-uses>
                    <linking-deps> mergeLinkdep(Linkdep1, Linkdep2) </linking-deps>
                    <external-defs-loc> updateMap(ExtDefsLoc1, ExtDefsLoc2) </external-defs-loc>
                    <odr-decls> mergeDecls(OdrDecls1, OdrDecls2) </odr-decls>
                    <odr-uses> OdrUses1 OdrUses2 </odr-uses>
               </linking-state>

               <tags> updateMap(Structs1, Structs2) </tags>
               <unnamed-locs> updateMap(Locs1, Locs2) </unnamed-locs>
               <main-tu> Main1 Main2 </main-tu>
               <dynamic-init> Init1 ~> Init2:K </dynamic-init>
               <constexpr-symbase> CS1 CS2 </constexpr-symbase>

               <translation-units> TUs1 TUs2 </translation-units>
          </global>

     // TODO(chathhorn): remove redundancy
     rule [[ nameOfCurrentTranslationUnit() => Tu ]]
          <curr-tu> Tu::String </curr-tu>

     context alias [c]: HERE:K

     rule [[ currentTranslationScope() => S ]]
          <curr-scope> S::Scope </curr-scope>

     rule [[ currentTranslationLoc() => Loc ]]
          <curr-program-loc> Loc::CabsLoc </curr-program-loc>

     rule <k> setTranslationLoc(Loc::CabsLoc) => .K ... </k>
          <curr-tr-program-loc> _ => Loc </curr-tr-program-loc>
          <curr-program-loc> _ => Loc </curr-program-loc>

     rule <k> setTranslationUnit(Tu::String) => .K ... </k>
          <curr-tr-tu> _ => Tu </curr-tr-tu>
          <curr-tu> _ => Tu </curr-tu>

     rule (<T>... <k> cleanup </k> ...</T> => .Bag)

     syntax Map ::= getOverridden(Map, Map) [function]
     rule getOverridden(_, _) => .Map::Map [owise]

endmodule
