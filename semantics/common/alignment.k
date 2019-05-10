module ALIGNMENT-SYNTAX
     imports SYMLOC-SORTS
     imports INT-SYNTAX

     syntax Int ::= getAlign(SymLoc) [function]
     syntax Int ::= getNativeAlign(address: Int, max: Int) [function]
endmodule

module ALIGNMENT
     imports ALIGNMENT-SYNTAX
     imports C-CONFIGURATION
     imports K-REFLECTION
     imports SYMLOC-SYNTAX
     imports C-SETTINGS-SYNTAX

     rule getAlign(NullPointer) => cfg:alignofMalloc
     rule getAlign(Loc::SymLoc) => getAlign'(base(Loc), offset(Loc)) [owise]
     syntax Int ::= "getAlign'" "(" SymBase "," Int ")" [function, withConfig]

     rule getAlign'(obj(... align: 0)::DirectBase, _) => 0
     rule [[ getAlign'((obj(... d: link(_)) #as Base::SymBase => Base'), _) ]]
          <linkings>... Base |-> Base'::SymBase ...</linkings>
     rule getAlign'(obj(... align: Align::Int)::DirectBase, I::Int) => getNativeAlign(I %Int Align, Align) [owise]
     syntax Int ::= #getNativeAlign(Int, Int, Int) [function]
     rule getNativeAlign(Address::Int, Max::Int) => #getNativeAlign(Address, Max, 1)
     rule #getNativeAlign(Address::Int, Max::Int, Accum::Int) => #getNativeAlign(Address, Max, Accum <<Int 1)
          requires Address &Int Accum ==Int 0 andBool Accum <Int Max
     rule #getNativeAlign(_, Accum::Int, _) => Accum [owise]

endmodule
