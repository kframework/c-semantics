module OTHERS-INSPECTION
  syntax KItem ::= thing()

  // int __kcc_get_obj_size(void* p);
  rule [obj-size]:
    builtin("__kcc_get_obj_size", tv(Loc:SymLoc, _) #as O::RValue))
      => thing()
    //requires notBool isNull(O)

endmodule
