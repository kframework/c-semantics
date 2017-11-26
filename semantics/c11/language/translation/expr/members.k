module C-EXPR-MEMBERS
     imports C-CONFIGURATION
     imports BOOL
     imports K-EQUAL
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     rule <k> ncle(K:K, T:StructOrUnionType) . F:CId
               => le(K . F, addQualifiers(getQualifiers(T), findFieldType(F, T)))
          ...</k>
          <initializing> Initializing:Bool </initializing>
          requires notBool (Atomic() inQuals getQualifiers(T)) orBool Initializing

     rule te(K:K, T:StructOrUnionUType) . F:CId => te(K . F, utype(findFieldType(F, {type(T)}:>StructOrUnionType)))

endmodule
