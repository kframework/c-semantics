module C-DECL-RESOLUTION-SYNTAX
     syntax KItem ::= "allocateIncompleteTentative"
     syntax KItem ::= "resolveReference"
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

     syntax KItem ::= midAllocateIncompleteTentative(CId,K)

     rule <k> ( . => midAllocateIncompleteTentative(X,DE))
		~> allocateIncompleteTentative ...</k>
          <externals>...
               (X:CId |-> DE:K => .Map)
          ...</externals>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          [structural]
     rule <k> allocateIncompleteTentative => . ...</k>
          <curr-tu> Tu:String </curr-tu>
          <tu-id> Tu </tu-id>
          (<tu-linking-state>...
               <externals> .Map </externals>
          ...</tu-linking-state> => .Bag)
          // TODO(chathhorn): move
          <incomplete-tags> .Set </incomplete-tags>
          [structural]

    rule <k> (midAllocateIncompleteTentative(X:CId,declState(SB:SymBase,
                    t(S:Set, incompleteArrayType(T:Type)), declared, true) )
		 => declare(typedDeclaration(t(S, arrayType(T, 1)), X), NoInit))
          ...</k>
          <externals>...
               (.Map => X:CId |-> declState(SB,t(S,
			 incompleteArrayType(T)), declared, true))
          ...</externals>
          [structural]

     rule midAllocateIncompleteTentative(_:CId,
	     declState(_, _, State:DeclState, Tentative:Bool)) => .
          when notBool Tentative
               orBool (State =/=K declared)
          [structural]

     // Add the real location at which an external reference is defined to the
     // environment of every TU where it appears.

     syntax KItem ::= midResolveReference(CId)

     rule <k> ( . => midResolveReference(X))~> resolveReference ...</k>
          <external-uses> (SetItem(X:CId) => .Set) ...</external-uses>
  	  [structural]
     // Now everything left in <external-uses> should be an unresolved
     // reference.
     rule <k> resolveReference => .K ...</k>
          (<linking-state>...
               <external-uses> .Set </external-uses>
          ...</linking-state> => .Bag)

     rule <k> midResolveReference(X:CId) ...</k>
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
          when isLinkerLoc(Base)

     rule <k> midResolveReference(X:CId) ...</k>
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
          when notBool isLinkerLoc(Base)

     rule <k> (midResolveReference(X:CId) => . ) ...</k>
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

     rule <k> (midResolveReference(X:CId) => ERROR("DR1", 
                    "no definition for symbol with external linkage: " 
                    +String idToString(X)) )
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
          when notBool (X in keys(Defs))
               orBool notBool (X in keys(Types))

     // Remember which TU has the definition of main.
     rule <k> (midResolveReference(Identifier("main")) => .) ...</k>
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

endmodule
