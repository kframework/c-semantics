module C-TRANSLATION-INIT-SYNTAX
     syntax KItem ::= loadMergeObj(Bag , Bag) [function]
     syntax KItem ::= "link" | "cleanup"

     syntax TransOpts ::= "DEBUG" | "NOLINK"

endmodule

module C-TRANSLATION-INIT
     imports C-TRANSLATION-INIT-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX

     imports C-DECL-RESOLUTION-SYNTAX
     imports C-DECL-GLOBAL-SYNTAX
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DECL-INITIALIZER-SYNTAX
     imports C-ENV-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-BUILTIN-SYNTAX
     imports C-FUNCTION-DEF-SYNTAX

     imports COMPAT-SYNTAX

     //TODO(LiyiLi): write to stdout does not work
     rule <k> link
               => (TranslationUnit("builtin", list(.List),
                    list(ListItem(addBuiltins(builtins))))
               ~> resolveReferences
               ~> printSuccess("Translation successful!\n"))
          ...</k>
          <options> Opts:Set </options>
          requires notBool (NOLINK in Opts)

     //TODO(LiyiLi): write to stdout does not work
     rule <k> link => printSuccess("Translation successful!\n") ...</k>
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
               (. => <tu>...
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
		    | addBuiltin(CId,Type)
          
     // Only add a builtin if it has an external type (that is, it's been
     // declared somewhere) and if it doesn't already have a definition.
     // Therefore, if someone redefines a builtin, we won't co-opt it (although
     // redefining it should probably be an error).

     rule <k> (. => addBuiltin(Identifier(B),T))
		~> addBuiltins((B:String |-> T:Type => .Map) _) ...</k>

     rule addBuiltins(.Map) => .K
  
     rule <k> (addBuiltin(B:CId,T:Type) => declare(
               typedDeclaration(T, B), 
               initializer(initFunction(
                    &(B),
                    functionObject(B, .List, T, handleBuiltin)
               )))) ...</k>
          <external-types>... B |-> _ ...</external-types>
          <external-defs> Defs:Map </external-defs>
          requires notBool (B in keys(Defs))
          
     rule <k> (addBuiltin(B:CId,_:Type) => . ) ...</k>
          <external-types> Types:Map </external-types>
          <external-defs> Defs:Map </external-defs>
          requires (B in keys(Defs))
               orBool (notBool (B in keys(Types)))

     

     // TODO(chathhorn): it'd be nice to remove the unused builtins from
     // <functions />.

     rule loadMergeObj(A:Bag , .Bag) => loadObj(A)
     rule loadMergeObj(.Bag , A:Bag) => loadObj(A)

     // TODO(chathhorn): Check compatibility of decls instead of dumbly
     // merging.
     rule loadMergeObj(<global>
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
          </global>,
	  <global>
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
          </global>)
          =>
          loadObj(
          <global>
               <mem> M1 M2 </mem>
               <functions> F1 F2 </functions>

               <external-types> ExtTypes1 ExtTypes2 </external-types>
               <external-defs> ExtDefs1 ExtDefs2 </external-defs>

               <linking-state>
                    <external-decls> ExtDecls1 ExtDecls2 </external-decls>
                    <external-uses> ExtUses1 ExtUses2 </external-uses>
               </linking-state>

               <linkings> Links1 Links2 </linkings>

               <main-tu> Main1 Main2 </main-tu>

               <translation-units> TUs1 TUs2 </translation-units>
          </global>)
     //TODO(LiyiLi): write to stdout not work currently
     //syntax KItem ::= "printSuccess"
     //rule printSuccess => #write(#stdout, "Translation successful!\n")
     syntax KItem ::= printSuccess(String)
     rule printSuccess(S:String) => #write(1,S)


endmodule
