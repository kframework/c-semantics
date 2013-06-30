module LIBC-BOOTSTRAP-SYNTAX
     syntax C ::= "vararg" "(" K ")" [hybrid, strict]
     syntax K ::= "prepareBuiltin" "(" Id "," KList ")" 
     syntax K ::= incSymbolic(K)
endmodule

module LIBC-BOOTSTRAP
     imports LIBC-BOOTSTRAP-SYNTAX

     imports C-DYNAMIC-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-COMPAT-SYNTAX
     imports C-EXPRESSION-SYNTAX
     imports C-TYPING-SYNTAX
     imports C-CONVERSION-SYNTAX

     // TODO(chathhorn): not pretty
     rule rkludge(vararg(K:K)) => vararg(K) [structural, anywhere]

     syntax KList ::= idsFromDeclList(KList) [function]
     
     rule [idsFromDeclList-one]:
          idsFromDeclList((L:KList,, typedDeclaration(t(_, T:K), X:Id)))
          => idsFromDeclList(L:KList),, X:Id
          when T:K =/=K void
          [structural]
     rule [idsFromDeclList-void]:
          idsFromDeclList((L:KList,, typedDeclaration(t(_, void), _:Id)))
          => idsFromDeclList(L:KList)
          [structural]
     rule [idsFromDeclList-vararg]:
          idsFromDeclList((L:KList,, 
               typedDeclaration(T:KResult, X:Id),, t(_, variadic)))
          => idsFromDeclList((L:KList,, typedDeclaration(T:KResult, X:Id)))
               // assumes variadic args are placed in incremental blocks
               ,, vararg(incSymbolic(cast(t(.Set, 
               pointerType(t(.Set, unsigned-char))), &(X:Id))))
          [structural]
     rule [idsFromDeclList-done]:
          idsFromDeclList(.KList) => .KList [structural]

     context incSymbolic((HOLE => reval(HOLE)))
     rule [incSymbolic]:
          incSymbolic(tv(Loc:SymLoc, T:KResult)) => tv(linc(Loc), T:KResult)
          [structural]
          
     context prepareBuiltin(_, (_,, (HOLE => reval(HOLE)),, _))
     rule [prepareBuiltin]:
          handleBuiltin(F:Id, t(_, functionType(_:KResult, L:KList)))
          => Return(prepareBuiltin(F:Id, idsFromDeclList(L:KList)))
          [structural]
endmodule
