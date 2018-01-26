module C-EXPR-EVAL
     imports BOOL
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports SYMLOC-SYNTAX

     rule reval(ncle(K:K, T::Type) => checkCompleteLValue(T) ~> te(K, utype(T)))
          requires notBool isArrayOrFunctionType(T)

     rule reval(ncle(K:K, T:ArrayType) => te(K, utype(arrayToPtrType(T))))
          requires getKLabel(K) =/=K #klabel(`lv`)
     rule reval(ncle(lv(Loc::SymLoc, _), T:ArrayType) => tv(Loc, utype(arrayToPtrType(T))))
     rule reval(ncle(K:K, T:FunctionType) => te(K, utype(pointerType(T))))
          requires getKLabel(K) =/=K #klabel(`lv`)
     rule reval(ncle(lv(Loc::SymLoc, _), T:FunctionType) => tv(Loc, utype(pointerType(T))))

     rule lv(Loc::SymLoc, T::Type) => ncle(lv(Loc, T), T)
          requires isLinkerLoc(Loc)

     rule le(K:K, T::Type) => ncle(K, T)

endmodule
