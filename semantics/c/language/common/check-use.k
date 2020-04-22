module C-CHECK-USE-SYNTAX
     imports BASIC-K
     imports SYMLOC-SORTS

     syntax KItem ::= checkUse(KItem) [strict]
     syntax KItem ::= checkLoc(SymLoc)

endmodule

module C-CHECK-USE
     imports C-CHECK-USE-SYNTAX
     imports C-CONFIGURATION
     imports BITS-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX
     imports MEMORY-SYNTAX
     imports SETTINGS-SYNTAX

     rule checkUse(V:KResult) => V
          requires tv(...) :/=K V
          [structural]
     rule checkUse(tv(V::CValue, T::UType)) => tv(V, T)
          requires notBool (isSymLoc(V) andBool isPointerUType(T))
               andBool notBool isTrap(V)
               andBool notBool isOpaque(V)
          [structural]
     rule <k> checkUse(tv(V:Opaque, T::UType)) => tv(V, T) ...</k>
          <curr-tu> "builtin" </curr-tu>
          [structural]
     rule <k> checkUse(tv(V:Opaque, T::UType)) => checkOpaque(V) ~> tv(V, T) ...</k>
          <curr-tu> Tu::String </curr-tu>
          requires Tu =/=K "builtin"
          [structural]
     rule checkUse(tv(trap, T::UType)) => trap(T)
          [structural]
     rule <k> checkUse(tv(V:SymLoc, ut(... st: pointerType(_)) #as T::UType))
               => checkLoc(resolveLinking(V, Linkings))
               ~> tv(resolveLinking(V, Linkings), T)
          ...</k>
          <linkings> Linkings::Map </linkings>
          [structural]

     syntax Error ::= "errorLinkUnresolved"
     rule <k> checkLoc(loc(Base:LinkBase, _))
               => EXT-UNDEF("TDR2", "No definition for symbol with external linkage.")
               ~> errorLinkUnresolved
          ...</k>
          requires currentSemantics() ==K ExecutionSemantics()
          [structural]
     rule <k> checkLoc(loc(Base:LinkBase, _, _))
               => EXT-UNDEF("TDR2", "No definition for symbol with external linkage.")
               ~> errorLinkUnresolved
          ...</k>
          requires currentSemantics() ==K ExecutionSemantics()
          [structural]
     rule <k> checkLoc(Loc::SymLoc) => checkLocAllowLink(Loc)
          ...</k>
          [structural, owise]

     syntax KItem ::= checkLocAllowLink(SymLoc)

     syntax Error ::= "errorLocBounds"
     syntax KItem ::= "errorLocInvalid"
     rule checkLocAllowLink(NullPointer) => .K
          [structural]
     rule checkLocAllowLink(loc(_, _, _) #as Loc::SymLoc => stripProv(Loc))
          [structural]
     rule <k> checkLocAllowLink(loc(Base::SymBase, Offset::Int)) => .K ...</k>
          <mem>... Base |-> object(_, Sz::Int, _) ...</mem>
          requires (Offset <=Int Sz) andBool (Offset >=Int 0)
          [structural]
     rule <k> checkLocAllowLink(loc(Base::SymBase, Offset::Int))
               => UNDEF("CEE3", "Found pointer that refers outside the bounds of an object + 1.")
               ~> errorLocBounds
          ...</k>
          <mem>... Base |-> object(_, Sz::Int, _) ...</mem>
          requires (Offset >Int Sz) orBool (Offset <Int 0)
          [structural]
     rule <k> checkLocAllowLink(loc(_, _) #as Loc::SymLoc) => .K ...</k>
          <mem> Mem::Map </mem>
          requires (isStaticDuration(Loc) orBool isNativeLoc(Loc))
               andBool notBool (base(Loc) in_keys(Mem))
          [structural]
     rule <k> checkLocAllowLink(loc(_, _) #as Loc::SymLoc)
               => UNDEF("CEE4", "Referring to an object outside of its lifetime.")
               ~> errorLocInvalid
          ...</k>
          <mem> Mem::Map </mem>
          requires notBool (base(Loc) in_keys(Mem))
               andBool notBool isStaticDuration(Loc)
               andBool notBool isNativeLoc(Loc)
          [structural]

     syntax K ::= checkOpaque(Opaque) [function]
     rule checkOpaque(_) => .K
          requires notBool hasLint

endmodule
