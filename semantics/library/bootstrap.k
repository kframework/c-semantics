module LIBC-BOOTSTRAP-SYNTAX
     syntax KItem ::= varg(K) [hybrid, strict]
     syntax KItem ::= prepareBuiltin(CId, HeatList) [strict(2)]
     syntax KItem ::= incSymbolic(K)
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

     imports COMPAT-SYNTAX

     rule rkludge(varg(K:K)) => varg(K)

     context incSymbolic(HOLE => reval(HOLE))
     rule incSymbolic(tv(Loc:SymLoc, T:Type))
          => tv(loc(linc(base(Loc)), offset(Loc)), T)
          [structural]

     // TODO(chathhorn): This is pretty dumb. Should handle var args nicer. In
     // particular, I don't understand why we should do the consecutive
     // addresses thing.
     //TODO(LiyiLi): context prepareBuiltin(_, _ ListItem(HOLE => reval(HOLE)) _)
     //use HeatList temporally
     rule <k> handleBuiltin => Return(prepareBuiltin(F, toHeatList(makeVarArgs(P)))) ...</k>
          <curr-function> F:CId </curr-function>
          <curr-function-params> P:List </curr-function-params>
          <types>... F |-> T:Type ...</types>
          requires variadic in getParams(T)
          [structural]
     rule <k> handleBuiltin => Return(prepareBuiltin(F, toHeatList(P))) ...</k>
          <curr-function> F:CId </curr-function>
          <curr-function-params> P:List </curr-function-params>
          <types>... F |-> T:Type ...</types>
          requires notBool variadic in getParams(T)
          [structural]

     syntax List ::= makeVarArgs(List) [function]
		   | makeVarArgsAux(List) [function]
     rule makeVarArgsAux(L:List ListItem(X:CId) ListItem(vararg(0)))
          => L ListItem(X) ListItem(varg(incSymbolic(&(X))))
     rule makeVarArgsAux(L:List ListItem(X:CId)) 
		=> makeVarArgsAux(L)
		requires X =/=K vararg(0)
     rule makeVarArgs(L:List) => makeVarArgsAux(L)
		requires vararg(0) in L
     rule makeVarArgs(L:List ListItem(X:CId))
          => L ListItem(X) ListItem(varg(incSymbolic(&(X))))
          requires notBool vararg(0) in (L ListItem(X))
endmodule
