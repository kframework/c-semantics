module C-EXPR-ASSIGNMENT
     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     rule nclv(Loc:SymLoc, T':Type) := tv(V:CValue, T:Type)
          => checkOverlap(stripProv(Loc), T)
          ~> write(Loc, V, T)
          ~> transferProv(Loc, tv(V, T))
          when notBool isRestrictType(T)
               andBool (#fromArrayStatic(T') =/=K true)
               andBool (T ==Type T')
          [structural]
     rule nclv(Loc:SymLoc, T':Type) := tv(V:CValue, T:Type)
          => checkOverlap(stripProv(Loc), T)
          ~> checkArrayStaticAssign(T', tv(V, T))
          ~> write(Loc, V, T)
          ~> transferProv(Loc, tv(V, T))
          when notBool isRestrictType(T)
               andBool (#fromArrayStatic(T') ==K true)
               andBool (T ==Type T')
          [structural]
     rule nclv(Loc:SymLoc, T':Type) := tv(V:SymLoc, T:Type)
          => checkOverlap(stripProv(Loc), T)
          ~> checkRestrictAssign(getRestrictBlock(T), getRelevantTags(Loc, V))
          ~> write(Loc, V, T)
          ~> transferProv(Loc, tv(V, T))
          when isRestrictType(T)
               andBool (#fromArrayStatic(T') =/=K true)
               andBool (T ==Type T')
          [structural]
     rule nclv(Loc:SymLoc, T':Type) := tv(V:SymLoc, T:Type)
          => checkOverlap(stripProv(Loc), T)
          ~> checkArrayStaticAssign(T', tv(V, T))
          ~> checkRestrictAssign(getRestrictBlock(T), getRelevantTags(Loc, V))
          ~> write(Loc, V, T)
          ~> transferProv(Loc, tv(V, T))
          when isRestrictType(T)
               andBool (#fromArrayStatic(T') ==K true)
               andBool (T ==Type T')
          [structural]

     syntax K ::= checkOverlap(SymLoc, Type)
     rule checkOverlap(_, T:Type) => .K
          when notBool hasReadFrom(T)
          [structural]
     rule checkOverlap(Loc:SymLoc, T:Type) => .K
          when getReadFrom(T) ==K Loc
          [structural]
     rule checkOverlap(Loc:SymLoc, T:Type) => .K
          when notBool sameBase(getReadFrom(T), Loc)
          [structural]
     rule checkOverlap(Loc:SymLoc, T:Type) => .K
          when (getReadFrom(T) +bytes byteSizeofType(T)) <=bytes Loc
          [structural]
     rule checkOverlap(Loc:SymLoc, T:Type) => .K
          when (Loc +bytes byteSizeofType(T)) <=bytes getReadFrom(T)
          [structural]
     rule (. => UNDEF("EEA1",
               "assignment from non-exactly-overlapping overlapping read.",
               "6.5.16.2"))
          ~> checkOverlap(Loc:SymLoc, T:Type)
          when sameBase(getReadFrom(T), Loc)
               andBool (getReadFrom(T) =/=K Loc)
               andBool (((getReadFrom(T) +bytes byteSizeofType(T)) >bytes Loc)
               orBool ((Loc +bytes byteSizeofType(T)) >bytes getReadFrom(T)))
          [structural]

     syntax Set ::= getRelevantTags(SymLoc, SymLoc) [function]
     rule getRelevantTags(Loc':SymLoc, Loc:SymLoc)
          => getRelevantTags'(stripProv(Loc'), getBases(Loc))

     syntax Set ::= "getRelevantTags'" "(" SymLoc "," Set ")" [function]
     rule getRelevantTags'(loc(Base:SymBase, Offset:Int),
               SetItem(basedOn(Base, _)) S:Set)
          => getRelevantTags'(loc(Base, Offset), S)
     rule getRelevantTags'(loc(Base:SymBase, Offset:Int),
               SetItem(basedOn(Base':SymBase, Tag:RestrictTag)) S:Set)
          => SetItem(Tag) getRelevantTags'(loc(Base, Offset), S)
          when Base =/=K Base'
     rule getRelevantTags'(_, .Set) => .Set

     syntax K ::= checkRestrictAssign(RestrictTag, Set)
     rule checkRestrictAssign(Tag:RestrictTag, SetItem(Tag':RestrictTag) S:Set)
          => checkRestrictAssign(Tag, S)
          when Tag =/=K Tag'
     rule checkRestrictAssign(Tag:RestrictTag, SetItem(Tag) _)
          => UNDEF("EEA2", "Attempt to alias restrict qualified pointers associated with the same block.", "6.7.3.1:4")
     // TODO(chathhorn): more cases here we don't catch.
     // rule checkRestrictAssign(global, SetItem(Tag:RestrictTag) _)
     //      => UNDEF("EEA2", "Attempt to alias restrict qualified pointers associated with the incompatible blocks.", "")
     //      when Tag =/=K global
     rule checkRestrictAssign(_, .Set) => .

     syntax Bool ::= "#fromArrayStatic" "(" Type ")" [function]
     rule #fromArrayStatic(t(SetItem(arrayStatic(_)) _, _)) => true

     syntax K ::= checkArrayStaticAssign(Type, RValue)
     rule checkArrayStaticAssign(
               t(SetItem(arrayStatic(N:Int)) _, pointerType(T:Type)),
               tv(loc(_, _, SetItem(fromArray(Offset:Int, Sz:Int)) _), _)) => .
          when (Sz -Int Offset) >=Int (N *Int byteSizeofType(T))
          [structural]
     rule (. => UNDEF("EEA3",
               "passing a pointer to an array object of fewer elements than required by a function parameter with a static-qualified array size.",
               "6.7.6.3:7"))
          ~> checkArrayStaticAssign(
               t(SetItem(arrayStatic(N:Int)) _, pointerType(T:Type)),
               tv(loc(_, _, SetItem(fromArray(Offset:Int, Sz:Int)) _), _))
          when (Sz -Int Offset) <Int (N *Int byteSizeofType(T))
          [structural]
     rule (. => UNDEF("EEA4",
               "passing a pointer not to an array object as a function parameter with a static-qualified array size.",
               "6.7.6.3:7"))
          ~> checkArrayStaticAssign(_, tv(Loc:SymLoc, _))
          when notBool isFromArray(Loc)
          [structural]

endmodule
