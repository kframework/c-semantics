module C-EXPRESSION-FUNCTION-CALL
     imports C-EXPRESSION-IDENTIFIER-SYNTAX
     imports C-SYM-VAL-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-DECLARATION-SYNTAX

     imports COMPAT-SYNTAX

     syntax KResult ::= rvlist(KList)

     syntax K ::= revalParams(K)
     context revalParams(klist(_,, (HOLE => reval(HOLE)),, _)) [ndheat]
     rule revalParams(klist(L:KList)) => revalParams(rvlist(L))
          when all(L, isKResult)
          [structural]
     
     context Call(_, (HOLE => revalParams(HOLE)))

     rule Call(tv(_, t(_, pointerType(t(_, prototype(t(_, functionType(T:Type, _))))))), rvlist(L:KList))
          => tv(symVal, T)
          [structural]

endmodule

