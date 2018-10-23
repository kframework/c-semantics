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
     rule getAlign(Loc::SymLoc) => getAlign'(base(Loc), offset(Loc), #configuration) [owise]
     syntax Int ::= "getAlign'" "(" SymBase "," Int "," K ")" [function]

     rule getAlign'(obj(... align: 0), _, _) => 0
     rule getAlign'((obj(... d: link(_)) #as Base::SymBase => Base'), _, <generatedTop>... <linkings>... Base |-> Base'::SymBase ...</linkings> ...</generatedTop>)
     rule getAlign'(obj(... align: Align::Int), I::Int, _) => getNativeAlign(I %Int Align, Align) [owise]
     syntax Int ::= #getNativeAlign(Int, Int, Int) [function]
     rule getNativeAlign(Address::Int, Max::Int) => #getNativeAlign(Address, Max, 1)
     rule #getNativeAlign(Address::Int, Max::Int, Accum::Int) => #getNativeAlign(Address, Max, Accum <<Int 1)
          requires Address &Int Accum ==Int 0 andBool Accum <Int Max
     rule #getNativeAlign(_, Accum::Int, _) => Accum [owise]

endmodule
