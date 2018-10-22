module C-CHECK-RESTRICT-SYNTAX
     imports INT-SYNTAX
     imports MAP
     imports STRING
//     imports C-DYNAMIC-SORTS
     imports COMMON-SORTS
     imports SYMLOC-SORTS

     syntax KItem ::= enterRestrictBlock(Scope)
                    | exitRestrictBlock(Set)
                    | "enterRestrictTU"

     // is write?, obj being accessed
     syntax KItem ::= checkRestrict(Bool, SymLoc)
endmodule

module C-CHECK-RESTRICT
     imports C-CHECK-RESTRICT-SYNTAX
     imports C-CONFIGURATION
     imports BOOL
     imports INT
     imports K-EQUAL
     imports MEMORY-SYNTAX
     imports C-ERROR-SYNTAX
     imports SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX

     syntax RestrictStatus ::= restrictStatus(Scope, Map)

     rule <k> enterRestrictBlock(Tag::Scope) => .K ...</k>
          <restrict> .List => ListItem(restrictStatus(Tag, .Map)) </restrict>
          <curr-tu> TU::String </curr-tu>
          <tu-id> TU </tu-id>
          <has-restrict> RestrictBlocks:Set </has-restrict>
          requires Tag in RestrictBlocks
          [structural]
     rule <k> enterRestrictBlock(Tag::Scope) => .K ...</k>
          <restrict> .List </restrict>
          <curr-tu> TU::String </curr-tu>
          <tu-id> TU </tu-id>
          <has-restrict> RestrictBlocks:Set </has-restrict>
          requires notBool (Tag in RestrictBlocks)
          [structural]
     rule <k> enterRestrictBlock(Tag::Scope) => .K ...</k>
          <restrict> (.List => ListItem(restrictStatus(Tag, .Map))) RestrictStack::List </restrict>
          requires size(RestrictStack) >=Int 1
          [structural]

     rule <k> exitRestrictBlock(Locals::Set) => mergeRestricts(Tag, Locals, keys_list(R), R) ...</k>
          <restrict> (ListItem(restrictStatus(Tag::Scope, R::Map)) => .List) RestrictStack::List </restrict>
          requires size(RestrictStack) >=Int 1
          [structural]
     rule <k> exitRestrictBlock(_) => .K ...</k>
          <restrict> RestrictStack::List => .List </restrict>
          requires size(RestrictStack) <=Int 1
          [structural]

     rule <k> enterRestrictTU => .K ...</k>
          <curr-tu> TU::String </curr-tu>
          <tu-id> TU </tu-id>
          <has-restrict> RestrictBlocks:Set </has-restrict>
          requires notBool (fileScope in RestrictBlocks)
          [structural]
     rule <k> enterRestrictTU => .K ...</k>
          <restrict>... ListItem(restrictStatus(fileScope, _)) </restrict>
          [structural]
     rule <k> enterRestrictTU => .K ...</k>
          <restrict>... ListItem(restrictStatus(Tag::Scope, _)) (.List => ListItem(restrictStatus(fileScope, .Map))) </restrict>
          <curr-tu> TU::String </curr-tu>
          <tu-id> TU </tu-id>
          <has-restrict> RestrictBlocks:Set </has-restrict>
          requires (fileScope in RestrictBlocks)
               andBool (Tag =/=K fileScope)
          [structural]
     rule <k> enterRestrictTU => .K ...</k>
          <restrict> .List => ListItem(restrictStatus(fileScope, .Map)) </restrict>
          <curr-tu> TU::String </curr-tu>
          <tu-id> TU </tu-id>
          <has-restrict> RestrictBlocks:Set </has-restrict>
          requires fileScope in RestrictBlocks
          [structural]

     syntax RestrictState ::= filterBases(RestrictState, Scope) [function]
     rule filterBases(onlyRead(Bases::Set, SrcLoc::CabsLoc), S::Scope) => onlyRead(filterBases'(Bases, S), SrcLoc)
     rule filterBases(restricted(Bases::Set, SrcLoc::CabsLoc), S::Scope) => restricted(filterBases'(Bases, S), SrcLoc)
     rule filterBases(R::RestrictState, _) => R [owise]

     syntax Set ::= "filterBases'" "(" Set "," Scope ")" [function]
     rule filterBases'(SetItem(basedOn(Base::SymBase, S)) Bases::Set, S::Scope)
          => filterBases'(Bases, S)
     rule filterBases'(SetItem(basedOn(Base::SymBase, S'::Scope)) Bases::Set, S::Scope)
          => SetItem(basedOn(Base, S')) filterBases'(Bases, S)
          requires S =/=K S'
     rule filterBases'(.Set, _) => .Set

     syntax RestrictState ::= onlyRead(Set, CabsLoc)
                            | unrestricted(CabsLoc)
                            | restricted(Set, CabsLoc)

     syntax CabsLoc ::= getSrcLoc(RestrictState) [function]
     rule getSrcLoc(onlyRead(_, SrcLoc::CabsLoc)) => SrcLoc
     rule getSrcLoc(unrestricted(SrcLoc::CabsLoc)) => SrcLoc
     rule getSrcLoc(restricted(_, SrcLoc::CabsLoc)) => SrcLoc

     syntax KItem ::= mergeRestricts(Scope, Set, List, Map)
     rule mergeRestricts(Tag::Scope, Locals::Set, ListItem(Loc::SymLoc) Locs::List, R::Map)
          => mergeRestrict(Tag, Loc, filterBases({R::Map[Loc]}:>RestrictState, Tag)) ~> mergeRestricts(Tag, Locals, Locs, R)
          requires notBool (base(Loc) in Locals)
          [structural]
     rule mergeRestricts(Tag::Scope, Locals::Set, ListItem(Loc::SymLoc) Locs::List, R::Map)
          => mergeRestricts(Tag, Locals, Locs, R)
          requires base(Loc) in Locals
          [structural]
     rule mergeRestricts(_, _, .List, _) => .K
          [structural]

     // Assumes no conflict.
     syntax RestrictState ::= joinRestrictState(RestrictState, RestrictState) [function]
     rule joinRestrictState(restricted(S::Set, SrcLoc::CabsLoc), _) => restricted(S, SrcLoc)
     rule joinRestrictState(State::RestrictState, restricted(S::Set, _)) => restricted(S, getSrcLoc(State))
     rule joinRestrictState(onlyRead(S::Set, SrcLoc::CabsLoc), onlyRead(S, _)) => onlyRead(S, SrcLoc)
     rule joinRestrictState(State::RestrictState, _) => unrestricted(getSrcLoc(State)) [owise]

     syntax Bool ::= isRestrictConflict(RestrictState, RestrictState) [function]
     rule isRestrictConflict(restricted(S::Set, _), restricted(S, _)) => false
     rule isRestrictConflict(unrestricted(_), unrestricted(_)) => false
     rule isRestrictConflict(onlyRead(_, _), onlyRead(_, _)) => false
     rule isRestrictConflict(onlyRead(_, _), unrestricted(_)) => false
     rule isRestrictConflict(unrestricted(_), onlyRead(_, _)) => false
     rule isRestrictConflict(onlyRead(S::Set, _), restricted(S, _)) => false
     rule isRestrictConflict(restricted(S::Set, _), onlyRead(S, _)) => false
     rule isRestrictConflict(_, _) => true [owise]

     syntax KItem ::= mergeRestrict(Scope, SymLoc, RestrictState)
     rule <k> mergeRestrict(_, Loc::SymLoc, State::RestrictState) => .K ...</k>
          <restrict> ListItem(restrictStatus(_, R::Map => R[Loc <- State])) ...</restrict>
          requires notBool (Loc in_keys(R))
          [structural]
     rule <k> mergeRestrict(_, Loc::SymLoc, State::RestrictState) => .K ...</k>
          <restrict> ListItem(restrictStatus(_, _
               Loc |-> (State'::RestrictState => joinRestrictState(State, State'))))
          ...</restrict>
          requires notBool isRestrictConflict(State, State')
          [structural]
     rule <k> mergeRestrict(_, Loc::SymLoc, State::RestrictState) => restrictViolation ...</k>
          <restrict> ListItem(restrictStatus(_, _ Loc |-> State'::RestrictState)) ...</restrict>
          <curr-program-loc> _ => getSrcLoc(State) </curr-program-loc>
          requires isRestrictConflict(State, State')
          [structural]

     rule <k> checkRestrict(_, _) => .K ...</k>
          <restrict> .List </restrict>
          [structural]
     rule <k> checkRestrict(Write::Bool, Loc::SymLoc)
               => checkRestrict'(Write, stripProv(Loc), getBases(Loc))
          ...</k>
          <restrict> R::List </restrict>
          requires R =/=K .List
          [structural]

     syntax KItem ::= "checkRestrict'" "(" Bool "," SymLoc "," Set ")" [klabel(checkRestrictBlock)]
     rule <k> checkRestrict'(false, Loc::SymLoc, Bases::Set) => .K ...</k>
          <restrict> ListItem(restrictStatus(_, R::Map => R[Loc <- onlyRead(Bases, SrcLoc)])) ...</restrict>
          <curr-program-loc> SrcLoc::CabsLoc </curr-program-loc>
          requires notBool (Loc in_keys(R))
          [structural]
     rule <k> checkRestrict'(true, Loc::SymLoc, Bases::Set) => checkConst(Bases) ...</k>
          <restrict> ListItem(restrictStatus(_, R::Map => R[Loc <- restricted(Bases, SrcLoc)])) ...</restrict>
          <curr-program-loc> SrcLoc::CabsLoc </curr-program-loc>
          requires notBool (Loc in_keys(R))
          [structural]

     rule <k> checkRestrict'(false, Loc::SymLoc, Bases::Set) => .K ...</k>
          <restrict> ListItem(restrictStatus(_, _
               Loc |-> (State'::RestrictState => joinRestrictState(onlyRead(Bases, SrcLoc), State'))))
          ...</restrict>
          <curr-program-loc> SrcLoc::CabsLoc </curr-program-loc>
          requires notBool isRestrictConflict(onlyRead(Bases, UnknownCabsLoc), State')
          [structural]
     rule <k> checkRestrict'(false, Loc::SymLoc, Bases::Set) => restrictViolation ...</k>
          <restrict> ListItem(restrictStatus(_, _
               Loc |-> State'::RestrictState))
          ...</restrict>
          requires isRestrictConflict(onlyRead(Bases, UnknownCabsLoc), State')
          [structural]

     rule <k> checkRestrict'(true, Loc::SymLoc, Bases::Set) => .K ...</k>
          <restrict> ListItem(restrictStatus(_, _
               Loc |-> (State'::RestrictState => joinRestrictState(restricted(Bases, SrcLoc), State'))))
          ...</restrict>
          <curr-program-loc> SrcLoc::CabsLoc </curr-program-loc>
          requires notBool isRestrictConflict(restricted(Bases, UnknownCabsLoc), State')
          [structural]
     rule <k> checkRestrict'(true, Loc::SymLoc, Bases::Set) => checkConst(Bases) ~> restrictViolation ...</k>
          <restrict> ListItem(restrictStatus(_, _
               Loc |-> State'::RestrictState))
          ...</restrict>
          requires isRestrictConflict(restricted(Bases, UnknownCabsLoc), State')
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
