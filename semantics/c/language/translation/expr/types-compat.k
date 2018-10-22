module C-EXPR-TYPES-COMPAT
     imports BASIC-K
     imports BOOL
     imports COMMON-SORTS

     imports C-ABSTRACT-SYNTAX
     imports C-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-DYNAMIC-SYNTAX

     rule TypesCompat(T1:KResult, D1:K, T2:KResult, D2:K)
          => typesCompat(DeclType(T1, D1), DeclType(T2, D2))
          [structural]

     syntax KItem ::= typesCompat(K, K) [strict]
     rule typesCompat(T1:Type, T2:Type)
          => tv(1, ut(SetItem(IntegerConstant), int))
          requires stripQualifiers(T1) ==Type stripQualifiers(T2)
          [structural]
     rule typesCompat(T1:Type, T2:Type)
          => tv(0, ut(SetItem(IntegerConstant), int))
          requires stripQualifiers(T1) =/=Type stripQualifiers(T2)
          [structural]
endmodule
