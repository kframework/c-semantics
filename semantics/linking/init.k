module C-LINKING-INIT-SYNTAX
     imports BASIC-K
     imports BOOL-SYNTAX
     imports MAP
     imports STRING-SYNTAX

     syntax KItem ::= load(K) 
     syntax KItem ::= "link" | "cleanup" | "reportSuccess" | "builtinTu"

     syntax TransOpts ::= Debug() | NoLink()

     syntax KItem ::= makeTu(String)

     syntax KItem ::= addBuiltins(Map, Bool)

endmodule

module C-LINKING-INIT
     imports C-LINKING-INIT-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports STRING
     imports C-TYPING-SORTS
     imports COMPAT-SYNTAX
     imports COMMON-BUILTIN-SYNTAX
     imports COMMON-INIT-SYNTAX
     imports ERROR-SYNTAX
     imports MEMORY-SYNTAX
     imports SYMLOC-SYNTAX
     imports C-LINKING-RESOLUTION-SYNTAX
     imports C-TYPING-COMMON-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX

     rule <k> link // compare against c11/language/translation/init.k
               => makeTu("native")
               ~> addBuiltins(nativeDefinedBuiltins, false)
               ~> removeUnusedIdentifiers
               ~> resolveReferences
               ~> reportSuccess
          ...</k>
          <options> Opts:Set </options>
          requires notBool (NoLink() in Opts)

     rule <k> makeTu(TU:String) => .K ...</k>
          <curr-tu> _ => TU </curr-tu>
          <translation-units>...
               (.Bag => <tu>...
                    <tu-id> TU </tu-id>
                    <next-link-loc> 0 @ link(TU) </next-link-loc>
                    <next-static-loc> 0 @ static(TU) </next-static-loc>
               ...</tu>)
          ...</translation-units>
          [structural]

     syntax KItem ::= addBuiltin(CId, Type, Bool)
     // Only add a builtin if it has an external type (that is, it's been
     // declared somewhere) and if it doesn't already have a definition.
     // Therefore, if someone redefines a builtin, we won't co-opt it (although
     // redefining it should probably be an error).

     rule <k> (.K => addBuiltin(Identifier(B), T, AddAll))
               ~> addBuiltins((B:String |-> T:Type => .Map) _, AddAll:Bool) ...</k>

     rule addBuiltins(.Map, _) => .K

     rule <k> addBuiltin(B:CId, T:FunctionType, AddAll:Bool) => declareBuiltinFunction(B, T, Base) ...</k>
          <external-types> Types:Map </external-types>
          <external-uses> Uses:Set </external-uses>
          <external-defs> Defs:Map </external-defs>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <next-static-loc> Base:SymBase => linc(Base) </next-static-loc>
          <uses>... .Set => SetItem(B) ...</uses>
          requires (notBool (B in_keys(Defs)) andBool B in_keys(Types) andBool B in Uses) orBool AddAll

     rule <k> addBuiltin(B:CId, _, false) => .K ...</k>
          <external-types> Types:Map </external-types>
          <external-defs> Defs:Map </external-defs>
          requires (B in_keys(Defs))
               orBool (notBool (B in_keys(Types)))

     rule <k> addBuiltin(B:CId, T:Type, AddAll:Bool) => declareBuiltinConstant(B, T, 0 @ nativeSymbol(idToString(B))) ...</k>
          <external-types> Types:Map </external-types>
          <external-uses> Uses:Set </external-uses>
          <external-defs> Defs:Map </external-defs>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <uses>... .Set => SetItem(B) ...</uses>
          requires ((notBool (B in_keys(Defs)) andBool B in_keys(Types) andBool B in Uses) orBool AddAll)
               andBool notBool isFunctionType(T)

     rule <k> addBuiltin(B:CId, _, false) => .K ...</k>
          <external-types>... B |-> _ ...</external-types>
          <external-uses> Uses:Set </external-uses>
          <external-defs> Defs:Map </external-defs>
          requires notBool (B in_keys(Defs))
               andBool notBool (B in Uses)

     // compare against declare()
     syntax KItem ::= declareBuiltinFunction(CId, Type, SymBase)
                    | declareBuiltinConstant(CId, Type, SymBase)

     rule <k> declareBuiltinFunction(B:CId, T::Type, Base:SymBase) => .K ...</k>
          <mem> Mem::Map => Mem[Base <- object(T, 1, makeEmptyArray(1))] </mem>
          <functions> Fun::Map => Fun[Base <- functionObject(B, T, .List, handleBuiltin)] </functions>
          <external-defs> Defs::Map => Defs[B <- Base] </external-defs>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <genv> Env::Map => Env[B <- Base] </genv>
          <gtypes> Types::Map => Types[B <- T] </gtypes>

     rule <k> declareBuiltinConstant(B:CId, T::Type, Base:SymBase) => .K ...</k>
          <external-defs> Defs::Map => Defs[B <- Base] </external-defs>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <genv> Env::Map => Env[B <- Base] </genv>
          <gtypes> Types::Map => Types[B <- T] </gtypes>

     rule load(Obj1:KItem ~> Obj2:KItem ~> Objs:K)
               => load(Objs ~> mergeObj(Obj1, Obj2))
               ~> checkMerge(Obj1, Obj2)

     rule <k> load(Merged:KItem)
               => loadObj(mergeObj(Merged, ThisObj))
               ~> checkMerge(Merged, ThisObj)
          ...</k>
          ThisObj:GlobalCell

     rule load(.K) => .K

     rule <k> link => reportSuccess ...</k>
          <options> SetItem(NoLink()) ...</options>

     rule (<T>...
               <k> cleanup </k>
               <options> Opts:Set </options>
          ...</T> => .Bag)
          requires notBool (Debug() in Opts)
          [structural]

     syntax KItem ::= checkMerge(K, K)
                    | checkExtTypes(K, Set, Map, Set, Map)
                    | checkExtType(Bool)
                    | checkExtDefs(K, Set, Set)

     rule checkMerge(_, .K) => .K
     rule checkMerge(.K, _) => .K
     rule checkMerge(
          (<global>...
               <external-types> Types:Map </external-types>
               <external-defs> Defs:Map </external-defs>
          ...</global>),
          (<global>...
               <external-types> Types':Map </external-types>
               <external-defs> Defs':Map </external-defs>
          ...</global>))
          => checkExtTypes(.K, keys(Types), Types, keys(Types'), Types')
          ~> checkExtDefs(.K, keys(Defs), keys(Defs'))

     rule checkExtTypes((.K => X::CId), (SetItem(X::CId) => .Set) _, _, _, _)
     rule checkExtTypes((X:KItem => .K), _, _, Ids':Set, _)
          requires notBool (X in Ids')
     rule (.K => checkExtType(areDeclCompat(T,T'))) ~> checkExtTypes(X:KItem,
               _, (X |-> T:Type) _,
               _, (X |-> T':Type) _)
     rule (checkExtType(true) => .K) ~> checkExtTypes((X:KItem => .K), _, _, _, _)
     rule checkExtTypes(.K, .Set, _, _, _) => .K
     rule (.K => EXT-UNDEF("TIN1",
               "Identifier " +String idToString({X}:>CId) +String " declared with incompatible types in different translation units.",
               "C11", "6.2.7:2, J.2:1 item 15"))
          ~> checkExtType(false) ~> checkExtTypes(X:KItem,
               _, _,
               _, _)

     rule checkExtDefs((.K => X::CId), (SetItem(X::CId) => .Set) _, _)
     rule checkExtDefs((X:KItem => .K), _, Defs':Set)
          requires notBool (X in Defs')
     rule checkExtDefs(.K, .Set, _) => .K
     rule (.K => EXT-UNDEF("TIN2",
               "Multiple external definitions for " +String idToString({X}:>CId) +String ".",
               "C11", "6.9:5, J.2:1 item 84"))
          ~> checkExtDefs(X:KItem, _, SetItem(X) _)

     syntax K ::= mergeObj(K, K) [function]
     syntax Map ::= mergeDecls(Map, Map) [function]
                  | #mergeDecls(Map, Map, Set) [function]
     rule mergeDecls(M1:Map, M2:Map) => #mergeDecls(M1:Map, updateMap(M1, M2), intersectSet(keys(M1), keys(M2)))
     rule #mergeDecls(OldValues:Map, NewValues:Map, SetItem(Key:K) CommonKeys:Set)
          => #mergeDecls(OldValues, NewValues[Key <- {{OldValues[Key]}<:K}:>Set {{NewValues[Key]}<:K}:>Set], CommonKeys)
     rule #mergeDecls(_, NewValues:Map, .Set) => NewValues

     syntax Map ::= mergeDefs(Map, Map) [function]
                  | #mergeDefs(Map, Map, Set) [function]
     rule mergeDefs(M1::Map, M2::Map) => #mergeDefs(M1, updateMap(M1, M2), intersectSet(keys(M1), keys(M2)))
     rule #mergeDefs(OldValues::Map, NewValues::Map, SetItem(Key:K) CommonKeys::Set)
          => #mergeDefs(OldValues, NewValues[Key <- updateMap({{OldValues[Key]}<:K}:>Map, {{NewValues[Key]}<:K}:>Map)], CommonKeys)
     rule #mergeDefs(_, NewValues::Map, .Set) => NewValues

     rule mergeObj(B:K, .K) => B
     rule mergeObj(.K, B:K) => B
     rule mergeObj(
          (<global>
               <mem> M1:Map </mem>
               <functions> F1:Map </functions>

               <external-types> ExtTypes1:Map </external-types>
               <external-defs> ExtDefs1:Map </external-defs>
               <odr-defs> OdrDefs1:Map </odr-defs>

               <linking-state>
                    <external-decls> ExtDecls1:Map </external-decls>
                    <external-uses> ExtUses1:Set </external-uses>
                    <odr-decls> OdrDecls1:Map </odr-decls>
                    <odr-uses> OdrUses1:Set </odr-uses>
               </linking-state>

               <tags> Structs1:Map </tags>

               <linkings> Links1:Map </linkings>

               <main-tu> Main1:Set </main-tu>

               <translation-units> TUs1:Bag </translation-units>
          </global>),
          (<global>
               <mem> M2:Map </mem>
               <functions> F2:Map </functions>

               <external-types> ExtTypes2:Map </external-types>
               <external-defs> ExtDefs2:Map </external-defs>
               <odr-defs> OdrDefs2:Map </odr-defs>

               <linking-state>
                    <external-decls> ExtDecls2:Map </external-decls>
                    <external-uses> ExtUses2:Set </external-uses>
                    <odr-decls> OdrDecls2:Map </odr-decls>
                    <odr-uses> OdrUses2:Set </odr-uses>
               </linking-state>

               <tags> Structs2:Map </tags>

               <linkings> Links2:Map </linkings>

               <main-tu> Main2:Set </main-tu>

               <translation-units> TUs2:Bag </translation-units>
          </global>))
          =>
          <global>
               <mem> updateMap(M1, M2) </mem>
               <functions> updateMap(F1, F2) </functions>

               <external-types> updateMap(ExtTypes1, ExtTypes2) </external-types>
               <external-defs> updateMap(ExtDefs1, ExtDefs2) </external-defs>
               <odr-defs> mergeDefs(OdrDefs1, OdrDefs2) </odr-defs>

               <linking-state>
                    <external-decls> mergeDecls(ExtDecls1, ExtDecls2) </external-decls>
                    <external-uses> ExtUses1 ExtUses2 </external-uses>
                    <odr-decls> mergeDecls(OdrDecls1, OdrDecls2) </odr-decls>
                    <odr-uses> OdrUses1 OdrUses2 </odr-uses>
               </linking-state>

               <tags> updateMap(Structs1, Structs2) </tags>

               <linkings> updateMap(Links1, Links2) </linkings>

               <main-tu> Main1 Main2 </main-tu>

               <translation-units> TUs1 TUs2 </translation-units>
          </global>

     rule <k> reportSuccess => .K ...</k>
          <result-value> _ => 0 </result-value>

     /*
          <generated-annotations> .List </generated-annotations>
     rule <k> reportSuccess => writeSpecModule(#open(S +String ".spec.k")) ...</k>
          <generated-annotations> L:List </generated-annotations>
          <curr-program-loc> CabsLoc(S:String, _, _, _) </curr-program-loc>
          requires size(L) >Int 0

     syntax KItem ::= writeSpecModule(Int)
     rule <k> writeSpecModule(Fd:Int) => #write(Fd,
                  "module " +String replaceAll(S, ".", "-") +String "-SPEC" +String "\n"
          +String "  imports C-VERIFIER\n\n") ~> writeSpecs(Fd) ...</k>
          <curr-program-loc> CabsLoc(S:String, _, _, _) </curr-program-loc>

     syntax KItem ::= writeSpecs(Int)
     rule <k> (.K => #write(Fd, S +String "\n")) ~> writeSpecs(Fd:Int) ...</k>
          <generated-annotations> ListItem(S:String) => .List ...</generated-annotations>
     rule <k> writeSpecs(Fd:Int) => #write(Fd, "\nendmodule") ~> writeEndModule(Fd) ...</k>
          <generated-annotations> .List </generated-annotations>

     syntax KItem ::= writeEndModule(Int)
     rule <k> writeEndModule(Fd:Int) => #close(Fd) ...</k>
          <result-value> _ => 0 </result-value>
     */
endmodule
