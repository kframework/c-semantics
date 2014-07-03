module C-CHECK-LOC
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-COMMON-EXPR-REFERENCE-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX

     imports COMPAT-SYNTAX

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

     rule checkRestrict(loc(Base:SymBase, Offset:Int), T:Type)
          => checkRestrict(loc(Base, Offset, .Set), T)
     rule <k> checkRestrict(loc(Base:SymBase, Offset:Int, Prov:Set), _)
               => .
          ...</k>
          <modified> Modified:Map </modified>
          <restrict>...
               loc(Base, Offset) |-> set((.Set => SetItem(set(getBases(Prov)))) _)
          ...</restrict>
          when notBool loc(Base, Offset) in keys(Modified)
          [structural]
     rule <k> checkRestrict(Loc:SymLoc, _) => . ...</k>
          <modified> Modified:Map </modified>
          <restrict>
               Restricts:Map
               (.Map => stripProv(Loc) |-> set(SetItem(set(getBases(Loc)))))
          </restrict>
          when notBool (stripProv(Loc) in keys(Restricts))
               andBool notBool stripProv(Loc) in keys(Modified)
          [structural]
     rule <k> checkRestrict(Loc:SymLoc, _)
               => checkRestrict(getBases(Loc), getBases(Loc), SetItem(set(getBases(Loc))))
          ...</k>
          <modified> Modified:Map </modified>
          <restrict>
               Restricts:Map
               (.Map => stripProv(Loc) |-> set(SetItem(set(getBases(Loc)))))
          </restrict>
          when notBool (stripProv(Loc) in keys(Restricts))
               andBool stripProv(Loc) in keys(Modified)
          [structural]
     // TODO(chathhorn): finer-grain modified detection. This can fail for the
     // case of aggregates.
     rule <k> checkRestrict(loc(Base:SymBase, Offset:Int, Prov:Set), _)
               => checkRestrict(getBases(Prov), getBases(Prov), Bases)
          ...</k>
          <modified> Modified:Map </modified>
          <restrict>... loc(Base, Offset) |-> set(Bases:Set) ...</restrict>
          when loc(Base, Offset) in keys(Modified)
          [structural]

     syntax K ::= checkRestrict(Set, Set, Set)

     rule (. => checkRestrict'(B))
          ~> checkRestrict((SetItem(B:Provenance) => .Set) _, _, _)
          [structural]
     rule checkRestrict(.Set, Bases:Set, (SetItem(set(Bases':Set)) => .Set) _)
          when Bases <=Set Bases'
          [structural]
     rule checkRestrict(.Set, _, .Set) => .
          [structural]
     rule (. => UNDEF("ECL3",
               "An object which has been modified is accessed through an expression based on a restrict-qualified pointer and another lvalue not also based on said pointer.",
               "6.7.3.1:4"))
          ~> checkRestrict(.Set, Bases:Set, PrevBases:Set)
          when PrevBases =/=Set SetItem(set(Bases))
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
