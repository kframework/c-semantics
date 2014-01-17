module C-SYMBOLIC-LOGICAL
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-STATEMENT-IF-THEN-SYNTAX

     rule tv(0, t(_, int)) && _ => tv(0, t(.Set, int))
          [structural]
     rule tv(1, t(_, int)) && E:K => simplifyTruth(E)
          [structural]
     rule tv(symVal, t(_, int)) && _ => tv(symVal, t(.Set, int))
          [structural]
     rule (V:TypedValue => simplifyTruth(V)) && _ 
          when notBool isTruthValue(V)
          [structural]   
                    
     rule tv(0, t(_, int)) || E:K => simplifyTruth(E)
          [structural]
     rule tv(1, t(_, int)) || _ => tv(1, t(.Set, int))
          [structural]
     rule tv(symVal, t(_, int)) || _ => tv(symVal, t(.Set, int))
          [structural]
     rule (V:TypedValue => simplifyTruth(V)) || _
          when notBool isTruthValue(V)
          [structural]

endmodule
