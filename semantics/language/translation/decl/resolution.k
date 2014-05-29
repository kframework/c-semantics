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
     rule <k> (.K => declare(typedDeclaration(t(S, arrayType(T, 1)), X), NoInit))
               ~> allocateIncompleteTentatives
          ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>...
               X:CId |-> declState(_,
                    t(S:Set, incompleteArrayType(T:Type)), declared, true) 
          ...</externals>
          [structural]
     rule <k> allocateIncompleteTentatives ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          <externals>...
               (_ |-> declState(_, _, State:DeclState, Tentative:Bool) => .Map)
          ...</externals>
          when notBool Tentative
               orBool (State =/=K declared)
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

     rule <k> (.K => ERROR("DR1", 
                    "no definition for symbol with external linkage: " 
                    +String idToString(X))) 
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

     // Now everything left in <external-uses> should be an unresolved
     // reference.
     
     rule <k> resolveReferences => .K ...</k>
          (<linking-state>...
               <external-uses> .Set </external-uses>
          ...</linking-state> => .Bag)

endmodule
