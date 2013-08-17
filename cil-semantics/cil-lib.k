// vim: set ts=2 sw=2:
module CIL-LIB
  imports CIL-SYNTAX
  imports CIL-COMMON
  imports CIL-COMMON-TYPED-VALUE

  // Exit.
  rule 
    (<frame>... <k> 
      nclv(_, ExtFun("exit"))(V:TypedValue)
    ...</k> ...</frame>
    => <result-value> mival(V) </result-value>)
    <phase> _ => terminated </phase>

  // Abort.
  rule 
    (<frame> <k> 
      nclv(T:Type, ExtFun("abort"))( .Exps ) ~> K:K 
    </k> Cells:Bag </frame> 
    => <frame> Cells </frame>)
    (. => <result-value> 134 </result-value>)
    (. => <final-computation> 
      nclv(T, ExtFun("abort"))( .Exps ) ~> K 
    </final-computation>)
    (. => <error-cell> "Aborted." </error-cell>)
    <phase> _ => terminated </phase>

endmodule
