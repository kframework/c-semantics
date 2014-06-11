module C-DECL-RESOLUTION-SYNTAX
     syntax K ::= "allocateIncompleteTentatives"
     syntax K ::= "resolveReferences"
endmodule

module C-DECL-RESOLUTION
     imports C-DECL-DEFINITION-SYNTAX
     imports C-DECL-GLOBAL-SYNTAX
     imports C-DECL-RESOLUTION-SYNTAX
     imports C-DECL-ZERO-SYNTAX

     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ENV-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports COMPAT-SYNTAX

     imports C-ERROR-SYNTAX

     rule <k> allocateIncompleteTentatives => . ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          (<tu-linking-state>...
               <externals> .Map </externals>
          ...</tu-linking-state> => .Bag)
          // TODO(chathhorn): move
          <incomplete-tags> .Set </incomplete-tags>
          [structural]
     rule <k> (.K => declare(typedDeclaration(t(Mods, arrayType(T, 1)), X), NoInit))
               ~> allocateIncompleteTentatives
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>...
               X:CId |-> declState(_,
                    t(Mods:Set, incompleteArrayType(T:Type)), declared, true)
          ...</externals>
          [structural]
     rule <k> allocateIncompleteTentatives ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>...
               _ |-> declState(_, t(Mods:Set, _), State:DeclState, _) => .Map
          ...</externals>
          when State =/=K declared
               // TODO(chathhorn): ... and we do this inline function check in
               // addition to completing tentatives.
               andBool notBool (State ==K completed andBool Inline in Mods)
          [structural]
     rule <k> allocateIncompleteTentatives ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>...
               _ |-> declState(_, t(Mods:Set, _), _, false) => .Map
          ...</externals>
          when notBool Inline in Mods
          [structural]
     rule <k> (. => UNDEF("TDR1",
               "declaration for inline function not defined in the same translation unit.",
               "6.7.4"))
               ~> allocateIncompleteTentatives
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>...
               _ |-> declState(_, t(Mods:Set, _), completed, _)
          ...</externals>
          when Inline in Mods
          [structural]

     // Add the real location at which an external reference is defined to the
     // environment of every TU where it appears.
     rule <k> resolveReferences ...</k>
          <external-uses>...
               SetItem(X:CId)
          ...</external-uses>
          <external-decls>...
               X |-> set((SetItem(Tu:String) => .) _)
          ...</external-decls>
          <external-defs>...
               X |-> Base':SymBase
          ...</external-defs>
          <tu-id> Tu </tu-id>
          <genv>...
               X |-> (Base:SymBase => Base')
          ...</genv>
          <linkings>...
               (. => Base |-> Base')
          ...</linkings>
          when isLinkerLoc(Base)
          [structural]
     rule <k> resolveReferences ...</k>
          <external-uses>...
               SetItem(X:CId)
          ...</external-uses>
          <external-decls>...
               X |-> set((SetItem(Tu:String) => .) _)
          ...</external-decls>
          <external-defs>...
               X |-> Base:SymBase
          ...</external-defs>
          <tu-id> Tu </tu-id>
          <genv>...
               X |-> Base
          ...</genv>
          when notBool isLinkerLoc(Base)
          [structural]

     rule <k> resolveReferences ...</k>
          <external-uses>...
               (SetItem(X:CId) => .)
          ...</external-uses>
          <external-decls>...
               (X:CId |-> set(.Set) => .Map)
          ...</external-decls>
          <external-defs>...
               X |-> _
          ...</external-defs>
          <external-types>...
               X |-> _
          ...</external-types>
          when X =/=K Identifier("main")
          [structural]

     rule <k> (. => UNDEF("TDR2",
                    "no definition for symbol with external linkage: "
                    +String idToString(X),
                    "6.9:5"))
               ~> resolveReferences
          ...</k>
          <external-uses>...
               SetItem(X:CId)
          ...</external-uses>
          <external-defs>
               Defs:Map
          </external-defs>
          <external-types>
               Types:Map
          </external-types>
          when notBool (X in keys(Defs))
               orBool notBool (X in keys(Types))
          [structural]

     // Remember which TU has the definition of main.
     rule <k> resolveReferences ...</k>
          <main-tu>... (.Set => SetItem(MainTu)) </main-tu>
          <external-uses>...
               (SetItem(Identifier("main")) => .Set)
          ...</external-uses>
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

endmodule
