module CPP-EXPR-MEMBERS
     imports BOOL
     imports INT
     imports C-CONFIGURATION
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-SYNTAX
     imports SETTINGS-SYNTAX
     imports SYMLOC-SYNTAX
     imports CPP-CLASS-SYNTAX

     context HOLE:Expr . _ _

     rule LV:LVal . no-template N::Name
       => lookupFieldCPP(LV, N, type(LV))

     syntax KItem ::= lookupFieldCPP(LVal, Name, CPPType)
     //TODO(traiansf): Check access permissions
     rule <k> lookupFieldCPP(LV::LVal, Name(NoNNS(), F::CId) #as N::Name, t(Qs::Quals, _, classType(C::Class)))
           => fieldExp(LV, N, addQuals(Qs, T), Offset)
          ...</k>
          <class-id> C </class-id>
          <cenv>... F |-> (T::CPPType |-> classOffset(Offset::Int)) ...</cenv>

     syntax KItem ::= fieldExp(LVal, Name, CPPType, Int)
     rule fieldExp(lv(Loc:SymLoc, _, _), _, T::CPPType, Offset::Int)
          => lv(Loc +bytes Offset /Int cfg:bitsPerByte, noTrace, T)
          requires notBool isCPPBitfieldType(T)
endmodule
