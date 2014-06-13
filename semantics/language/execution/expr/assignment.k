module C-EXPR-ASSIGNMENT
     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     rule lval(Loc:SymLoc, T:Type) := tv(V:CValue, T)
          => write(Loc, V, T)
          ~> transferProv(Loc, tv(V, T))
          when notBool isRestrictType(T)
               andBool (#fromArrayStatic(T) =/=K true)
          [structural]
     rule lval(Loc:SymLoc, T:Type) := tv(V:CValue, T)
          => checkArrayStaticAssign(T, tv(V, T))
          ~> write(Loc, V, T)
          ~> transferProv(Loc, tv(V, T))
          when notBool isRestrictType(T)
               andBool (#fromArrayStatic(T) ==K true)
          [structural]
     rule lval(Loc:SymLoc, T:Type) := tv(V:SymLoc, T)
          => checkRestrictAssign(getRestrictBlock(T), getRelevantTags(Loc, V))
          ~> write(Loc, V, T)
          ~> transferProv(Loc, tv(V, T))
          when isRestrictType(T)
          [structural]
     rule lval(Loc:SymLoc, T:Type) := tv(V:SymLoc, T)
          => checkArrayStaticAssign(T, tv(V, T))
          ~> checkRestrictAssign(getRestrictBlock(T), getRelevantTags(Loc, V))
          ~> write(Loc, V, T)
          ~> transferProv(Loc, tv(V, T))
          when isRestrictType(T)
               andBool (#fromArrayStatic(T) ==K true)
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
          => UNDEF("CEA4", "Attempt to alias restrict qualified pointers associated with the same block.", "6.7.3.1:4")
     // TODO(chathhorn): more cases here we don't catch.
     // rule checkRestrictAssign(global, SetItem(Tag:RestrictTag) _)
     //      => UNDEF("CEA5", "Attempt to alias restrict qualified pointers associated with the incompatible blocks.", "")
     //      when Tag =/=K global
     rule checkRestrictAssign(_, .Set) => .

     syntax Bool ::= "#fromArrayStatic" "(" Type ")" [function]
     rule #fromArrayStatic(t(SetItem(arrayStatic(_)) _, _)) => true

     syntax K ::= checkArrayStaticAssign(Type, TypedValue)
     rule checkArrayStaticAssign(
               t(SetItem(arrayStatic(N:Int)) _, pointerType(T:Type)),
               tv(loc(_, _, SetItem(fromArray(Offset:Int, Sz:Int))), _)) => .
          when (Sz -Int Offset) >=Int (N *Int byteSizeofType(T))
     rule (. => UNDEF("CEA5",
               "passing a pointer to an array object of fewer elements than required to a function with a static-qualified size.",
               "6.7.6.3"))
          ~> checkArrayStaticAssign(
               t(SetItem(arrayStatic(N:Int)) _, pointerType(T:Type)),
               tv(loc(_, _, SetItem(fromArray(Offset:Int, Sz:Int))), _))
          when (Sz -Int Offset) <Int (N *Int byteSizeofType(T))

endmodule

