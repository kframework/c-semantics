// vim: set ts=2 sw=2:
module CIL-LIB
  imports CIL-SYNTAX
  imports CIL-COMMON
  imports CIL-COMMON-TYPED-VALUE

  // Exit.
  rule 
    (<frame>... <k> 
      nclv(T:Type, ExtFun("exit"))(V:TypedValue)
    ...</k> ...</frame>
    => <resultValue> val(V) </resultValue>)
    <phase> _ => terminated </phase>


endmodule
