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
     
     rule [idsFromDeclList-one]:
          idsFromDeclList(L:List ListItem(typedDeclaration(t(_, T:K), X:Id)))
          => idsFromDeclList(L) ListItem(X)
          when T:K =/=K void
          [structural]
     rule [idsFromDeclList-void]:
          idsFromDeclList(L:List ListItem(typedDeclaration(t(_, void), _:Id)))
          => idsFromDeclList(L)
          [structural]
     rule [idsFromDeclList-vararg]:
          idsFromDeclList(
               L:List
               ListItem(typedDeclaration(T:KResult, X:Id))
               ListItem(t(_, variadic)))
          => idsFromDeclList(
               L:List 
               ListItem(typedDeclaration(T:KResult, X:Id)))
               // assumes variadic args are placed in incremental blocks
               ListItem(vararg(incSymbolic(cast(t(.Set, 
                    pointerType(t(.Set, unsigned-char))), &(X:Id)))))
          [structural]
     rule [idsFromDeclList-done]:
          idsFromDeclList(.List) => .List [structural]

     context incSymbolic((HOLE => reval(HOLE)))
     rule [incSymbolic]:
          incSymbolic(tv(Loc:SymLoc, T:KResult)) => tv(linc(Loc), T:KResult)
          [structural]
          
     context prepareBuiltin(_, _:List ListItem(HOLE => reval(HOLE)) _:List)
     rule [prepareBuiltin]:
          handleBuiltin(F:Id, t(_, functionType(_:KResult, L:List)))
          => Return(prepareBuiltin(F:Id, idsFromDeclList(L:List)))
          [structural]
endmodule
