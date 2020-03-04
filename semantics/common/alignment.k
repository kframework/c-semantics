module ALIGNMENT-SYNTAX
     imports SYMLOC-SORTS
     imports INT-SYNTAX

     syntax Int ::= getAlign(SymLoc) [function, withConfig]
     syntax Int ::= getNativeAlign(address: Int, max: Int) [function]
endmodule

module ALIGNMENT
     imports ALIGNMENT-SYNTAX
     imports C-CONFIGURATION
     imports K-REFLECTION
     imports SYMLOC-SYNTAX
     imports C-SETTINGS-SYNTAX

     rule getAlign(NullPointer) => cfg:alignofMalloc
     rule getAlign(Loc::SymLoc) => getAlign'(base(Loc), offset(Loc))
          requires notBool isLinkerLoc(Loc) andBool Loc =/=K NullPointer
     rule [[ getAlign(Loc::SymLoc => resolveLinking(Loc, Linkings)) ]]
          <linkings> Linkings::Map </linkings>
          requires isLinkerLoc(Loc) andBool base(Loc) in_keys(Linkings)
     rule getAlign(Loc::SymLoc) => getAlign'(base(Loc), offset(Loc))
          [owise]

     syntax Int ::= "getAlign'" "(" SymBase "," Int ")" [function]
     rule getAlign'(obj(... align: Align::Int)::DirectBase, I::Int) => getNativeAlign(I, Align)
     rule getAlign'(obj(... align: Align::Int)::LinkBase, I::Int) => getNativeAlign(I, Align)

     rule getNativeAlign(_, 0) => 0
     rule getNativeAlign(Address::Int, Max::Int) => #getNativeAlign(Address %Int Max, Max, 1) [owise]

     syntax Int ::= #getNativeAlign(Int, Int, Int) [function]
     rule #getNativeAlign(Address::Int, Max::Int, Accum::Int)
          => #getNativeAlign(Address, Max, Accum <<Int 1)
          requires Address &Int Accum ==Int 0 andBool Accum <Int Max
     rule #getNativeAlign(_, Accum::Int, _) => Accum [owise]

endmodule
