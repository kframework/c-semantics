module C-CHECK-LOC-SYNTAX
     imports INT-SYNTAX
     imports MAP
     imports STRING
     imports C-DYNAMIC-SORTS
     imports SYMLOC-SORTS

     syntax KItem ::= enterRestrictBlock(Scope)
                    | exitRestrictBlock(Scope)

     // is write?, obj being accessed
     syntax KItem ::= checkRestrict(Bool, SymLoc)
endmodule

module C-CHECK-LOC
     imports C-CHECK-LOC-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports INT
     imports K-EQUAL
     imports MEMORY-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX

     syntax RestrictStatus ::= restrictStatus(Scope, Map)

     rule <k> enterRestrictBlock(Tag::Scope) => .K ...</k>
          <restrict> (.List => ListItem(restrictStatus(Tag, .Map))) ...</restrict>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <has-restrict> RestrictBlocks:Set </has-restrict>
          requires Tag in RestrictBlocks
          [structural]
     rule <k> enterRestrictBlock(Tag::Scope) => .K ...</k>
          <curr-tu> Tu::String </curr-tu>
          <tu-id> Tu </tu-id>
          <has-restrict> RestrictBlocks:Set </has-restrict>
          requires notBool (Tag in RestrictBlocks)
          [structural]

     rule <k> exitRestrictBlock(Tag::Scope) => .K ...</k>
          <restrict> (ListItem(restrictStatus(Tag, _)) => .List) ...</restrict>
          [structural]
     rule <k> exitRestrictBlock(Tag::Scope) => .K ...</k>
          <restrict> ListItem(restrictStatus(Tag'::Scope, _)) ...</restrict>
          requires Tag =/=K Tag'
          [structural]
     rule <k> exitRestrictBlock(Tag::Scope) => .K ...</k>
          <restrict> .List </restrict>
          [structural]

     rule <k> checkRestrict(_, _) => .K ...</k>
          <restrict> .List </restrict>
          [structural]
     rule <k> checkRestrict(Write::Bool, Loc::SymLoc)
               => checkRestrict'(Write, stripProv(Loc), intersectProv(getBases(Loc), scopeSet(R)))
               ~> checkRestrict(.List, Write, stripProv(Loc), getBases(Loc))
          ...</k>
          <restrict> R::List </restrict>
          <local-addresses> Locals::Set </local-addresses>
          requires R =/=K .List
               andBool notBool (base(Loc) in Locals)
          [structural]
     // Two minor optimizations: (1) if it's an object with a lifetime of this
     // block, then we don't need to track accesses at blocks that outlive this
     // block, and
     rule <k> checkRestrict(Write::Bool, Loc::SymLoc)
               => checkRestrict'(Write, stripProv(Loc), intersectProv(getBases(Loc), scopeSet(ListItem(Head) Tail)))
               ~> checkRestrict(Tail, Write, stripProv(Loc), getBases(Loc))
          ...</k>
          <restrict> ListItem(Head:RestrictStatus) (Tail::List => .List) </restrict>
          <local-addresses> Locals::Set </local-addresses>
          requires base(Loc) in Locals
          [structural]

     syntax KItem ::= checkRestrict(List, Bool, SymLoc, Set) [klabel(checkRestrictList)]
     rule <k> (.K => checkRestrict'(Write, Loc, intersectProv(Prov, scopeSet(ListItem(Next) ActiveScopes))))
               ~> checkRestrict(_::List (.List => ListItem(Head)), Write::Bool, Loc::SymLoc, Prov::Set)
          ...</k>
          <restrict> (ListItem(Head::RestrictStatus) => .List) ListItem(Next:RestrictStatus) ActiveScopes::List </restrict>
          [structural]
     rule <k> checkRestrict(Restrict'::List, _, _, _) => .K ...</k>
          <restrict> .List => Restrict' </restrict>
          [structural]
     rule <k> checkRestrict(Restrict'::List, _, _, _) => .K ...</k>
          <restrict> (.List => Restrict') ListItem(_) </restrict>
          [structural]

     syntax Set ::= scopeSet(List) [function]
     rule scopeSet(ListItem(R:RestrictStatus) L::List) => SetItem(scope(R)) scopeSet(L)
     rule scopeSet(.List) => .Set

     syntax Scope ::= scope(RestrictStatus) [function]
     rule scope(restrictStatus(S::Scope, _)) => S

     syntax Set ::= intersectProv(Set, Set) [function]
     rule intersectProv(SetItem(basedOn(Base::SymBase, S::Scope)) Prov::Set, Scopes::Set)
          => SetItem(basedOn(Base, S)) intersectProv(Prov, Scopes)
          requires S in Scopes
     rule intersectProv(SetItem(basedOn(Base::SymBase, S::Scope)) Prov::Set, Scopes::Set)
          => intersectProv(Prov, Scopes)
          requires notBool (S in Scopes)
     rule intersectProv(.Set, _) => .Set

     syntax KItem ::= "noRestrictAccess"  // Only non-restrict lvals.
                    | "unrestricted"      // Mult. non-restrict lvals or write.
                    | restrictAccess(Set) // Access via restrict lval.
                    | restricted(Set)     // Write via restrict lval.

     syntax KItem ::= "checkRestrict'" "(" Bool "," SymLoc "," Set ")" [klabel(checkRestrictBlock)]
     // (2) if it's an auto duration object then we don't need to track
     // accesses at the file scope (more generally, we don't need to track
     // accesses in any blocks with a longer lifetime than this auto-duration
     // object, but this is harder to calculate for cases other than these two).
     rule <k> checkRestrict'(_, Loc::SymLoc, _) => .K ...</k>
          <restrict> ListItem(restrictStatus(fileScope, _)) </restrict>
          requires isAutoDuration(Loc)
          [structural]
     rule <k> checkRestrict'(false, Loc::SymLoc, .Set) => .K ...</k>
          <restrict> ListItem(restrictStatus(S::Scope, R::Map))
               => ListItem(restrictStatus(S, R (Loc |-> noRestrictAccess)))
          ...</restrict>
          requires notBool (Loc in_keys(R))
               andBool (S ==K fileScope impliesBool notBool isAutoDuration(Loc))
          [structural]
     rule <k> checkRestrict'(true, Loc::SymLoc, .Set) => .K ...</k>
          <restrict> ListItem(restrictStatus(S::Scope, R::Map))
               => ListItem(restrictStatus(S, R (Loc |-> unrestricted)))
          ...</restrict>
          requires notBool (Loc in_keys(R))
               andBool (S ==K fileScope impliesBool notBool isAutoDuration(Loc))
          [structural]
     rule <k> checkRestrict'(false, Loc::SymLoc, Bases::Set) => .K ...</k>
          <restrict> ListItem(restrictStatus(S::Scope, R::Map))
               => ListItem(restrictStatus(S, R (Loc |-> restrictAccess(Bases))))
          ...</restrict>
          requires notBool (Loc in_keys(R))
               andBool Bases =/=K .Set
               andBool (S ==K fileScope impliesBool notBool isAutoDuration(Loc))
          [structural]
     rule <k> checkRestrict'(true, Loc::SymLoc, Bases::Set) => checkConst(Bases) ...</k>
          <restrict> ListItem(restrictStatus(S::Scope, R::Map))
               => ListItem(restrictStatus(S, R (Loc |-> restricted(Bases))))
          ...</restrict>
          requires notBool (Loc in_keys(R))
               andBool Bases =/=K .Set
               andBool (S ==K fileScope impliesBool notBool isAutoDuration(Loc))
          [structural]

     rule <k> checkRestrict'(false, Loc::SymLoc, .Set) => .K ...</k>
          <restrict> ListItem(restrictStatus(_, _
               Loc |-> noRestrictAccess))
          ...</restrict>
          [structural]
     rule <k> checkRestrict'(true, Loc::SymLoc, .Set) => .K ...</k>
          <restrict> ListItem(restrictStatus(_, _
               Loc |-> (noRestrictAccess => unrestricted)))
          ...</restrict>
          [structural]
     rule <k> checkRestrict'(_, Loc::SymLoc, .Set) => .K ...</k>
          <restrict> ListItem(restrictStatus(_, _
               Loc |-> unrestricted))
          ...</restrict>
          [structural]
     rule <k> checkRestrict'(_, Loc::SymLoc, .Set) => .K ...</k>
          <restrict> ListItem(restrictStatus(_, _
               Loc |-> (restrictAccess(_) => unrestricted)))
          ...</restrict>
          [structural]
     rule <k> checkRestrict'(_, Loc::SymLoc, .Set) => restrictViolation ...</k>
          <restrict> ListItem(restrictStatus(_, _
               Loc |-> restricted(_)))
          ...</restrict>
          [structural]

     rule <k> checkRestrict'(false, Loc::SymLoc, Bases::Set) => .K ...</k>
          <restrict> ListItem(restrictStatus(_, _
               Loc |-> (noRestrictAccess => unrestricted)))
          ...</restrict>
          requires Bases =/=K .Set
          [structural]
     rule <k> checkRestrict'(true, Loc::SymLoc, Bases::Set) => checkConst(Bases) ~> restrictViolation ...</k>
          <restrict> ListItem(restrictStatus(_, _
               Loc |-> noRestrictAccess))
          ...</restrict>
          requires Bases =/=K .Set
          [structural]
     rule <k> checkRestrict'(_, Loc::SymLoc, Bases::Set) => restrictViolation ...</k>
          <restrict> ListItem(restrictStatus(_, _
               Loc |-> unrestricted))
          ...</restrict>
          requires Bases =/=K .Set
          [structural]
     rule <k> checkRestrict'(false, Loc::SymLoc, Bases::Set) => .K ...</k>
          <restrict> ListItem(restrictStatus(_, _
               Loc |-> restrictAccess(Bases)))
          ...</restrict>
          requires Bases =/=K .Set
          [structural]
     rule <k> checkRestrict'(true, Loc::SymLoc, Bases::Set) => checkConst(Bases) ...</k>
          <restrict> ListItem(restrictStatus(_, _
               Loc |-> (restrictAccess(Bases) => restricted(Bases))))
          ...</restrict>
          requires Bases =/=K .Set
          [structural]
     rule <k> checkRestrict'(false, Loc::SymLoc, Bases'::Set) => .K ...</k>
          <restrict> ListItem(restrictStatus(_, _
               Loc |-> (restrictAccess(Bases::Set) => unrestricted)))
          ...</restrict>
          requires Bases =/=K .Set
               andBool Bases =/=K Bases'
          [structural]
     rule <k> checkRestrict'(true, Loc::SymLoc, Bases'::Set) => checkConst(Bases') ~> restrictViolation ...</k>
          <restrict> ListItem(restrictStatus(_, _
               Loc |-> restrictAccess(Bases::Set)))
          ...</restrict>
          requires Bases =/=K .Set
               andBool Bases =/=K Bases'
          [structural]

     rule <k> checkRestrict'(_, Loc::SymLoc, Bases::Set) => .K ...</k>
          <restrict> ListItem(restrictStatus(_, _
               Loc |-> restricted(Bases)))
          ...</restrict>
          requires Bases =/=K .Set
          [structural]
     rule <k> checkRestrict'(false, Loc::SymLoc, Bases'::Set) => restrictViolation ...</k>
          <restrict> ListItem(restrictStatus(_, _
               Loc |-> restricted(Bases::Set)))
          ...</restrict>
          requires Bases =/=K .Set
               andBool Bases =/=K Bases'
          [structural]
     rule <k> checkRestrict'(true, Loc::SymLoc, Bases'::Set) => checkConst(Bases') ~> restrictViolation ...</k>
          <restrict> ListItem(restrictStatus(_, _
               Loc |-> restricted(Bases::Set)))
          ...</restrict>
          requires Bases =/=K .Set
               andBool Bases =/=K Bases'
          [structural]

     syntax KItem ::= "restrictViolation"
     rule (.K => UNDEF("ECL3", "An object which has been modified is accessed through an expression based on a restrict-qualified pointer and another lvalue not also based on said pointer."))
          ~> restrictViolation
          [structural]

     syntax KItem ::= checkConst(Set)
     rule (.K => checkConst'(B))
          ~> checkConst((SetItem(B:Provenance) => .Set) _)
          [structural]
     rule checkConst(.Set) => .K
          [structural]

     syntax KItem ::= "checkConst'" "(" Provenance ")"
     rule <k> checkConst'(basedOn(Base:SymBase, _)) => .K ...</k>
          <mem>... Base |-> object(T:Type, _, _) ...</mem>
          requires notBool isConstType(innerType(T))
          [structural]
     rule <k> (.K => UNDEF("ECL4",
               "An object which has been modified is accessed through an expression based on a restrict-qualified pointer to a const-qualified type."))
               ~> checkConst'(basedOn(Base:SymBase, _))
          ...</k>
          <mem>... Base |-> object(T:Type, _, _) ...</mem>
          requires isConstType(innerType(T))
          [structural]
endmodule
