module C-CONDITIONAL
     imports C-SYNTAX
     imports C-TYPING-SYNTAX

     // Same as IfThenElse (type issues already dealt with).
     context (HOLE => rval(HOLE) ? _ : _ [result(RValue)]
     rule tv(1, t(_, int)) ? S:K : _ => sequencePoint ~> S
          [structural]
     rule tv(0, t(_, int)) ? _ : S:K => sequencePoint ~> S
          [structural]
     rule (V:RValue => simplifyTruth(V)) ? _ : _
          requires notBool isTruthValue(V)
          [structural]

endmodule

