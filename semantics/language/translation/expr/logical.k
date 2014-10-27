module C-EXPR-LOGICAL
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-STMT-IF-THEN-SYNTAX

     context _ && (HOLE => reval'(HOLE))
     rule tv(0, t(_, int)) && _:KResult => tv(0, t(.Set, int))
          [structural]
     rule tv(1, t(_, int)) && V:KResult => simplifyTruth(V)
          [structural]
     rule tv(symVal, t(_, int)) && _:KResult => tv(symVal, t(.Set, int))
          [structural]
     rule (tv(V:CValue, T:Type) => simplifyTruth(tv(V,T))) && _
          when notBool isTruthValue(tv(V,T)) // symVal is a truth value.
          [structural]

     context _ || (HOLE => reval'(HOLE))
     rule tv(0, t(_, int)) || V:KResult => V
          [structural]
     rule tv(1, t(_, int)) || _:KResult => tv(1, t(.Set, int))
          [structural]
     rule tv(symVal, t(_, int)) || _:KResult => tv(symVal, t(.Set, int))
          [structural]
     rule (tv(V:CValue, T:Type) => simplifyTruth(tv(V,T))) || _
          when notBool isTruthValue(tv(V,T))
          [structural]

endmodule
