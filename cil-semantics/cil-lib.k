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
    => <resultValue> mival(V) </resultValue>)
    <phase> _ => terminated </phase>

  // Abort.
  rule 
    (<frame>... <k> 
      nclv(_, ExtFun("abort"))( .Exps )
    ...</k> ...</frame>
    => <resultValue> 134 </resultValue>)
    (. => <errorCell> "Aborted." </errorCell>)
    <phase> _ => terminated </phase>

endmodule
