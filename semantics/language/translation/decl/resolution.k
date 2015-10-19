module C-DECL-RESOLUTION-SYNTAX
     syntax KItem ::= "allocateIncompleteTentatives"
     syntax KItem ::= "resolveReferences"
     syntax KItem ::= "removeUnusedIdentifiers"
endmodule

module C-DECL-RESOLUTION
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DECL-GLOBAL-SYNTAX
     imports C-DECL-RESOLUTION-SYNTAX

     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-CONFIGURATION

     imports C-ERROR-SYNTAX

     syntax KItem ::= allocateIncompleteTentative(CId, K)

     rule <k> (.K => allocateIncompleteTentative(X, Decl))
               ~> allocateIncompleteTentatives
          ...</k>
          <externals>...
               (X:CId |-> Decl:K => .Map)
          ...</externals>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          [structural]
     rule <k> allocateIncompleteTentatives => .K ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals> .Map </externals>
          [structural]

     rule allocateIncompleteTentative(X:CId,
               declState(_,
                    t(Mods:Set, incompleteArrayType(T:Type)), declared, true))
          => declare(typedDeclaration(t(Mods, arrayType(T, 1)), X), NoInit)
          [structural]
     rule allocateIncompleteTentative(_,
               declState(_, t(Mods:Set, _), State:DeclState, _))
          => .K
          requires State =/=K declared
               // TODO(chathhorn): ... and we do this inline function check in
               // addition to completing tentatives.
               andBool notBool (State ==K completed andBool Inline in Mods)
          [structural]
     rule allocateIncompleteTentative(_,
               declState(_, t(Mods:Set, _), _, false))
          => .K
          requires notBool (Inline in Mods)
          [structural]
     rule allocateIncompleteTentative(X:CId,
               declState(_, t(Mods:Set, _), completed, _))
          => UNDEF("TDR1",
               "declaration for inline function not defined in the same translation unit: "
               +String idToString(X),
               "6.7.4:7, J.2:1 item 70")
          requires Inline in Mods
          [structural]

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
          <external-defs>... X |-> Base:SymBase ...</external-defs>
          <tu-id> Tu </tu-id>
          <genv>... X |-> Base ...</genv>
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

     rule <k> resolveReference(X:CId)
               => UNDEF("TDR2",
                    "no definition for symbol with external linkage: "
                     +String idToString(X),
                    "6.9:5, J.2:1 item 84")
          ...</k>
          <external-uses>... (.Set => SetItem(X)) ...</external-uses>
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

     syntax KItem ::= removeFromExternalDecls(Set)

     rule <k> removeUnusedIdentifiers => removeFromExternalDecls(keys(Env) -Set Uses) ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <genv> Env:Map => removeAll(Env, (keys(Env) -Set Uses)) </genv>
          <gtypes> Types:Map => removeAll(Types, (keys(Types) -Set Uses)) </gtypes>
          (<tu-linking-state>...
               <uses> Uses:Set </uses>
          ...</tu-linking-state> => .Bag)

     rule <k> removeFromExternalDecls((SetItem(X:CId) => .Set) _) ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <external-decls>... X |-> set((SetItem(Tu) => .Set) _) ...</external-decls>
     rule <k> removeFromExternalDecls((SetItem(X:CId) => .Set) _) ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <external-decls> Decls:Map </external-decls>
          requires notBool (X in_keys(Decls))
     rule removeFromExternalDecls(.Set) => .K

endmodule
