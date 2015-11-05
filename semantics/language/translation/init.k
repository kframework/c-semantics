module C-TRANSLATION-INIT-SYNTAX
     imports BASIC-K
     syntax KItem ::= load(K)
     syntax KItem ::= "link" | "cleanup"

     syntax TransOpts ::= "DEBUG" | "NOLINK"
endmodule

module C-TRANSLATION-INIT
     imports C-TRANSLATION-INIT-SYNTAX

     imports C-ABSTRACT-SYNTAX
     imports C-BUILTIN-SYNTAX
     imports C-COMMON-EXPR-REFERENCE-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DECL-GLOBAL-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DECL-RESOLUTION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ELABORATOR-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-FUNCTION-DEF-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SETTINGS-SYNTAX

     imports C-CONFIGURATION

     rule ToIdentifier("___missing_field_name") => #NoName
     rule ToIdentifier(S:String) => Identifier(S)
          requires S =/=String "___missing_field_name"

     rule <k> link
               => TranslationUnit("builtin", list(.List),
                    list(ListItem(addBuiltins(builtins))))
               ~> resolveReferences
               ~> reportSuccess
          ...</k>
          <options> Opts:Set </options>
          requires notBool (NOLINK in Opts)

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
          <options> SetItem(NOLINK) ...</options>

     rule (<T>...
               <k> cleanup </k>
               <options> Opts:Set </options>
          ...</T> => .Bag)
          requires notBool (DEBUG in Opts)
          [structural]

     // TODO(chathhorn): prevent duplicate TUs or TU name clashes.
     rule <k> TranslationUnit(TU:String, list(Strings:List), list(Decls:List))
               => preDeclareStrings(Strings)
               ~> listToK(Decls)
               ~> allocateIncompleteTentatives
               ~> removeUnusedIdentifiers
          ...</k>
          <curr-tu> _ => TU </curr-tu>
          <translation-units>...
               (.Bag => <tu>...
                    <tu-id> TU </tu-id>
                    <next-link-loc> 0 @ link(TU) </next-link-loc>
                    <next-static-loc> 0 @ static(TU) </next-static-loc>
               ...</tu>)
          ...</translation-units>
          [structural]

     syntax KItem ::= preDeclareStrings(List)

     rule preDeclareStrings(ListItem(K:K) L:List)
          => runInit(K ~> discard)
          ~> preDeclareStrings(L)
          [structural]
     rule preDeclareStrings(.List) => .K
          [structural]
     syntax KItem ::= addBuiltins(Map)
                    | addBuiltin(CId, Type)
     // Only add a builtin if it has an external type (that is, it's been
     // declared somewhere) and if it doesn't already have a definition.
     // Therefore, if someone redefines a builtin, we won't co-opt it (although
     // redefining it should probably be an error).

     rule <k> (.K => addBuiltin(Identifier(B), T))
               ~> addBuiltins((B:String |-> T:Type => .Map) _) ...</k>

     rule addBuiltins(.Map) => .K

     rule <k> addBuiltin(B:CId, T:FunctionType) => declare(
               typedDeclaration(T, B),
               initializer(Computation(initFunction(
                    &(B), B,
                    functionObject(B, .List, T, handleBuiltin)
               )))) ...</k>
          <external-types>... B |-> _ ...</external-types>
          <external-uses>... SetItem(B) ...</external-uses>
          <external-defs> Defs:Map </external-defs>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <uses>... .Set => SetItem(B) ...</uses>
          requires notBool (B in_keys(Defs))

     rule <k> addBuiltin(B:CId, _) => .K ...</k>
          <external-types> Types:Map </external-types>
          <external-defs> Defs:Map </external-defs>
          requires (B in_keys(Defs))
               orBool (notBool (B in_keys(Types)))

     rule <k> addBuiltin(B:CId, T:Type) => declare(
               typedDeclaration(T, B),
               initializer(handleBuiltinConstant(B, T))) ~> deleteObject(0 @ nativeSymbol(idToString(B))) ...</k>
          <external-types>... B |-> _ ...</external-types>
          <external-uses>... SetItem(B) ...</external-uses>
          <external-defs> Defs:Map </external-defs>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <uses>... .Set => SetItem(B) ...</uses>
          requires notBool (B in_keys(Defs))
               andBool notBool isFunctionType(T)

     rule <k> addBuiltin(B:CId, T:Type) => .K ...</k>
          <external-types>... B |-> _ ...</external-types>
          <external-uses> Uses:Set </external-uses>
          <external-defs> Defs:Map </external-defs>
          requires notBool (B in_keys(Defs))
               andBool notBool (B in Uses)

     rule handleBuiltinConstant(Identifier(S:String), T:Type)
          => addToEnv(Identifier(S), 0 @ nativeSymbol(S))
          when S in_keys(nativeDefinedBuiltins)

     syntax KItem ::= deleteObject(SymBase)

     rule <k> deleteObject(Base:SymBase) => .K ...</k>
          <mem>... Base |-> _ => .Map ...</mem>

     syntax KItem ::= checkMerge(K, K)
                    | checkExtTypes(K, Set, Map, Set, Map)
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

     rule checkExtTypes((.K => X:CId), (SetItem(X:CId) => .Set) _, _, _, _)
     rule checkExtTypes((X:CId => .K), _, _, Ids':Set, _)
          requires notBool (X in Ids')
     rule checkExtTypes((X:CId => .K),
               _, (X |-> T:Type) _,
               _, (X |-> T':Type) _)
          requires areCompatible(T, T')
     rule checkExtTypes(.K, .Set, _, _, _) => .K
     rule (.K => UNDEF("TIN1",
               "Identifier " +String idToString(X) +String " declared with incompatible types in different translation units.",
               "6.2.7:2, J.2:1 item 15"))
          ~> checkExtTypes(X:CId,
               _, X:CId |-> T:Type _,
               _, X |-> T':Type _)
          requires notBool areCompatible(T, T')
     rule (_:ErrorExit => .K) ~> checkExtTypes((X:CId => .K), 
               _, (X |-> T:Type) _,
               _, (X |-> T':Type) _)
          requires isErrorRecovery

     rule checkExtDefs((.K => X:CId), (SetItem(X:CId) => .Set) _, _)
     rule checkExtDefs((X:CId => .K), _, Defs':Set)
          requires notBool (X in Defs')
     rule checkExtDefs(.K, .Set, _) => .K
     rule (.K => UNDEF("TIN2", 
               "Multiple external definitions for " +String idToString(X) +String ".",
               "6.9:5, J.2:1 item 84"))
          ~> checkExtDefs(X:CId, _, SetItem(X) _)
     rule (_:ErrorExit => .K) ~> checkExtDefs((X:CId => .K), _, _)
          requires isErrorRecovery 

     syntax K ::= mergeObj(K, K) [function]
     syntax Map ::= mergeDecls(Map, Map) [function]
                  | #mergeDecls(Map, Map) [function]

     syntax Set ::= getSet(K) [function]
     rule getSet(set(S:Set)) => S
     rule mergeDecls(M1:Map, M2:Map) => #mergeDecls(M1, M2)
          requires size(M2) <Int size(M1)
     rule mergeDecls(M1:Map, M2:Map) => #mergeDecls(M2, M1) [owise]
     rule #mergeDecls(M:Map, .Map) => M
     rule #mergeDecls(M':Map, (Key:K |-> set(S:Set)) M:Map)
          => mergeDecls(M'[Key <- set(S getSet(M'[Key]<:K))], M)
          requires Key in_keys(M')
     rule #mergeDecls(M':Map, (Key:K |-> Val:K) M:Map)
          => mergeDecls((Key |-> Val) M', M) [owise]

     rule mergeObj(B:K, .K) => B
     rule mergeObj(.K, B:K) => B
     rule mergeObj(
          (<global>
               <mem> M1:Map </mem>
               <functions> F1:Map </functions>

               <external-types> ExtTypes1:Map </external-types>
               <external-defs> ExtDefs1:Map </external-defs>

               <linking-state>
                    <external-decls> ExtDecls1:Map </external-decls>
                    <external-uses> ExtUses1:Set </external-uses>
               </linking-state>

               <structs> Structs1:Map </structs>

               <linkings> Links1:Map </linkings>

               <main-tu> Main1:Set </main-tu>

               <translation-units> TUs1:Bag </translation-units>
          </global>),
          (<global>
               <mem> M2:Map </mem>
               <functions> F2:Map </functions>

               <external-types> ExtTypes2:Map </external-types>
               <external-defs> ExtDefs2:Map </external-defs>

               <linking-state>
                    <external-decls> ExtDecls2:Map </external-decls>
                    <external-uses> ExtUses2:Set </external-uses>
               </linking-state>

               <structs> Structs2:Map </structs>

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

               <linking-state>
                    <external-decls> mergeDecls(ExtDecls1, ExtDecls2) </external-decls>
                    <external-uses> ExtUses1 ExtUses2 </external-uses>
               </linking-state>

               <structs> updateMap(Structs1, Structs2) </structs>

               <linkings> updateMap(Links1, Links2) </linkings>

               <main-tu> Main1 Main2 </main-tu>

               <translation-units> TUs1 TUs2 </translation-units>
          </global>

     syntax KItem ::= "reportSuccess"
     rule <k> reportSuccess => .K ...</k>
          <result-value> _ => 0 </result-value>
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

     rule CodeLoc(K:K, L:CabsLoc) => filterCabsLoc(L) ~> K
     rule DefinitionLocRange(K:K, L1:CabsLoc, L2:CabsLoc)
          => filterCabsLoc(L1) ~> K ~> filterCabsLoc(L2)

     rule <k> L:CabsLoc => .K ...</k>
          <elab>... .K => L </elab>
          <curr-program-loc> _ => L </curr-program-loc>

     syntax CabsLoc ::= filterCabsLoc(CabsLoc) [function]
     rule filterCabsLoc(CabsLoc("cabs loc unknown", -10, -10, 0))
          => UnknownCabsLoc
     rule filterCabsLoc(L:CabsLoc) => L [owise]

     rule ExpressionLoc(K:K, _) => K

     /*@ \fromStandard{\source[n1570]{\para{6.10.6}{1}}}{
     A preprocessing directive of the form
     \cdisplay{# pragma pp-tokensoptnew-line}
     \broken{where the preprocessing token \cinline{STDC} does not immediately
     follow pragma in the directive (prior to any macro replacement)} causes the
     implementation to behave in an implementation-defined manner. The behavior
     might cause translation to fail or cause the translator or the resulting
     program to behave in a non-conforming manner. Any such pragma that is not
     recognized by the implementation is ignored.
     }*/
     rule Pragma(_) => .K
          [structural]
     rule PragmaKccInv(_) => .K
          [structural]

     rule AttributeWrapper(K:K, _) => K

     rule NothingExpression => emptyValue:>Expression

     rule Computation(.K) => .K
     rule <k> Computation(V:RValue) => .K ...</k>
          <elab>... .K => Computation(V) </elab>
          requires isHold(V)
     // Totally elide pure expressions from the translated program.
     rule Computation(V:RValue) => .K
          requires notBool isHold(V)

     rule checkRestrict(_) => .K

endmodule
