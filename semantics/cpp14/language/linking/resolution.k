module CPP-LINKING-RESOLUTION
     imports COMMON-RESOLUTION-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports C-CONFIGURATION
     imports COLLECTIONS
     imports LIST
     imports MAP
     imports COMPAT-SYNTAX
     imports SYMLOC-SYNTAX

     // Linking resolution for class members with static storage
     rule <k> resolveCPPReference(OdrBase::SymBase) ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(ktriple(Tu::String, C:Class :: X::CId, T:K)) => .Set) _::Set
          ...</odr-decls>
          <odr-defs>... C :: X |-> (T |-> Base'::SymBase _::Map) ...</odr-defs>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <cenv>... X |-> (T |-> kpair(_, (Base::SymBase => Base')) _::Map) ...</cenv>
          <linkings>... (.Map => Base |-> Base') ...</linkings>
          requires isLinkerLoc(Base)

     rule <k> resolveCPPReference(OdrBase::SymBase) ...</k>
          <odr-decls>...
               OdrBase |-> (SetItem(ktriple(Tu::String, C:Class :: X::CId, T:K)) => .Set) _::Set
          ...</odr-decls>
          <odr-defs>... C :: X |-> (T |-> _ _::Map) ...</odr-defs>
          <tu-id> Tu </tu-id>
          <class-id> C </class-id>
          <cenv>... X |-> (T |-> kpair(_, Base::SymBase) _::Map) ...</cenv>
          requires notBool isLinkerLoc(Base)

endmodule
