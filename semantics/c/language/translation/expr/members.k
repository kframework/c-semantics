module C-EXPR-MEMBERS
     imports C-CONFIGURATION
     imports BOOL
     imports K-EQUAL
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     rule ncle(K::InitLValue, structOrUnionType #as T::Type) .init F::CId
          => le(K .init F, addQualifiers(getQualifiers(T), findFieldType(F, T)))
     rule ncle(K:K, structOrUnionType #as T::Type) . F:CId
          => le(K . F, addQualifiers(getQualifiers(T), findFieldType(F, T)))
          requires notBool (Atomic() inQuals getQualifiers(T))

     rule te(K:K, structOrUnionUType #as T::UType) . F:CId => te(K . F, rvalType(findFieldType(F, type(T))))

     rule ncle(K::InitLValue, t(... st: _:SimpleArrayType) #as T::Type) [[ N::Int ]]
          => le(K [[ N ]], addQualifiers(getQualifiers(T), getElementType(N, T)))

endmodule
