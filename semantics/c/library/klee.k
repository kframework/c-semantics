module OTHERS-INSPECTION
  syntax KItem ::= thing()

  // int __kcc_get_obj_size(void* p);
  rule [obj-size]:
    <k> builtin("__kcc_get_obj_size", tv(Loc:SymLoc, _) #as O::RValue))
      => thing()
    ...</k>
    //requires notBool isNull(O)

endmodule
