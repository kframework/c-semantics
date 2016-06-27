module C-LINKING-RESOLUTION-SYNTAX
     syntax KItem ::= "resolveReferences"
     syntax KItem ::= "removeUnusedIdentifiers"
endmodule

module C-LINKING-RESOLUTION
     imports C-LINKING-RESOLUTION-SYNTAX

     imports COMPAT-SYNTAX
     imports SYMLOC-SYNTAX

     imports C-CONFIGURATION
     imports C-ERROR-SYNTAX

     // Add the real location at which an external reference is defined to the
     // environment of every TU where it appears.

     syntax KItem ::= resolveReference(CId)

     rule <k> (.K => resolveReference(X)) ~> resolveReferences ...</k>
          <external-uses> (SetItem(X:CId) => .Set) ...</external-uses>
          [structural]

     rule <k> resolveReference(X:CId) ...</k>
          <external-decls>...
               X |-> set((SetItem(Tu:String) => .Set) _)
          ...</external-decls>
          <external-defs>... X |-> Base':SymBase ...</external-defs>
          <tu-id> Tu </tu-id>
          <genv>... X |-> (Base:SymBase => Base') ...</genv>
          <linkings>... (.Map => Base |-> Base') ...</linkings>
          requires isLinkerLoc(Base)
          [structural]

     rule <k> resolveReference(X:CId) ...</k>
          <external-decls>...
               X |-> set((SetItem(Tu:String) => .Set) _)
          ...</external-decls>
          <external-defs>... X |-> _ ...</external-defs>
          <tu-id> Tu </tu-id>
          <genv>... X |-> Base:SymBase ...</genv>
          requires notBool isLinkerLoc(Base)
          [structural]

     rule <k> resolveReference(X:CId) => .K  ...</k>
          <external-decls>...
               (X:CId |-> set(.Set) => .Map)
          ...</external-decls>
          <external-defs>... X |-> _ ...</external-defs>
          <external-types>... X |-> _ ...</external-types>
          requires X =/=K Identifier("main")
          [structural]

     rule <k> (.K => EXT-UNDEF("TDR2",
                    "No definition for symbol with external linkage: "
                     +String idToString(X) +String ".",
                    "C11", "6.9:5, J.2:1 item 84"))
              ~> resolveReference(X:CId)
          ...</k>
          <external-defs> Defs:Map </external-defs>
          <external-types> Types:Map </external-types>
          requires notBool (X in_keys(Defs))
               orBool notBool (X in_keys(Types))
          [structural]

     // Remember which TU has the definition of main.
     rule <k> resolveReference(Identifier("main")) => .K ...</k>
          <main-tu>... (.Set => SetItem(MainTu)) </main-tu>
          <external-decls>...
               (Identifier("main") |-> set(.Set) => .Map)
          ...</external-decls>
          <external-defs>...
               Identifier("main") |-> _ @ static(MainTu:String)
          ...</external-defs>
          <external-types>...
               Identifier("main") |-> _
          ...</external-types>
          [structural]

     // Now everything left in <external-uses> should be an unresolved
     // reference.
     rule <k> resolveReferences => .K ...</k>
          (<linking-state>...
               <external-uses> .Set </external-uses>
          ...</linking-state> => .Bag)
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
          <external-decls>... X |-> set((SetItem(Tu) => .Set) _) ...</external-decls>
     rule <k> removeFromExternalDecls((ListItem(X:CId) => .List) _) ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <external-decls> Decls:Map </external-decls>
          requires notBool (X in_keys(Decls))
     rule removeFromExternalDecls(.List) => .K


endmodule
