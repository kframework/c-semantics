module CPP-REFERENCE-SYNTAX
     imports CPP-TYPING-SORTS
     imports CPP-DYNAMIC-SORTS

     syntax Bool ::= isReferenceCompatible(CPPType, CPPType) [function]
                   | isReferenceRelated(CPPType, CPPType) [function]
                   | isValidReferenceType(CPPType) [function]

     syntax ReferenceBindingResult ::= referenceBindingResult(Val)
     syntax ValResult ::= ReferenceBindingResult

     syntax Expr ::= bindReferenceExec(Expr, Expr)

endmodule

module CPP-REFERENCE
     imports CPP-REFERENCE-SYNTAX
     imports BOOL
     imports COMMON-SYNTAX
     imports CPP-TYPING-SYNTAX
     imports CPP-CONVERSION-SYNTAX // isSimilar

     // @ref n4820 9.3.3/4
     rule isReferenceRelated(T1::CPPType, T2::CPPType) => true
          requires isSimilar(utype(T1), utype(T2))

     rule isReferenceRelated(t(... st: classType(...)) #as T1::CPPType, t(... st: classType(...)) #as T2::CPPType) => isBaseClassOf(T1, T2)

     rule isReferenceRelated(T1::CPPType, T2::CPPType) => false
          [owise]

     rule isReferenceCompatible(T1::CPPType, T2::CPPType) => isReferenceRelated(T1, T2) andBool getQuals(T2) <=Quals getQuals(T1)

     rule isValidReferenceType(t(... st: rvRefType(_))) => true

     rule isValidReferenceType(t(... st: lvRefType(t(... q: Q::Quals)))) => Const() inQuals Q andBool notBool Volatile() inQuals Q

endmodule
