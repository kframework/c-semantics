module CPP-EXPR-MEMBERS-SYNTAX
     imports INT
     imports CPP-SORTS
     imports CPP-DYNAMIC-SORTS
     imports CPP-TYPING-SORTS
     syntax KItem ::= fieldExp(LVal, Name, CPPType, Int)
endmodule

module CPP-EXPR-MEMBERS
     imports CPP-EXPR-MEMBERS-SYNTAX
     imports BOOL
     imports C-CONFIGURATION
     imports CPP-SYNTAX
     imports CPP-CLASS-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports SETTINGS-SYNTAX
     imports SYMLOC-SYNTAX

     context HOLE:Expr . _ _

     rule LV:LVal . no-template (Name(C:Class, X::CId) #as N::Name)
       => lookupFieldCPP(LV, N, type(LV))

     syntax KItem ::= lookupFieldCPP(LVal, Name, CPPType)
     //TODO(traiansf): Check access permissions
     rule <k> lookupFieldCPP(LV::LVal, Name(FC::Class, F::CId) #as N::Name, t(Qs::Quals, _, classType(C::Class)))
           => fieldExp(LV, N, addQuals(Qs, T), Offset)
          ...</k>
          <class-id> FC </class-id>
          <cenv>... F |-> (T::CPPType |-> classOffset(Offset::Int)) ...</cenv>
          requires isBaseClassOf(FC,C)

     rule fieldExp(lv(Loc:SymLoc, _, _), _, T::CPPType, Offset::Int)
          => lv(Loc +bytes Offset /Int cfg:bitsPerByte, noTrace, T)
          requires notBool isCPPBitfieldType(T)
endmodule
