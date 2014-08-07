module C-DECL-RESOLUTION-SYNTAX
     syntax KItem ::= "allocateIncompleteTentatives"
     syntax KItem ::= "resolveReferences"
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

     syntax KItem ::= allocateIncompleteTentative(CId,K)

     rule <k> ( . => allocateIncompleteTentative(X,DE))
               ~> allocateIncompleteTentatives ...</k>
          <externals>...
               (X:CId |-> DE:K => .Map)
          ...</externals>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          [structural]
     rule <k> allocateIncompleteTentatives => . ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          (<tu-linking-state>...
               <externals> .Map </externals>
          ...</tu-linking-state> => .)
          // TODO(chathhorn): move
          <incomplete-tags> .Set </incomplete-tags>
          [structural]

// TODO(chathhorn): merging; needs further effort to integrate.
//      rule <k> (allocateIncompleteTentative(X:CId,declState(SB:SymBase,
//                     t(S:Set, incompleteArrayType(T:Type)), declared, true) )
//                => declare(typedDeclaration(t(S, arrayType(T, 1)), X), NoInit))
     rule <k> (.K => declare(typedDeclaration(t(Mods, arrayType(T, 1)), X), NoInit))
               ~> allocateIncompleteTentatives
          ...</k>
          <externals>...
// TODO(chathhorn): merging; further effort.
//                (.Map => X:CId |-> declState(SB,t(S,
//                incompleteArrayType(T)), declared, true))
//           ...</externals>
//           [structural]
// 
//      rule allocateIncompleteTentative(_:CId,
//           declState(_, _, State:DeclState, Tentative:Bool)) => .
//           requires notBool Tentative
//                orBool (State =/=K declared)
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
          requires State =/=K declared
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
          requires notBool Inline in Mods
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
          requires Inline in Mods
          [structural]

     // Add the real location at which an external reference is defined to the
     // environment of every TU where it appears.

     syntax KItem ::= resolveReference(CId)

     rule <k> ( . => resolveReference(X))~> resolveReferences ...</k>
          <external-uses> (SetItem(X:CId) => .Set) ...</external-uses>
          [structural]
     // Now everything left in <external-uses> should be an unresolved
     // reference.
     rule <k> resolveReferences => .K ...</k>
          (<linking-state>...
               <external-uses> .Set </external-uses>
          ...</linking-state> => .Bag)

     rule <k> resolveReference(X:CId) ...</k>
          <external-decls>...
               X |-> set((SetItem(Tu:String) => .Set) _)
          ...</external-decls>
          <external-defs>...
               X |-> Base':SymBase
          ...</external-defs>
          <tu-id> Tu </tu-id>
          <genv>...
               X |-> (Base:SymBase => Base')
          ...</genv>
          <linkings>...
               (.Map => Base |-> Base')
          ...</linkings>
          requires isLinkerLoc(Base)
          [structural]

     rule <k> resolveReference(X:CId) ...</k>
          <external-decls>...
               X |-> set((SetItem(Tu:String) => .Set) _)
          ...</external-decls>
          <external-defs>...
               X |-> Base:SymBase
          ...</external-defs>
          <tu-id> Tu </tu-id>
          <genv>...
               X |-> Base
          ...</genv>
          requires notBool isLinkerLoc(Base)
          [structural]

     rule <k> (resolveReference(X:CId) => . ) ...</k>
          <external-decls>...
               (X:CId |-> set(.Set) => .Map)
          ...</external-decls>
          <external-defs>...
               X |-> _
          ...</external-defs>
          <external-types>...
               X |-> _
          ...</external-types>
          requires X =/=K Identifier("main")
          [structural]
// TODO(chathhorn): merging; integrate.
//      rule <k> (resolveReference(X:CId) => ERROR("DR1", 
//                     "no definition for symbol with external linkage: " 
//                     +String idToString(X)) )

     rule <k> (. => UNDEF("TDR2",
                    "no definition for symbol with external linkage: "
                    +String idToString(X),
                    "6.9:5"))
               ~> resolveReferences
          ...</k>
          <external-uses>...
               (.Set => SetItem(X))
          ...</external-uses>
          <external-defs>
               Defs:Map
          </external-defs>
          <external-types>
               Types:Map
          </external-types>
          requires notBool (X in keys(Defs))
               orBool notBool (X in keys(Types))
          [structural]

     // Remember which TU has the definition of main.
     rule <k> resolveReference(Identifier("main")) => . ...</k>
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

// TODO(chathhorn): merging; probably to be removed.
//      // Now everything left in <external-uses> should be an unresolved
//      // reference.
// 
//      rule <k> resolveReferences => . ...</k>
//           (<linking-state>...
//                <external-uses> .Set </external-uses>
//           ...</linking-state> => .Bag)
//           [structural]

endmodule
