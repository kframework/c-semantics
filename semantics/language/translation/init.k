module C-TRANSLATION-INIT-SYNTAX
     syntax Bag ::= mergeObj(Bag, Bag) [function]
     syntax SemMode ::= "link" | "nolink"
     syntax K ::= outputMode(SemMode, Bool) [function]
endmodule

module C-TRANSLATION-INIT
     imports C-TRANSLATION-INIT-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX

     imports C-DECL-RESOLUTION-SYNTAX
     imports C-DECL-GLOBAL-SYNTAX
     imports C-ENV-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-BUILTIN-SYNTAX
     imports C-FUNCTION-DEF-SYNTAX

     imports COMPAT-SYNTAX

     rule outputMode(link, Debug:Bool) 
          => TranslationUnit("builtin", list(.List), addBuiltins(builtins))
          ~> resolveReferences
          ~> #if (Debug)
             #then (.K)
             #else (cleanup)
             #fi

     rule outputMode(nolink, Debug:Bool)
          => #if (Debug)
             #then (.K)
             #else (cleanup)
             #fi

     syntax K ::= "cleanup"
     rule <T>... <k> cleanup </k> ...</T> => .Bag
          [structural]
          
     // TODO(chathhorn): prevent duplicate TUs or TU name clashes.
     rule [unpack-TranslationUnit]:
          <k> TranslationUnit(TU:String, Strings:K, K:K) 
               => preDeclareStrings(Strings)
               ~> listToK(deCons(K))
               ~> allocateIncompleteInternals
          ...</k>
          <currTU> _ => TU </currTU>
          <translation-units>...
               (.Bag => <tu>...
                    <tu-id> TU </tu-id>
                    <next-link-loc> firstLoc(link(TU)) </next-link-loc>
                    <next-static-loc> firstLoc(static(TU)) </next-static-loc>
               ...</tu>)
          ...</translation-units>
          [structural, large]
          
     syntax K ::= preDeclareStrings(K)
     
     rule preDeclareStrings(list(ListItem(K:K) L:List))
          => allowInit(K ~> discard)
          ~> preDeclareStrings(list(L))
          [structural]
     rule preDeclareStrings(list(.List)) => .K
          [structural]
     
     syntax K ::= addBuiltins(Set)

     // Only add a builtin if it has an external type (that is, it's been
     // declared somewhere) and if it doesn't already have a definition.
     // Therefore, if someone redefines a builtin, we won't co-opt it (although
     // redefining it should probably be an error).

     rule <k> (.K => initFunction(
               tv(Loc, t(.Set, pointerType(T))), 
               builtinPrototype(Identifier(B), T)))
               ~> addBuiltins((SetItem(B:String) => .Set) _)
          ...</k>
          <external-types>...
               Identifier(B) |-> T:Type
          ...</external-types>
          <external-defs> 
               Defs:Map => Defs:Map[Loc / Identifier(B)]
          </external-defs>
          <currTU> TU:String </currTU>
          <tu-id> TU </tu-id>
          <next-static-loc> Loc:SymLoc => linc(Loc) </next-static-loc>
          when notBool Identifier(B) in keys Defs
          
     rule <k> addBuiltins((SetItem(B:String) => .Set) _) ...</k>
          <external-types> Types:Map </external-types>
          <external-defs> Defs:Map </external-defs>
          when (Identifier(B) in keys Defs)
               orBool (notBool Identifier(B) in keys Types)
     
     rule addBuiltins(.Set) => .K

     // TODO(chathhorn): it'd be nice to remove the unused builtins from
     // <functions />.

     rule mergeObj(B:Bag, .Bag) => B
     rule mergeObj(.Bag, B:Bag) => B

     rule mergeObj(
          (<global>
               <mem> M1:Map </mem>
               <functions> F1:Map </functions>
               <gstructs> Structs1:Map </gstructs>
               <notWritable> NoWrite1:Set </notWritable>

               <linking-state>
                    <external-decls> ExtDecls1:Map </external-decls>
                    <external-types> ExtTypes1:Map </external-types>
                    <external-defs> ExtDefs1:Map </external-defs>
                    <external-uses> ExtUses1:Set </external-uses>
               </linking-state>

               <linkings> Links1:Map </linkings>

               <mainTU> Main1:Set </mainTU>

               <translation-units> TUs1:Bag </translation-units>
          </global>),
          (<global>
               <mem> M2:Map </mem>
               <functions> F2:Map </functions>
               <gstructs> Structs2:Map </gstructs>
               <notWritable> NoWrite2:Set </notWritable>

               <linking-state>
                    <external-decls> ExtDecls2:Map </external-decls>
                    <external-types> ExtTypes2:Map </external-types>
                    <external-defs> ExtDefs2:Map </external-defs>
                    <external-uses> ExtUses2:Set </external-uses>
               </linking-state>

               <linkings> Links2:Map </linkings>

               <mainTU> Main2:Set </mainTU>

               <translation-units> TUs2:Bag </translation-units>
          </global>))
          =>
          <global>
               <mem> M1 M2 </mem>
               <functions> F1 F2 </functions>
               <gstructs> Structs1 Structs2 </gstructs>
               <notWritable> NoWrite1 NoWrite2 </notWritable>

               <linking-state>
                    <external-decls> ExtDecls1 ExtDecls2 </external-decls>
                    <external-types> ExtTypes1 ExtTypes2 </external-types>
                    <external-defs> ExtDefs1 ExtDefs2 </external-defs>
                    <external-uses> ExtUses1 ExtUses2 </external-uses>
               </linking-state>

               <linkings> Links1 Links2 </linkings>

               <mainTU> Main1 Main2 </mainTU>

               <translation-units> TUs1 TUs2 </translation-units>
          </global>


endmodule
