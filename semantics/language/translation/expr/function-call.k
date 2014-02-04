module C-EXPR-FUNCTION-CALL
     imports C-SYMBOLIC-VALUE-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     imports COMPAT-SYNTAX

     syntax KResult ::= rvlist(List)

     syntax K ::= revalParams(K)
     context revalParams(list(_:List ListItem((HOLE => reval(HOLE))) _:List))
     rule revalParams(list(L:List)) => revalParams(rvlist(L))
          when all(L, isKResult)
          [structural]
     
     context Call(_, (HOLE => revalParams(HOLE)))

     rule Call(tv(_, t(_, pointerType(t(_, functionType(T:Type, _))))), 
               rvlist(_))
          => tv(symVal, T)
          [structural]

endmodule

