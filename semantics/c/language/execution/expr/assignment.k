module C-EXPR-ASSIGNMENT
     imports BOOL
     imports K-REFLECTION
     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-MEMORY-WRITING-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     rule nclv(Loc:SymLoc, T'::Type) := tv(V:CValue, T::UType)
          => checkOverlap(stripProv(Loc), T, T')
          ~> write(Loc, V, T', keys(getReadFromMap(T)))
          ~> tv(V, stripConstants(T))
          requires notBool isRestrictType(T')
               andBool (T ==Type utype(T'))
          [structural]
     rule nclv(Loc:SymLoc, T'::Type) := tv(V:SymLoc, T::UType)
          => checkOverlap(stripProv(Loc), T, T')
          ~> checkRestrictAssign(getRestrictBlock(T'), getRelevantTags(Loc, V))
          ~> write(Loc, V, T', keys(getReadFromMap(T)))
          ~> tv(V, stripConstants(T))
          requires isRestrictType(T')
               andBool (T ==Type utype(T'))
          [structural]

     syntax K ::= checkOverlap(SymLoc, UType, Type) [function]
     rule checkOverlap(Loc:SymLoc, T::UType, T'::Type) => errorOverlap
          requires getReadFromLen(T, Loc) =/=Int byteSizeofType(T')
               andBool isOverlappedRead(T, Loc, byteSizeofType(T'))
     rule checkOverlap(_, _, _) => .K [owise]

     syntax Error ::= "errorOverlap"
     rule (.K => UNDEF("EEA1",
               "Assignment from non-exactly-overlapping overlapping read."))
          ~> errorOverlap

     syntax Set ::= getRelevantTags(SymLoc, SymLoc) [function]
     rule getRelevantTags(Loc':SymLoc, Loc:SymLoc)
          => getRelevantTags'(.K, stripProv(Loc'), getBases(Loc))

     syntax Set ::= "getRelevantTags'" "(" K "," SymLoc "," Set ")" [function]
     rule getRelevantTags'((.K => K), _, (SetItem(K:KItem) => .Set) _)
     rule getRelevantTags'((basedOn(Base, _) => .K), loc(Base:SymBase, _), _)
     rule getRelevantTags'(basedOn(Base':SymBase, Tag:Scope),
               loc(Base:SymBase, Offset:Int), Bases:Set)
          => SetItem(Tag) getRelevantTags'(.K, loc(Base:SymBase, Offset), Bases)
          requires Base =/=K Base'
     rule getRelevantTags'(.K, _, .Set) => .Set

     syntax K ::= checkRestrictAssign(Scope, Set) [function]
     rule checkRestrictAssign(Tag:Scope, Tags:Set) => errorRestrictPointerAssign1
          requires Tag in Tags
     // TODO(chathhorn): more cases here we don't catch.
     rule checkRestrictAssign(fileScope, Tags:Set) => errorRestrictPointerAssign2
          requires notBool (fileScope in Tags)
               andBool Tags =/=K .Set
     rule checkRestrictAssign(_, _) => .K [owise]

     syntax Error ::= "errorRestrictPointerAssign1" | "errorRestrictPointerAssign2"
     rule (.K => UNDEF("EEA2", "Attempt to alias restrict qualified pointers associated with the same block."))
          ~> errorRestrictPointerAssign1
     rule (.K => UNDEF("EEA3", "Attempt to alias restrict qualified pointers associated with incompatible blocks."))
          ~> errorRestrictPointerAssign2

     rule compoundAssign(LV:KResult, AExp:K)
          => #compoundAssign(LV, LV, AExp)
          [structural]

     syntax KItem ::= #compoundAssign(K, K, K)
     context #compoundAssign(_, (HOLE:KItem => reval(HOLE)), _) [result(RValue)]
     rule #compoundAssign(LV:KResult, V:RValue, AExp:K)
          => fillLHoles(LV, fillRHoles(V, AExp))
          [structural]

endmodule

