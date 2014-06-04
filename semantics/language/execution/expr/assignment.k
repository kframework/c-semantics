module C-EXPR-ASSIGNMENT
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     rule lval(Loc:SymLoc, T':Type) := tv(V:CValue, T:Type)
          => write(Loc, V, T')
          ~> transferProv(Loc, tv(V, T'))
          when T' ==Type T
               andBool notBool isRestrictType(T')
          [structural]
     rule lval(Loc:SymLoc, T':Type) := tv(V:SymLoc, T:Type)
          => checkRestrictAssign(
               getRestrictBlock(T'), getRelevantTags(Loc, V))
          ~> write(Loc, V, T')
          ~> transferProv(Loc, tv(V, T'))
          when T' ==Type T
               andBool isRestrictType(T')
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

endmodule

