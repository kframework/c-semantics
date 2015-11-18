module C-CHECK-LOC-SYNTAX
     imports C-TYPING-SYNTAX

     syntax KItem ::= enterRestrictScope(Scope)
     syntax KItem ::= exitRestrictScope(Scope)
     syntax KItem ::= activity(Int, Map)
endmodule

module C-CHECK-LOC
     imports C-CHECK-LOC-SYNTAX
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-COMMON-EXPR-REFERENCE-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SETTINGS-SYNTAX

     imports C-CONFIGURATION

     rule <k> enterRestrictScope(Tag:Scope) => .K ...</k>
          <activeBlocks>... Tag |-> activity((N:Int => N +Int 1), _) ...</activeBlocks>
          [structural]
     rule <k> enterRestrictScope(Tag:Scope) => .K ...</k>
          <activeBlocks> Tags:Map (.Map => Tag |-> activity(1, .Map)) </activeBlocks>
          requires notBool (Tag in_keys(Tags))
          [structural]

     rule <k> exitRestrictScope(Tag:Scope) => .K ...</k>
          <activeBlocks>... Tag |-> activity((N:Int => N -Int 1), _) ...</activeBlocks>
          requires N >Int 1
          [structural]
     rule <k> exitRestrictScope(Tag:Scope) => .K ...</k>
          <activeBlocks>... Tag |-> activity(1, _) => .Map ...</activeBlocks>
          [structural]
     rule <k> exitRestrictScope(Tag:Scope) => .K ...</k>
          <activeBlocks> Blocks:Map </activeBlocks>
          requires notBool Tag in_keys(Blocks)
          [structural]

     // Split out the prov to normalize the address.
     rule checkRestrict(loc(Base:SymBase, Offset:Int))
          => checkRestrict(loc(Base, Offset), .Set)
     rule checkRestrict(loc(Base:SymBase, Offset:Int, Prov:Set))
          => checkRestrict(loc(Base, Offset), Prov)

     // First, associate the restrict-qual'd pointer of this access with the
     // object.
     syntax KItem ::= checkRestrict(SymLoc, Set)
     rule <k> checkRestrict(Loc:SymLoc, Prov:Set)
               // If no accesses have occured previously, we should still check
               // for const violations.
               => checkRestrict(stripProv(Loc), getBases(Prov), getBases(Prov))
          ...</k>
          <restrict>
               Restricts:Map
               (.Map => Loc |-> set(getBases(Prov)))
          </restrict>
          requires notBool (Loc in_keys(Restricts))
          [structural]
     // TODO(chathhorn): finer-grain modified detection. This can fail for the
     // case of aggregates.
     rule <k> checkRestrict(Loc:SymLoc, Prov:Set)
               => checkRestrict(Loc, getBases(Prov), Bases)
          ...</k>
          <restrict>...
               Loc |-> set(Bases:Set (.Set => getBases(Prov)))
          ...</restrict>
          [structural]

     // Next, filter out the restrict pointers where the object has been
     // unmodified in the associated block.
     syntax KItem ::= checkRestrict(SymLoc, Set, Set) [klabel(checkRestrict3)]
     rule checkRestrict(Loc:SymLoc, Bases:Set, Bases':Set)
          => checkRestrict2(
               filterUnmodified(Loc, .K, Bases, .Set),
               filterUnmodified(Loc, .K, Bases', .Set))
          [structural]

     syntax KItem ::= filterUnmodified(SymLoc, Provenance,  Set, Set)
     syntax KResult ::= rset(Set)

     rule filterUnmodified(_, (.K => K), (SetItem(K:K) => .Set) _, _)
          [structural]
     rule <k> filterUnmodified(Loc:SymLoc,
               (basedOn(Base:SymBase, Tag:Scope) => .K), _,
               (.Set => SetItem(basedOn(Base, Tag))) _)
          ...</k>
          <activeBlocks>... Tag |-> activity(_, Modified:Map) ...</activeBlocks>
          requires Loc in_keys(Modified)
          [structural]
     rule <k> filterUnmodified(Loc:SymLoc, (basedOn(_, Tag:Scope) => .K), _, _)
          ...</k>
          <activeBlocks>... Tag |-> activity(_, Modified:Map) ...</activeBlocks>
          requires notBool (Loc in_keys(Modified))
          [structural]
     rule <k> filterUnmodified(_, (basedOn(_, Tag:Scope) => .K), _, _)
          ...</k>
          <activeBlocks> Modified:Map </activeBlocks>
          requires notBool (Tag in_keys(Modified))
          [structural]
     rule filterUnmodified(_, .K, .Set, Bases:Set) => rset(Bases)
          [structural]

     syntax KItem ::= checkRestrict2(K, K) [strict]
     rule checkRestrict2(rset(Bases:Set), rset(Bases':Set))
          => checkRestrict(Bases Bases', Bases, Bases')
          [structural]

     // Finally, do the actual checks.
     syntax KItem ::= checkRestrict(Set, Set, Set)
     rule (.K => checkRestrict'(B))
          ~> checkRestrict((SetItem(B:Provenance) => .Set) _, _, _)
          [structural]
     rule checkRestrict(.Set, Bases:Set, Bases':Set) => .K
          requires Bases ==K Bases'
          [structural]
     rule (.K => UNDEF("ECL3",
               "An object which has been modified is accessed through an expression based on a restrict-qualified pointer and another lvalue not also based on said pointer.",
               "6.7.3.1:4, J.2:1 item 68"))
          ~> checkRestrict(.Set, Bases:Set, Bases':Set)
          requires Bases =/=K Bases'
          [structural]

     syntax KItem ::= "checkRestrict'" "(" Provenance ")"
     rule <k> checkRestrict'(basedOn(Base:SymBase, _)) => .K ...</k>
          <mem>... Base |-> object(T:Type, _, _, _) ...</mem>
          requires notBool isConstType(innerType(T))
          [structural]
     rule <k> (.K => UNDEF("ECL4",
               "An object which has been modified is accessed through an expression based on a restrict-qualified pointer to a const-qualified type.",
               "6.7.3.1:4, J.2:1 item 68"))
               ~> checkRestrict'(basedOn(Base:SymBase, _))
          ...</k>
          <mem>... Base |-> object(T:Type, _, _, _) ...</mem>
          requires isConstType(innerType(T))
          [structural]
endmodule
