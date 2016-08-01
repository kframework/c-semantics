module C-EXPR-OFFSETOF
     imports BASIC-K
     imports COMMON-SORTS
     imports SYMLOC-SYNTAX
     imports C-ABSTRACT-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

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
     // TODO(chathhorn): array indexing?
     syntax KItem ::= "offsetOf'" "(" K "," K ")" [function]
     rule offsetOf'(K:K, K':K . F:CId) => offsetOf'(K, K') . F
     rule offsetOf'(K:K, K1:K + K2:K) =>  offsetOf'(K, K1) + K2
     rule offsetOf'(K:K, * K':K) => * offsetOf'(K, K')
     rule offsetOf'(K:K, F:CId) => K . F

     syntax KItem ::= toOffset(K) [strict]
     rule toOffset(nclv(Loc:SymLoc, _)) => tv(offset(Loc), utype(cfg:sizeut))
          [structural]
endmodule
