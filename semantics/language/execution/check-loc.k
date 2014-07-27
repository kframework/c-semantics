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

     syntax KItem ::= "checkLoc'" "(" SymLoc ")"
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
          requires notBool (Base in keys(Mem))
               andBool notBool (Base in keys(Funs))
               andBool notBool (Base in keys(Links))
          [structural]

     syntax KItem ::= checkOffsets(Int, Int) [function]
     rule checkOffsets(Offset:Int, Len:Int) => .
          requires (Offset <=Int Len) andBool (Offset >=Int 0)
     rule checkOffsets(Offset:Int, Len:Int) => errorLocBounds
          requires (Offset >Int Len) orBool (Offset <Int 0)

     syntax Error ::= "errorLocInvalid"
                    | "errorLocBounds"
     rule errorLocInvalid
          => UNDEF("ECL2", "Referring to an object outside of its lifetime.", "6.2.4")
          [structural]
     rule errorLocBounds
          => UNDEF("ECL3", "Found pointer that refers outside the bounds of an object + 1.", "6.2.4")
          [structural]

     // TODO(chathhorn): finer-grain modified detection. This can fail for the
     // case of aggregates.
     rule <k> checkRestrict(loc(Base:SymBase, Offset:Int, Prov:Set), _)
               => .
          ...</k>
          <modified> Modified:Map </modified>
          <restrict>...
               loc(Base, Offset) |-> set((.Set => SetItem(set(getBases(Prov)))) _)
          ...</restrict>
          requires notBool loc(Base, Offset) in keys(Modified)
          [structural]
     rule <k> checkRestrict(Loc:SymLoc, _) => . ...</k>
          <restrict>
               Restricts:Map
               (.Map => stripProv(Loc) |-> set(SetItem(set(getBases(Loc)))))
          </restrict>
          requires notBool (stripProv(Loc) in keys(Restricts))
          [structural]
     rule <k> checkRestrict(loc(Base:SymBase, Offset:Int, Prov:Set), _)
               => checkRestrict(getBases(Prov), getBases(Prov), Bases)
          ...</k>
          <modified> Modified:Map </modified>
          <restrict>... loc(Base, Offset) |-> set(Bases:Set) ...</restrict>
          requires (loc(Base, Offset) in keys(Modified))
          [structural]
     rule <k> checkRestrict(loc(Base:SymBase, Offset:Int), _)
               => checkRestrict(.Set, .Set, Bases)
          ...</k>
          <modified> Modified:Map </modified>
          <restrict>... loc(Base, Offset) |-> set(Bases:Set) ...</restrict>
          requires loc(Base, Offset) in keys(Modified)
          [structural]

     syntax KItem ::= checkRestrict(Set, Set, Set)
     syntax Set ::= "#checkRestrict" "(" Set "," K "," Set "," Set ")" [function]

     rule #checkRestrict(_:Set,.K,.Set,S:Set) => S
     rule #checkRestrict(Bases:Set,.K,SetItem(K:K) S:Set,S':Set) 
	  => #checkRestrict(Bases,K,S,S') 
     rule #checkRestrict(Bases:Set,set(Bases':Set),S:Set,S':Set) 
	  => #checkRestrict(Bases,.K,S,S') 
	  requires Bases <=Set Bases'  
     rule #checkRestrict(Bases:Set,set(Bases':Set),S:Set,S':Set)
	  => #checkRestrict(Bases,.K,S,set(Bases') S')
	  requires notBool (Bases <=Set Bases')  


     rule #checkRestrict(Bases:Set,set(Bases':Set),.Set,S:Set)
	  => (set(Bases':Set) S)
	  requires notBool (Bases <=Set Bases')  

     rule (. => checkRestrict'(B))
          ~> checkRestrict((SetItem(B:Provenance) => .Set) _, _, _)
          [structural]
     rule checkRestrict(.Set, Bases:Set, (SetItem(K:K) S:Set 
		=> #checkRestrict(Bases,K,S,.Set)))
          [structural]
     rule checkRestrict(.Set, _, .Set) => .
          [structural]
     rule (. => UNDEF("ECL4", "An object which has been modified is accessed through a restrict-qualified pointer and another lvalue not also based on said pointer.", "6.7.3.1:4"))
          ~> checkRestrict(.Set, Bases:Set, PrevBases:Set)
          requires PrevBases =/=K SetItem(set(Bases))
          [structural]

     syntax KItem ::= "checkRestrict'" "(" Provenance ")"
     rule <k> checkRestrict'(basedOn(Base:SymBase)) => . ...</k>
          <mem>... Base |-> object(T:Type, _, _) ...</mem>
          requires notBool isConstType(innerType(T))
          [structural]
     rule <k> (. => UNDEF("ECL4", "An object which has been modified is accessed through a restrict-qualified pointer to a const-qualified type.", "6.7.3.1:4"))
               ~> checkRestrict'(basedOn(Base:SymBase))
          ...</k>
          <mem>... Base |-> object(T:Type, _, _) ...</mem>
          requires isConstType(innerType(T))
          [structural]
endmodule
