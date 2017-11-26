module C-EXPR-OFFSETOF
     imports BASIC-K
     imports BOOL
     imports COMMON-SORTS

     imports C-ABSTRACT-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports SYMLOC-SYNTAX

     // Used by stddef.h.
     rule OffsetOf(T:KResult, K:K, Mem:K) => offsetOf(DeclType(T, K), Mem)
          [structural]

     syntax KItem ::= offsetOf(K, K) [strict(1)]
     syntax SymBase ::= "accum"
     rule isStaticDuration(loc(accum,_)) => true
     rule offsetOf(T:Type, Mem:K)
          => toOffset(offsetOf'(lv(loc(accum, 0), T), Mem))
          [structural]

     // Rejigger the AST.
     syntax KItem ::= "offsetOf'" "(" K "," K ")" [function]
     rule offsetOf'(K:K, K':K . F:CId) => offsetOf'(K, K') . F
     rule offsetOf'(K:K, K1:K + K2:K) =>  offsetOf'(K, K1) + K2
     rule offsetOf'(K:K, * K':K) => * offsetOf'(K, K')
     rule offsetOf'(K:K, F:CId) => K . F

     syntax KItem ::= toOffset(K) [strict]
     rule toOffset(nclv(Loc:SymLoc, T::Type)) => tv(offset(Loc), addModifier(IntegerConstant, utype(cfg:sizeut)))
          requires notBool isBitfieldType(T)
          [structural]
     rule (.K => UNDEF("TEOFF1", "Offsetof member designator specifies a bit-field."))
          ~> toOffset(nclv(_, T::Type))
          requires isBitfieldType(T)
          [structural]
endmodule
