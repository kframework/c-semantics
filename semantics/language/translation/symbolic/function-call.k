module C-SYMBOLIC-FUNCTION-CALL
     imports C-SYMBOLIC-VALUE-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-DECLARATION-SYNTAX

     imports COMPAT-SYNTAX

     syntax KResult ::= rvlist(KList)

     syntax K ::= revalParams(K)
     context revalParams(klist(_,, (HOLE => reval(HOLE)),, _))
     rule revalParams(klist(L:KList)) => revalParams(rvlist(L))
          when all(L, isKResult)
          [structural]
     
     context Call(_, (HOLE => revalParams(HOLE)))

     rule Call(tv(_, t(_, pointerType(t(_, prototype(t(_, functionType(T:Type, _))))))), _)
          => tv(symVal, T)
          [structural]
     rule Call(tv(_, t(_, pointerType(t(_, functionType(T:Type, _))))), _)
          => tv(symVal, T)
          [structural]

endmodule

