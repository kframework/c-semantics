module C-EXPR-MEMBERS
     imports C-CONFIGURATION
     imports BOOL
     imports K-EQUAL
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     rule ncle(K::InitLValue, T:StructOrUnionType) .init F::CId
          => le(K .init F, addQualifiers(getQualifiers(T), findFieldType(F, T)))
     rule ncle(K:K, T:StructOrUnionType) . F:CId
          => le(K . F, addQualifiers(getQualifiers(T), findFieldType(F, T)))
          requires notBool (Atomic() inQuals getQualifiers(T))

     rule te(K:K, T:StructOrUnionUType) . F:CId => te(K . F, utype(findFieldType(F, {type(T)}:>StructOrUnionType)))

     rule ncle(K::InitLValue, T:ArrayType) [[ N::Int ]]
          => le(K [[ N ]], addQualifiers(getQualifiers(T), getElementType(N, T)))

endmodule
