module C-TRANSLATION-INIT
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX

     imports C-DECL-RESOLUTION-SYNTAX
     imports C-ENV-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-BUILTIN-SYNTAX
     imports C-FUNCTION-DEF-SYNTAX

     imports COMPAT-SYNTAX

     // TODO(chathhorn): check that main is (correctly) defined.
     rule <k> Program(klist(P:KList)) 
               => klistToK(P) 
               ~> TranslationUnit(
                    "builtin", klist(.KList), addBuiltins(builtins))
               ~> resolveReferences
          </k>
          <control>...
               <currentFunction> 
                    _ => file-scope
               </currentFunction>
               <currentProgramLoc>
                    _ => UnknownCabsLoc
               </currentProgramLoc>
          ...</control>
          [structural, large]

     // TODO(chathhorn): prevent duplicate TUs or TU name clashes.
     rule [unpack-TranslationUnit]:
          <k> TranslationUnit(Tu:String, Strings:K, K:K) 
               => preDeclareStrings(Strings)
               ~> klistToK(eraseKLabel('StmtCons, K))
               ~> allocateIncompleteInternals
          ...</k>
          <currTU> _ => Tu </currTU>
          <translation-units>...
               (. => <tu>...
                    <tu-id> Tu </tu-id>
                    <next-link-loc> firstLoc(link(Tu)) </next-link-loc>
                    <next-static-loc> firstLoc(static(Tu)) </next-static-loc>
               ...</tu>)
          ...</translation-units>
          [structural, large]
          
     syntax K ::= preDeclareStrings(K)
     
     rule preDeclareStrings(klist((K:K,, L:KList)))
          => K ~> discard ~> preDeclareStrings(klist(L))
          [structural]
     rule preDeclareStrings(klist(.KList)) => .
          [structural]
     
     syntax SemMode ::= "InterpMode" | "DebugMode"
     rule <T>... <mode> InterpMode </mode> <k> .K </k> ...</T> => .Bag
          [structural]
          
     syntax K ::= addBuiltins(Set)

     // Only add a builtin if it has an external type (that is, it's been
     // declared somewhere) and if it doesn't already have a definition.
     // Therefore, if someone redefines a builtin, we won't co-opt it (although
     // redefining it should probably be an error).
     rule <k> (. => initFunction(
               tv(Loc, t(.Set, pointerType(T))), 
               builtinPrototype(Identifier(B), T)))
               ~> addBuiltins((SetItem(B:String) => .) _)
          ...</k>
          <external-types>...
               Identifier(B) |-> T:Type
          ...</external-types>
          <external-defs> 
               Defs:Map (. => Identifier(B) |-> Loc)
          </external-defs>
          <currTU> Tu:String </currTU>
          <tu-id> Tu </tu-id>
          <next-static-loc> Loc:SymLoc => linc(Loc) </next-static-loc>
          when notBool Identifier(B) in keys Defs
          
     rule <k> addBuiltins((SetItem(B:String) => .) _) ...</k>
          <external-types> Types:Map </external-types>
          <external-defs> Defs:Map </external-defs>
          when (Identifier(B) in keys Defs)
               orBool (notBool Identifier(B) in keys Types)
          
     rule addBuiltins(.Set) => .

endmodule
