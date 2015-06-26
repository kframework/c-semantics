module C-CHECK-LOC-SYNTAX
     imports C-TYPING-SYNTAX

     syntax KItem ::= enterRestrictScope(RestrictTag)
     syntax KItem ::= exitRestrictScope(RestrictTag)
     syntax KItem ::= activity(Int, Map)
endmodule

module C-CHECK-LOC
     imports C-CHECK-LOC-SYNTAX
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-COMMON-EXPR-REFERENCE-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SYMLOC-SYNTAX

     imports COMPAT-SYNTAX

     rule <k> enterRestrictScope(_:RestrictTag) => .K ...</k>
     //rule <k> enterRestrictScope(Tag:RestrictTag) => .K ...</k>
     //     <activeBlocks>... Tag |-> activity((N:Int => N +Int 1), _) ...</activeBlocks>
     //     [structural]
     //rule <k> enterRestrictScope(Tag:RestrictTag) => .K ...</k>
     //     <activeBlocks> Tags:Map (.Map => Tag |-> activity(1, .Map)) </activeBlocks>
     //     requires notBool (Tag in keys(Tags))
     //     [structural]

     rule <k> exitRestrictScope(_:RestrictTag) => .K ...</k>
     //rule <k> exitRestrictScope(Tag:RestrictTag) => .K ...</k>
     //     <activeBlocks>... Tag |-> activity((N:Int => N -Int 1), _) ...</activeBlocks>
     //     requires N >Int 1
     //     [structural]
     //rule <k> exitRestrictScope(Tag:RestrictTag) => .K ...</k>
     //     <activeBlocks>... Tag |-> activity(1, _) => .Map ...</activeBlocks>
     //     [structural]
     //rule <k> exitRestrictScope(Tag:RestrictTag) => .K ...</k>
     //     <activeBlocks> Blocks:Map </activeBlocks>
     //     requires notBool Tag in keys(Blocks)
     //     [structural]

     rule checkLoc(_) => .K
     /*
     rule checkLoc(NullPointer) => checkLoc'(NullPointer)
          [structural]
     rule checkLoc(loc(Base:SymBase, Offset:Int)) => checkLoc'(loc(Base:SymBase, Offset:Int))
          [structural]
     rule checkLoc(loc(Base:SymBase, Offset:Int, _)) => checkLoc'(loc(Base:SymBase, Offset:Int))
          [structural]
     */

     syntax KItem ::= "checkLoc'" "(" SymLoc ")"
     rule checkLoc'(NullPointer) => .K
          [structural]
     rule <k> checkLoc'(loc(Base:SymBase, Offset:Int))
               => checkOffsets(Offset, Len)
          ...</k>
          <mem>... Base |-> object(_, Len:Int, _, _) ...</mem>
          [structural]
     rule <k> checkLoc'(loc(Base:SymBase, 0)) => .K ...</k>
          <functions>... Base |-> _ ...</functions>
          [structural]
     rule <k> checkLoc'(loc((Base:SymBase => Base'), _)) ...</k>
          <linkings>... Base |-> Base':SymBase ...</linkings>
          [structural]
     rule <k> checkLoc'(loc(Base:SymBase, Offset:Int)) => errorLocInvalid ...</k>
          <mem> Mem:Map </mem>
          <functions> Funs:Map </functions>
          <linkings> Links:Map </linkings>
          requires notBool (Base in keys(Mem))
               andBool notBool (Base in keys(Funs))
               andBool notBool (Base in keys(Links))
               andBool notBool isNativeLoc(loc(Base, Offset))
          [structural]
     rule checkLoc'(L:SymLoc) => .K
          requires isNativeLoc(L)
          [structural]

     syntax KItem ::= checkOffsets(Int, Int) [function]
     rule checkOffsets(Offset:Int, Len:Int) => .K
          requires (Offset <=Int Len) andBool (Offset >=Int 0)
     rule checkOffsets(_, _) => errorLocBounds [owise]

     syntax Error ::= "errorLocInvalid"
                    | "errorLocBounds"
     rule errorLocInvalid
          => UNDEF("ECL1",
               "Referring to an object outside of its lifetime.",
               "6.2.4")
          [structural]
     rule errorLocBounds
          => UNDEF("ECL2",
               "Found pointer that refers outside the bounds of an object + 1.",
               "6.2.4")
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
               //(.Map => Loc |-> set(getBases(Prov)))
          </restrict>
          requires notBool (Loc in keys(Restricts))
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
     syntax KItem ::= checkRestrict(SymLoc, Set, Set)
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
               (basedOn(Base:SymBase, Tag:RestrictTag) => .K), _,
               (.Set => SetItem(basedOn(Base, Tag))) _)
          ...</k>
          <activeBlocks>... Tag |-> activity(_, Modified:Map) ...</activeBlocks>
          requires Loc in keys(Modified)
          [structural]
     rule <k> filterUnmodified(Loc:SymLoc, (basedOn(_, Tag:RestrictTag) => .K), _, _)
          ...</k>
          <activeBlocks>... Tag |-> activity(_, Modified:Map) ...</activeBlocks>
          requires notBool (Loc in keys(Modified))
          [structural]
     rule <k> filterUnmodified(_, (basedOn(_, Tag:RestrictTag) => .K), _, _)
          ...</k>
          <activeBlocks> Modified:Map </activeBlocks>
          requires notBool (Tag in keys(Modified))
          [structural]
     rule filterUnmodified(_, .K, .Set, Bases:Set) => rset(Bases)
          [structural]

     // conflicts with checkRestrict(SymLoc, Set) above
     syntax KItem ::= checkRestrict2(K, K) [seqstrict]
     rule checkRestrict2(rset(Bases:Set), rset(Bases':Set))
          => checkRestrict2(Bases Bases', Bases, Bases')
          [structural]

     // Finally, do the actual checks.
     syntax KItem ::= checkRestrict2(Set, Set, Set)
     rule (.K => checkRestrict'(B))
          ~> checkRestrict2((SetItem(B:Provenance) => .Set) _, _, _)
          [structural]
     rule checkRestrict2(.Set, Bases:Set, Bases':Set) => .K
          requires Bases ==K Bases'
          [structural]
     rule (.K => UNDEF("ECL3",
               "An object which has been modified is accessed through an expression based on a restrict-qualified pointer and another lvalue not also based on said pointer.",
               "6.7.3.1:4"))
          ~> checkRestrict2(.Set, Bases:Set, Bases':Set)
          requires Bases =/=K Bases'
          [structural]

     syntax KItem ::= "checkRestrict'" "(" Provenance ")"
     rule <k> checkRestrict'(basedOn(Base:SymBase, _)) => .K ...</k>
          <mem>... Base |-> object(T:Type, _, _, _) ...</mem>
          requires notBool isConstType(innerType(T))
          [structural]
     rule <k> (.K => UNDEF("ECL4",
               "An object which has been modified is accessed through an expression based on a restrict-qualified pointer to a const-qualified type.",
               "6.7.3.1:4"))
               ~> checkRestrict'(basedOn(Base:SymBase, _))
          ...</k>
          <mem>... Base |-> object(T:Type, _, _, _) ...</mem>
          requires isConstType(innerType(T))
          [structural]
endmodule
