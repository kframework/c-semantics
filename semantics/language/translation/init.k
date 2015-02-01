module C-TRANSLATION-INIT-SYNTAX
     syntax KItem ::= load(Bag, Bag)
     syntax KItem ::= "link" | "cleanup"

     syntax TransOpts ::= "DEBUG" | "NOLINK"
endmodule

module C-TRANSLATION-INIT
     imports C-TRANSLATION-INIT-SYNTAX

     imports C-BUILTIN-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DECL-GLOBAL-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-DECL-RESOLUTION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-FUNCTION-DEF-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-COMPATIBILITY-SYNTAX
     imports C-TYPING-SYNTAX

     imports COMPAT-SYNTAX

     rule <k> link
               => TranslationUnit("builtin", list(.List),
                    list(ListItem(addBuiltins(builtins))))
               ~> resolveReferences
               ~> printSuccess
          ...</k>
          <options> Opts:Set </options>
          requires notBool (NOLINK in Opts)

     rule load(Obj1:Bag, Obj2:Bag)
               => checkMerge(Obj1, Obj2)
               ~> load'(mergeObj(Obj1, Obj2))

     syntax KItem ::= "load'" "(" Bag ")"
     rule <k> load'(Merged:Bag)
               => checkMerge(Merged, <global> ThisObj </global>)
               ~> loadObj(mergeObj(Merged, <global> ThisObj </global>))
          ...</k>
          <global> ThisObj:Bag </global>

     rule <k> link => printSuccess ...</k>
          <options> SetItem(NOLINK) ...</options>

     rule (<T>...
               <k> cleanup </k>
               <options> Opts:Set </options>
          ...</T> => .Bag)
          requires notBool (DEBUG in Opts)
          [structural]

     // TODO(chathhorn): prevent duplicate TUs or TU name clashes.
     rule <k> (TranslationUnit(TU:String, list(Strings:List), list(Decls:List))
               => (preDeclareStrings(Strings)
               ~> listToK(Decls)
               ~> allocateIncompleteTentatives))
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
          => allowInit(K ~> discard)
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

     rule <k> addBuiltin(B:CId, T:Type) => declare(
               typedDeclaration(T, B),
               initializer(initFunction(
                    &(B),
                    functionObject(B, .List, T, handleBuiltin)
               ))) ...</k>
          <external-types>... B |-> _ ...</external-types>
          <external-defs> Defs:Map </external-defs>
          requires notBool (B in keys(Defs)) andBool isFunctionType(T)

     rule <k> addBuiltin(B:CId, _) => .K ...</k>
          <external-types> Types:Map </external-types>
          <external-defs> Defs:Map </external-defs>
          requires (B in keys(Defs))
               orBool (notBool (B in keys(Types)))

     rule <k> addBuiltin(B:CId, T:Type) => declare(
               typedDeclaration(T, B),
               initializer(handleBuiltinConstant(B, T))) ...</k>
          <external-types>... B |-> _ ...</external-types>
          <external-defs> Defs:Map </external-defs>
          requires notBool (B in keys(Defs)) andBool notBool isFunctionType(T)
               
     syntax KItem ::= #nativeConstant(String, Type) [function, hook(C-SEMANTICS:nativeConstant), impure]
     rule handleBuiltinConstant(Identifier(S:String), T:Type) => #nativeConstant(S, T) when S in keys(nativeDefinedBuiltins)

     syntax KItem ::= checkMerge(Bag, Bag)
     rule checkMerge(_, _) => .K
     // TODO(chathhorn): need to rework in light of the silly limitations on
     // matching keys.
     // rule checkMerge(_, .Bag) => .
     // rule checkMerge(.Bag, _) => .
     // rule checkMerge(
     //      (<global>...
     //           <external-types> X:CId |-> _ => .Map ...</external-types>
     //      ...</global>),
     //      (<global>...
     //           <external-types> Types':Map </external-types>
     //      ...</global>))
     //      requires notBool (X in keys(Types'))
     // rule checkMerge(
     //      (<global>...
     //           <external-defs> X:CId |-> _ => .Map ...</external-defs>
     //      ...</global>),
     //      (<global>...
     //           <external-defs> Defs':Map </external-defs>
     //      ...</global>))
     //      requires notBool (X in keys(Defs'))
     // rule checkMerge(
     //      (<global>...
     //           <external-types> Types:Map </external-types>
     //      ...</global>),
     //      (<global>...
     //           <external-types> X:CId |-> _ => .Map ...</external-types>
     //      ...</global>))
     //      requires notBool (X in keys(Types))
     // rule checkMerge(
     //      (<global>...
     //           <external-defs> Defs:Map </external-defs>
     //      ...</global>),
     //      (<global>...
     //           <external-defs> X:CId |-> _ => .Map ...</external-defs>
     //      ...</global>))
     //      requires notBool (X in keys(Defs))
     // rule checkMerge(
     //      (<global>...
     //           <external-types> X:CId |-> T:Type => .Map ...</external-types>
     //      ...</global>),
     //      (<global>...
     //           <external-types> X |-> T':Type => .Map ...</external-types>
     //      ...</global>))
     //      requires areCompatible(T, T')
     // rule checkMerge(
     //      (<global>...
     //           <external-types> .Map </external-types>
     //           <external-defs> .Map </external-defs>
     //      ...</global>),
     //      (<global>...
     //           <external-types> .Map </external-types>
     //           <external-defs> .Map </external-defs>
     //      ...</global>)) => .
     // rule (.K => UNDEF("TIN1",
     //           "Identifier " +String idToString(X) +String " declared with incompatble types in different translation units.",
     //           "6.2.7:2"))
     //      ~> checkMerge(
     //      (<global>...
     //           <external-types>... X:CId |-> T:Type ...</external-types>
     //      ...</global>),
     //      (<global>...
     //           <external-types>... X |-> T':Type ...</external-types>
     //      ...</global>))
     //      requires notBool areCompatible(T, T')
     // rule (.K => UNDEF("TIN2",
     //           "Multiple external definitions for " +String idToString(X) +String ".",
     //           "6.9"))
     //      ~> checkMerge(
     //      (<global>...
     //           <external-defs>... X:CId |-> _ ...</external-defs>
     //      ...</global>),
     //      (<global>...
     //           <external-defs>... X |-> _  ...</external-defs>
     //      ...</global>))

     syntax Bag ::= mergeObj(Bag, Bag) [function]
     syntax Map ::= mergeDecls(Map, Map) [function]
                  | mergeDecl(K, K, K, Map) [function]

     rule mergeDecls(.Map, M:Map) => M
     rule mergeDecls((Key:K |-> Val:K) M:Map, M':Map)
          => mergeDecls(M, mergeDecl(Key, Val, .K, M'))

     rule mergeDecl(Key:K, Val:K, .K, M:Map) => (Key |-> Val) M
          requires notBool (Key in keys(M))
     rule mergeDecl(Key:K, Val:K, .K, (Key |-> Val':K) M:Map)
          => mergeDecl(Key, Val, Val', M)
     rule mergeDecl(Key:K, set(S:Set), set(S':Set), M:Map)
          => (Key |-> set(S S')) M

     rule mergeObj(B:Bag, .Bag) => B
     rule mergeObj(.Bag, B:Bag) => B
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

               <linkings> updateMap(Links1, Links2) </linkings>

               <main-tu> Main1 Main2 </main-tu>

               <translation-units> TUs1 TUs2 </translation-units>
          </global>

     syntax KItem ::= "printSuccess"

     // This message tells kcc the translation phase succeeded.
     rule <k> printSuccess => .K ...</k>
          <result-value> _ => 0 </result-value>

endmodule
