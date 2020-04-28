module C-SYMLOC-SYNTAX
     imports SYMLOC-SYNTAX
     imports C-DYNAMIC-SORTS
     imports C-TYPING-SORTS
     imports COMMON-SORTS

     // Base, type
     syntax SymBase ::= bnew(Int, Type, Duration) [function]
     syntax SymBase ::= bnew(Int, Type, LinkDuration) [function, klabel(bnew2)]
     syntax SymBase ::= linc(Type, Duration) [function]
     syntax SymLoc ::= lnew(SymBase) [function]
     syntax SymLoc ::= restrictedNew(SymBase, Scope) [function]

     syntax Bool ::= hasUnionMarker(SymLoc) [function]
     syntax Bool ::= ifFromArrayInBounds(SymLoc, UType, Int) [function]

     syntax SymLoc ::= stripBases(SymLoc) [function]
endmodule

module C-SYMLOC
     imports C-SYMLOC-SYNTAX
     imports BOOL
     imports K-REFLECTION
     imports SET
     imports COMPAT-SYNTAX
     imports C-ALIGNMENT-SYNTAX
     imports C-BITSIZE-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     rule bnew(I::Int, T::Type, D::Duration) => obj(I, getAlignas(T), D) [owise]
     rule bnew(I::Int, T::Type, D::LinkDuration) => obj(I, getAlignas(T), D) [owise]

     rule linc(T::Type, D::Duration) => bnew(!I:Int, T, D)

     rule lnew(Base::SymBase) => loc(Base, 0)

     rule restrictedNew(Base:SymBase, Tag:Scope) => addProv(basedOn(Base, Tag), lnew(Base))

     rule stripBases(loc(_, _, (SetItem(K:KItem) => .Set) _))
          requires basedOn(...) :=K K
     rule stripBases(Loc:SymLoc) => Loc [owise]

     rule ifFromArrayInBounds(loc(_, _, SetItem(K:KItem) S:Set), T::UType, I:Int)
          => #ifFromArrayInBounds(K, S, T, I)
     rule ifFromArrayInBounds(Loc:SymLoc, _, _) => true
          requires notBool isFromArray(Loc)

     syntax Bool ::= #ifFromArrayInBounds(K, Set, UType, Int) [function]
     rule #ifFromArrayInBounds(fromArray(Offset:Int, Len:Int, _), _, T::UType, I:Int)
          => true
          requires (Offset +Int (I *Int byteSizeofType(innerType(T))) >=Int 0)
               andBool (Offset +Int (I *Int byteSizeofType(innerType(T))) <=Int Len)
     rule #ifFromArrayInBounds(fromArray(Offset:Int, Len:Int, _), _, T::UType, I:Int)
          => false
          requires (Offset +Int (I *Int byteSizeofType(innerType(T))) <Int 0)
               orBool (Offset +Int (I *Int byteSizeofType(innerType(T))) >Int Len)
     rule #ifFromArrayInBounds(K:K, .Set, _, _) => true
          requires fromArray(...) :/=K K
     rule #ifFromArrayInBounds(K:K, SetItem(K':KItem) S:Set, T::UType, I:Int)
          => #ifFromArrayInBounds(K', S, T, I)
          requires fromArray(...) :/=K K

endmodule
