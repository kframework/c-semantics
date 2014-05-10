module LIBC-BOOTSTRAP-SYNTAX
     syntax C ::= vararg(K) [hybrid, strict]
     syntax K ::= prepareBuiltin(Id, List) 
     syntax K ::= incSymbolic(K)
endmodule

module LIBC-BOOTSTRAP
     imports LIBC-BOOTSTRAP-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-BUILTIN-SYNTAX
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-TYPING-SYNTAX

     // TODO(chathhorn): not pretty
     rule rkludge(vararg(K:K)) => vararg(K) [structural, anywhere]

     syntax List ::= idsFromDeclList(List) [function]
     
     rule idsFromDeclList(
               L:List ListItem(typedDeclaration(t(_, T:SimpleType), X:Id)))
          => idsFromDeclList(L) ListItem(X)
          when T =/=K void
          [structural]
     rule idsFromDeclList(
               L:List ListItem(typedDeclaration(t(_, void), _)))
          => idsFromDeclList(L)
          [structural]
     rule idsFromDeclList(
               L:List
               ListItem(typedDeclaration(T:Type, X:Id))
               ListItem(variadic))
          => idsFromDeclList(
               L
               ListItem(typedDeclaration(T, X)))
               // assumes variadic args are placed in incremental blocks
               ListItem(vararg(incSymbolic(&(X))))
          [structural]
     rule idsFromDeclList(.List) => .List [structural]

     context incSymbolic((HOLE => reval(HOLE)))
     rule incSymbolic(tv(Loc:SymLoc, T:Type)) => tv(linc(Loc), T)
          [structural]
          
     context prepareBuiltin(_, _:List ListItem(HOLE => reval(HOLE)) _:List)
     rule handleBuiltin(F:Id, t(_, functionType(_:KResult, L:List)))
          => Return(prepareBuiltin(F, idsFromDeclList(L)))
          [structural]
endmodule
