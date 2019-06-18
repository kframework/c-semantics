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
     rule OffsetOf(T:KResult, K:KItem, Mem:KItem) => offsetOf(DeclType(T, K), Mem)
          [structural]

     syntax KItem ::= offsetOf(KItem, KItem) [strict(1)]
     syntax SymBase ::= "accum"
     rule isStaticDuration(loc(accum,_)) => true
     rule offsetOf(T:Type, Mem:KItem)
          => toOffset(offsetOf'(lv(loc(accum, 0), T), Mem))
          [structural]

     // Rejigger the AST.
     syntax KItem ::= "offsetOf'" "(" KItem "," KItem ")" [function]
     rule offsetOf'(K:KItem, K':KItem . F:CId) => offsetOf'(K, K') . F
     rule offsetOf'(K:KItem, K1:KItem + K2:KItem) =>  offsetOf'(K, K1) + K2
     rule offsetOf'(K:KItem, * K':KItem) => * offsetOf'(K, K')
     rule offsetOf'(K:KItem, F:CId) => K . F

     syntax KItem ::= toOffset(KItem) [strict]
     rule toOffset(nclv(Loc:SymLoc, T::Type)) => tv(offset(Loc), addModifier(IntegerConstant, utype(cfg:sizeut)))
          requires notBool isBitfieldType(T)
          [structural]
     rule (.K => UNDEF("TEOFF1", "Offsetof member designator specifies a bit-field."))
          ~> toOffset(nclv(_, T::Type))
          requires isBitfieldType(T)
          [structural]
endmodule
