module C-CHECK-LOC
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-COMMON-EXPR-REFERENCE-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-ALLOC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX

     imports COMPAT-SYNTAX

     // fixme could additionally use the type to check whether that type is
     // valid for that pointer
     rule checkLoc(NullPointer) => .
     rule <k> checkLoc(loc(Base:SymBase, Offset:Int))
               => checkOffsets(Offset, Len)
          ...</k>
          <mem>... Base |-> object(_, Len:Int, _) ...</mem>
          [structural]
     rule <k> checkLoc(loc(Base:SymBase, 0)) => . ...</k>
          <functions>... Base |-> _ ...</functions>
          [structural]
     rule <k> checkLoc(loc((Base:SymBase => Base'), _)) ...</k>
          <linkings>... Base |-> Base':SymBase ...</linkings>
          [structural]
     rule <k> checkLoc(loc(Base:SymBase, _)) => errorLocInvalid ...</k>
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
          => UNDEF("ECL2", "Referring to an object outside of its lifetime.", "6.2.4")
          [structural]
     rule errorLocBounds
          => UNDEF("ECL3", "Found pointer that refers outside the bounds of an object + 1.", "6.2.4")
          [structural]

     rule <k> checkRestrict(Loc:SymLoc, T:Type) => . ...</k>
          <modified> Modified:Set </modified>
          <restrict>...
               Loc |-> set((.Set => SetItem(set(getBases(T)))) _)
          ...</restrict>
          when notBool (Loc in Modified)
          [structural]
     rule <k> checkRestrict(Loc:SymLoc, T:Type) => . ...</k>
          <restrict>
               Restricts:Map (.Map => Loc |-> set(SetItem(set(getBases(T)))))
          </restrict>
          when notBool (Loc in keys(Restricts))
          [structural]
     rule <k> checkRestrict(Loc:SymLoc, T:Type)
               => checkRestrict(getBases(T), getBases(T), Bases)
          ...</k>
          <modified> Modified:Set </modified>
          <restrict>... Loc |-> set(Bases:Set) ...</restrict>
          when Loc in Modified
          [structural]

     syntax K ::= checkRestrict(Set, Set, Set)

     rule (. => checkRestrict'(B))
          ~> checkRestrict((SetItem(B:Provenance) => .Set) _, _, _)
          [structural]
     rule checkRestrict(.Set, Bases:Set, SetItem(set(Bases:Set)))
          => .
          [structural]
     rule (. => UNDEF("ECL4", "An object which has been modified is accessed through a restrict-qualified pointer and another lvalue not also based on said pointer.", "6.7.3.1:4"))
          ~> checkRestrict(.Set, Bases:Set, PrevBases:Set)
          when PrevBases =/=Set SetItem(set(Bases))

     syntax K ::= "checkRestrict'" "(" Provenance ")"
     rule <k> checkRestrict'(basedOn(Base:SymBase)) => . ...</k>
          <mem>... Base |-> object(T:Type, _, _) ...</mem>
          when notBool isConstType(innerType(T))
          [structural]
     rule checkRestrict'(unbased) => .
          [structural]
     rule <k> (. => UNDEF("ECL4", "An object which has been modified is accessed through a restrict-qualified pointer to a const-qualified type.", "6.7.3.1:4"))
               ~> checkRestrict'(basedOn(Base:SymBase))
          ...</k>
          <mem>... Base |-> object(T:Type, _, _) ...</mem>
          when isConstType(innerType(T))
          [structural]
endmodule
