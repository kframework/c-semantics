module C-EXPR-ASSIGNMENT
     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     rule nclv(Loc:SymLoc, T':Type) := tv(V:CValue, T:Type)
          => checkOverlap(stripProv(Loc), T, T')
          ~> write(Loc, V, T')
          ~> transferProv(Loc, tv(V, T))
          requires notBool isRestrictType(T)
               andBool notBool fromArrayStatic(T')
               andBool (T ==Type T')
          [structural]
     rule nclv(Loc:SymLoc, T':Type) := tv(V:CValue, T:Type)
          => checkOverlap(stripProv(Loc), T, T')
          ~> checkArrayStaticAssign(T', V)
          ~> write(Loc, V, T')
          ~> transferProv(Loc, tv(V, T))
          requires notBool isRestrictType(T)
               andBool fromArrayStatic(T')
               andBool (T ==Type T')
          [structural]
     rule nclv(Loc:SymLoc, T':Type) := tv(V:SymLoc, T:Type)
          => checkOverlap(stripProv(Loc), T, T')
          ~> checkRestrictAssign(getRestrictBlock(T), getRelevantTags(Loc, V))
          ~> write(Loc, V, T')
          ~> transferProv(Loc, tv(V, T))
          requires isRestrictType(T)
               andBool (T ==Type T')
          [structural]
     rule nclv(Loc:SymLoc, T':Type) := tv(V:SymLoc, T:Type)
          => checkOverlap(stripProv(Loc), T, T')
          ~> checkArrayStaticAssign(T', V)
          ~> checkRestrictAssign(getRestrictBlock(T), getRelevantTags(Loc, V))
          ~> write(Loc, V, T')
          ~> transferProv(Loc, tv(V, T))
          requires isRestrictType(T)
               andBool fromArrayStatic(T')
               andBool (T ==Type T')
          [structural]

     syntax KItem ::= checkOverlap(SymLoc, Type, Type)
     rule checkOverlap(_, T:Type, _) => .K
          requires notBool hasReadFrom(T)
          [structural]
     rule checkOverlap(Loc:SymLoc, T:Type, T':Type) => .K
          requires getReadFromLoc(T) ==K Loc
               andBool getReadFromLen(T) ==K byteSizeofType(T')
          [structural]
     rule checkOverlap(Loc:SymLoc, T:Type, _) => .K
          requires notBool sameBase(getReadFromLoc(T), Loc)
          [structural]
     rule checkOverlap(Loc:SymLoc, T:Type, _) => .K
          requires (getReadFromLoc(T) +bytes getReadFromLen(T)) <=bytes Loc
          [structural]
     rule checkOverlap(Loc:SymLoc, T:Type, T':Type) => .K
          requires (Loc +bytes byteSizeofType(T')) <=bytes getReadFromLoc(T)
          [structural]
     rule (.K => UNDEF("EEA1",
               "assignment from non-exactly-overlapping overlapping read.",
               "6.5.16.2"))
          ~> checkOverlap(Loc:SymLoc, T:Type, T':Type)
          requires sameBase(getReadFromLoc(T), Loc)
               andBool ((getReadFromLoc(T) =/=K Loc)
               andBool (((getReadFromLoc(T) +bytes getReadFromLen(T)) >bytes Loc)
               orBool ((Loc +bytes byteSizeofType(T)) >bytes getReadFromLoc(T))))
               orBool (getReadFromLoc(T) ==K Loc 
               andBool getReadFromLen(T) =/=K byteSizeofType(T'))
          [structural]

     syntax Set ::= getRelevantTags(SymLoc, SymLoc) [function]
     rule getRelevantTags(Loc':SymLoc, Loc:SymLoc)
          => getRelevantTags'(.K, stripProv(Loc'), getBases(Loc))

     syntax Set ::= "getRelevantTags'" "(" K "," SymLoc "," Set ")" [function]
     rule getRelevantTags'((.K => K), _, (SetItem(K:K) => .Set) _)
     rule getRelevantTags'((basedOn(Base, _) => .K), loc(Base:SymBase, _), _)
     rule getRelevantTags'(basedOn(Base':SymBase, Tag:RestrictTag),
               loc(Base:SymBase, Offset:Int), Bases:Set)
          => SetItem(Tag) getRelevantTags'(.K, loc(Base:SymBase, Offset), Bases)
          requires Base =/=K Base'
     rule getRelevantTags'(.K, _, .Set) => .Set

     syntax KItem ::= checkRestrictAssign(RestrictTag, Set)
     rule checkRestrictAssign(Tag:RestrictTag, Tags:Set) => .K
          requires (Tag =/=K global) andBool notBool (Tag in Tags)
     rule checkRestrictAssign(Tag:RestrictTag, Tags:Set)
          => UNDEF("EEA2", "Attempt to alias restrict qualified pointers associated with the same block.", "6.7.3.1:4")
          requires Tag in Tags
     rule checkRestrictAssign(global, .Set) => .K
     // TODO(chathhorn): more cases here we don't catch.
     rule checkRestrictAssign(global, SetItem(_) _)
          => UNDEF("EEA3", "Attempt to alias restrict qualified pointers associated with incompatible blocks.", "6.7.3.1:4")

     syntax Bool ::= fromArrayStatic(Type) [function]
     rule fromArrayStatic(t(SetItem(K:K) S:Set, T:SimpleType))
          => (getKLabel(K) ==KLabel 'arrayStatic) orBool fromArrayStatic(t(S, T))
     rule fromArrayStatic(_) => false [owise]

     syntax KItem ::= checkArrayStaticAssign(Type, CValue)
                    | "checkArrayStaticAssign'" "(" Type "," Modifier "," Provenance ")"

     rule checkArrayStaticAssign(t(Mods:Set, pointerType(T:Type)), loc(_, _, Prov:Set))
          => checkArrayStaticAssign'(T,
               getFirstMatch(Mods, 'arrayStatic),
               getFirstMatch(Prov, 'fromArray))
     rule (.K => UNDEF("EEA4",
               "passing a pointer not to an array object as a function parameter with a static-qualified array size.",
               "6.7.6.3:7"))
          ~> checkArrayStaticAssign(_, Loc:SymLoc)
          requires notBool isFromArray(Loc)

     rule checkArrayStaticAssign'(T:Type,
               arrayStatic(N:Int), fromArray(Offset:Int, Sz:Int))
          => .K
          requires (Sz -Int Offset) >=Int (N *Int byteSizeofType(T):>Int)
     rule (.K => UNDEF("EEA5",
               "passing a pointer to an array object of fewer elements than required by a function parameter with a static-qualified array size.",
               "6.7.6.3:7"))
          ~> checkArrayStaticAssign'(T:Type,
               arrayStatic(N:Int), fromArray(Offset:Int, Sz:Int))
          requires (Sz -Int Offset) <Int (N *Int byteSizeofType(T):>Int)

     syntax KItem ::= getFirstMatch(Set, KLabel) [function]
                    | "getFirstMatch'" "(" K "," Set "," KLabel ")" [function]

     rule getFirstMatch(S:Set, L:KLabel) => getFirstMatch'(.K, S, L)

     rule getFirstMatch'((.K => K), (SetItem(K:K) => .Set) _, _)
     rule getFirstMatch'((K:K => .K), _, L:KLabel)
          requires getKLabel(K) =/=KLabel L
     rule getFirstMatch'(K:K, _, L:KLabel) => K
          requires getKLabel(K) ==KLabel L
     rule getFirstMatch'(.K, .Set, _) => .K

endmodule

