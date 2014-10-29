module C-CHECK-LOC-SYNTAX
     syntax K ::= enterRestrictScope(RestrictTag)
     syntax K ::= exitRestrictScope(RestrictTag)
     syntax K ::= activity(Int, Map)
endmodule

module C-CHECK-LOC
     imports C-CHECK-LOC-SYNTAX
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-COMMON-EXPR-REFERENCE-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX

     imports COMPAT-SYNTAX

     rule <k> enterRestrictScope(Tag:RestrictTag) => . ...</k>
          <activeBlocks>... Tag |-> activity((N:Int => N +Int 1), _) ...</activeBlocks>
          [structural]
     rule <k> enterRestrictScope(Tag:RestrictTag) => . ...</k>
          <activeBlocks> Tags:Map (.Map => Tag |-> activity(1, .Map)) </activeBlocks>
          when notBool (Tag in keys(Tags))
          [structural]

     rule <k> exitRestrictScope(Tag:RestrictTag) => . ...</k>
          <activeBlocks>... Tag |-> activity((N:Int => N -Int 1), _) ...</activeBlocks>
          when N >Int 1
          [structural]
     rule <k> exitRestrictScope(Tag:RestrictTag) => . ...</k>
          <activeBlocks> _ (Tag |-> activity(1, _) => .Map) </activeBlocks>
          [structural]

     rule checkLoc(Loc:SymLoc) => checkLoc'(stripProv(Loc))
          [structural]

     syntax K ::= "checkLoc'" "(" SymLoc ")"
     rule checkLoc'(NullPointer) => .
          [structural]
     rule <k> checkLoc'(loc(Base:SymBase, Offset:Int))
               => checkOffsets(Offset, Len)
          ...</k>
          <mem>... Base |-> object(_, Len:Int, _) ...</mem>
          [structural]
     rule <k> checkLoc'(loc(Base:SymBase, 0)) => . ...</k>
          <functions>... Base |-> _ ...</functions>
          [structural]
     rule <k> checkLoc'(loc((Base:SymBase => Base'), _)) ...</k>
          <linkings>... Base |-> Base':SymBase ...</linkings>
          [structural]
     rule <k> checkLoc'(loc(Base:SymBase, _)) => errorLocInvalid ...</k>
          <mem> Mem:Map </mem>
          <functions> Funs:Map </functions>
          <linkings> Links:Map </linkings>
          when notBool Base in keys(Mem)
               andBool notBool Base in keys(Funs)
               andBool notBool Base in keys(Links)
          [structural]

     syntax K ::= checkOffsets(Int, Int) [function]
     rule checkOffsets(Offset:Int, Len:Int) => .
          when (Offset <=Int Len) andBool (Offset >=Int 0)
     rule checkOffsets(Offset:Int, Len:Int) => errorLocBounds
          when (Offset >Int Len) orBool (Offset <Int 0)

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

     // First, associate the restrict-qual'd pointer of this access with the
     // object.
     rule checkRestrict(loc(Base:SymBase, Offset:Int), T:Type)
          => checkRestrict(loc(Base, Offset, .Set), T)
     rule <k> checkRestrict(Loc:SymLoc, _)
               // If no accesses have occured previously, we should still check
               // for const violations.
               => checkRestrict(stripProv(Loc),
                    getBases(Loc), .Set,
                    getBases(Loc), .Set)
          ...</k>
          <restrict>
               Restricts:Map
               (.Map => stripProv(Loc) |-> set(getBases(Loc)))
          </restrict>
          when notBool (stripProv(Loc) in keys(Restricts))
          [structural]
     // TODO(chathhorn): finer-grain modified detection. This can fail for the
     // case of aggregates.
     rule <k> checkRestrict(loc(Base:SymBase, Offset:Int, Prov:Set), _)
               => checkRestrict(loc(Base, Offset),
                    getBases(Prov), .Set,
                    Bases, .Set)
          ...</k>
          <restrict>...
               loc(Base, Offset) |-> set(Bases:Set (.Set => getBases(Prov)))
          ...</restrict>
          [structural]

     // Next, filter out the restrict pointers where the object has been
     // unmodified in the associated block.
     syntax K ::= checkRestrict(SymLoc, Set, Set, Set, Set)
     rule <k> checkRestrict(Loc:SymLoc,
                    (SetItem(basedOn(Base:SymBase, Tag:RestrictTag)) => .Set) _,
                    (.Set => SetItem(basedOn(Base, Tag))) _, _, _)
          ...</k>
          <activeBlocks>... Tag |-> activity(_, Modified:Map) ...</activeBlocks>
          when Loc in keys(Modified)
          [structural]
     rule <k> checkRestrict(Loc:SymLoc,
                    (SetItem(basedOn(_, Tag:RestrictTag)) => .Set) _, _, _, _)
          ...</k>
          <activeBlocks>... Tag |-> activity(_, Modified:Map) ...</activeBlocks>
          when notBool (Loc in keys(Modified))
          [structural]
     rule <k> checkRestrict(_,
                    (SetItem(basedOn(_, Tag:RestrictTag)) => .Set) _, _, _, _)
          ...</k>
          <activeBlocks> Modified:Map </activeBlocks>
          when notBool (Tag in keys(Modified))
          [structural]
     rule <k> checkRestrict(Loc:SymLoc, _, _,
                    (SetItem(basedOn(Base:SymBase, Tag:RestrictTag)) => .Set) _,
                    (.Set => SetItem(basedOn(Base, Tag))) _)
          ...</k>
          <activeBlocks>... Tag |-> activity(_, Modified:Map) ...</activeBlocks>
          when Loc in keys(Modified)
          [structural]
     rule <k> checkRestrict(Loc:SymLoc, _, _,
                    (SetItem(basedOn(_, Tag:RestrictTag)) => .Set) _, _)
          ...</k>
          <activeBlocks>... Tag |-> activity(_, Modified:Map) ...</activeBlocks>
          when notBool (Loc in keys(Modified))
          [structural]
     rule <k> checkRestrict(_, _, _,
                    (SetItem(basedOn(_, Tag:RestrictTag)) => .Set) _, _)
          ...</k>
          <activeBlocks> Modified:Map </activeBlocks>
          when notBool (Tag in keys(Modified))
          [structural]
     rule checkRestrict(_, .Set, Bases:Set, .Set, Bases':Set)
               => checkRestrict(Bases Bases', Bases, Bases')
          [structural]

     // Finally, do the actual checks.
     syntax K ::= checkRestrict(Set, Set, Set)
     rule (. => checkRestrict'(B))
          ~> checkRestrict((SetItem(B:Provenance) => .Set) _, _, _)
          [structural]
     rule checkRestrict(.Set, Bases:Set, Bases':Set) => .
          when Bases ==Set Bases'
          [structural]
     rule (. => UNDEF("ECL3",
               "An object which has been modified is accessed through an expression based on a restrict-qualified pointer and another lvalue not also based on said pointer.",
               "6.7.3.1:4"))
          ~> checkRestrict(.Set, Bases:Set, Bases':Set)
          when Bases =/=Set Bases'
          [structural]

     syntax K ::= "checkRestrict'" "(" Provenance ")"
     rule <k> checkRestrict'(basedOn(Base:SymBase, _)) => . ...</k>
          <mem>... Base |-> object(T:Type, _, _) ...</mem>
          when notBool isConstType(innerType(T))
          [structural]
     rule <k> (. => UNDEF("ECL4",
               "An object which has been modified is accessed through an expression based on a restrict-qualified pointer to a const-qualified type.",
               "6.7.3.1:4"))
               ~> checkRestrict'(basedOn(Base:SymBase, _))
          ...</k>
          <mem>... Base |-> object(T:Type, _, _) ...</mem>
          when isConstType(innerType(T))
          [structural]
endmodule
