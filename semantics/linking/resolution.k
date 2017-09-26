module C-LINKING-RESOLUTION-SYNTAX
     imports BASIC-K

     syntax KItem ::= "resolveReferences"
     syntax KItem ::= "removeUnusedIdentifiers"
     syntax Bool ::= isCLinkage(K) [function]
endmodule

module C-LINKING-RESOLUTION
     imports C-LINKING-RESOLUTION-SYNTAX
     imports COMMON-RESOLUTION-SYNTAX
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
               Identifier("main") |-> (obj(... d: static(MainTu:String)) #as Main::SymBase)
          ...</external-defs>
          <external-types>...
               Identifier("main") |-> _
          ...</external-types>
          <functions>... Main |-> _ ...</functions>
          [structural]
     rule <k> (.K => EXT-UNDEF("TDR3", "Main is not a function."))
               ~> resolveMain
          ...</k>
          <external-defs>...
               Identifier("main") |-> Main::SymBase
          ...</external-defs>
          <external-defs-loc>...
               Identifier("main") |-> L::CabsLoc
          ...</external-defs-loc>
          <curr-program-loc> _ => L </curr-program-loc>
          <functions> Functions:Map </functions>
          requires notBool (Main in_keys(Functions))
          [structural]

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
