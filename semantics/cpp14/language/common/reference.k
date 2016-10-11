module CPP-REFERENCE-SYNTAX
     imports CPP-TYPING-SORTS

     syntax Bool ::= isReferenceCompatible(CPPType, CPPType) [function]
                   | isReferenceRelated(CPPType, CPPType) [function]

endmodule

module CPP-REFERENCE
     imports CPP-REFERENCE-SYNTAX
     imports BOOL
     imports COMMON-SYNTAX
     imports CPP-TYPING-SYNTAX

     rule isReferenceRelated(T1::CPPType, T2::CPPType) => true
          requires T1 ==Type T2
     // TODO(dwightguth): base classes
     rule isReferenceRelated(T1::CPPType, T2::CPPType) => false
          requires T1 =/=Type T2 andBool (notBool isCPPClassType(T1) orBool notBool isCPPClassType(T2))
     rule isReferenceCompatible(T1::CPPType, T2::CPPType) => isReferenceRelated(utype(T1), utype(T2)) andBool getQuals(T2) <=Quals getQuals(T1)


endmodule
