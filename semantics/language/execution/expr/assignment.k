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
          requires notBool isRestrictType(T)
               andBool notBool #fromArrayStatic(T)
          [structural]
     rule lval(Loc:SymLoc, T:Type) := tv(V:CValue, T)
          => checkArrayStaticAssign(T, tv(V, T))
          ~> write(Loc, V, T)
          ~> transferProv(Loc, tv(V, T))
          requires notBool isRestrictType(T)
               andBool #fromArrayStatic(T)
          [structural]
     rule lval(Loc:SymLoc, T:Type) := tv(V:SymLoc, T)
          => checkRestrictAssign(getRestrictBlock(T), getRelevantTags(Loc, V))
          ~> write(Loc, V, T)
          ~> transferProv(Loc, tv(V, T))
          requires isRestrictType(T)
          [structural]
     rule lval(Loc:SymLoc, T:Type) := tv(V:SymLoc, T)
          => checkArrayStaticAssign(T, tv(V, T))
          ~> checkRestrictAssign(getRestrictBlock(T), getRelevantTags(Loc, V))
          ~> write(Loc, V, T)
          ~> transferProv(Loc, tv(V, T))
          requires isRestrictType(T)
               andBool #fromArrayStatic(T)
          [structural]

     syntax Set ::= getRelevantTags(SymLoc, SymLoc) [function]
     rule getRelevantTags(Loc':SymLoc, Loc:SymLoc)
          => getRelevantTags'(stripProv(Loc'), getBases(Loc))

     syntax Set ::= "getRelevantTags'" "(" SymLoc "," Set ")" [function]
     // TODO(chathhorn): java port (keys).
     // rule getRelevantTags'(loc(Base:SymBase, Offset:Int),
     //           SetItem(basedOn(Base, _)) S:Set)
     //      => getRelevantTags'(loc(Base, Offset), S)
     // rule getRelevantTags'(loc(Base:SymBase, Offset:Int),
     //           SetItem(basedOn(Base':SymBase, Tag:RestrictTag)) S:Set)
     //      => SetItem(Tag) getRelevantTags'(loc(Base, Offset), S)
     //      requires Base =/=K Base'
     rule getRelevantTags'(_, .Set) => .Set

     syntax KItem ::= checkRestrictAssign(RestrictTag, Set)
     // TODO(chathhorn): java port (keys).
     // rule checkRestrictAssign(Tag:RestrictTag, SetItem(Tag':RestrictTag) S:Set)
     //      => checkRestrictAssign(Tag, S)
     //      requires Tag =/=K Tag'
     rule checkRestrictAssign(Tag:RestrictTag, SetItem(Tag) _)
          => UNDEF("CEA4", "Attempt to alias restrict qualified pointers associated with the same block.", "6.7.3.1:4")
     // TODO(chathhorn): more cases here we don't catch.
     // rule checkRestrictAssign(global, SetItem(Tag:RestrictTag) _)
     //      => UNDEF("CEA5", "Attempt to alias restrict qualified pointers associated with the incompatible blocks.", "")
     //      requires Tag =/=K global
     rule checkRestrictAssign(_, .Set) => .K

     syntax Bool ::= "#fromArrayStatic" "(" Type ")" [function]
     rule #fromArrayStatic(t(SetItem(K:K) S:Set, T:SimpleType)) => getKLabel(K) ==KLabel 'arrayStatic orBool #fromArrayStatic(t(S, T))
     rule #fromArrayStatic(_) => false [owise]

     syntax KItem ::= checkArrayStaticAssign(Type, TypedValue)
     // TODO(chathhorn): java port (keys).
     // rule checkArrayStaticAssign(
     //           t(SetItem(arrayStatic(N:Int)) _, pointerType(T:Type)),
     //           tv(loc(_, _, SetItem(fromArray(Offset:Int, Sz:Int)) _), _)) => .
     //      requires (Sz -Int Offset) >=Int (N *Int byteSizeofType(T))
     // rule (.K => UNDEF("CEA5",
     //           "passing a pointer to an array object of fewer elements than required by a function parameter with a static-qualified array size.",
     //           "6.7.6.3:7"))
     //      ~> checkArrayStaticAssign(
     //           t(SetItem(arrayStatic(N:Int)) _, pointerType(T:Type)),
     //           tv(loc(_, _, SetItem(fromArray(Offset:Int, Sz:Int)) _), _))
     //      requires (Sz -Int Offset) <Int (N *Int byteSizeofType(T))
     rule (.K => UNDEF("CEA6",
               "passing a pointer not to an array object as a function parameter with a static-qualified array size.",
               "6.7.6.3:7"))
          ~> checkArrayStaticAssign(_, tv(Loc:SymLoc, _))
          requires notBool isFromArray(Loc)

endmodule

