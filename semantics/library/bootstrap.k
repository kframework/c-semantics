module LIBC-BOOTSTRAP-SYNTAX
     imports C-SYNTAX

     syntax KItem ::= varg(K) [strict]
     //TODO(liyili): might not need this if we have hybrid label
     syntax RValue ::= vargResult(K)
     syntax KItem ::= prepareBuiltin(CId, HeatList) [strict(2)]
     syntax KItem ::= incSymbolic(K)
     context incSymbolic(HOLE:KItem => reval(HOLE)) [result(RValue)]
endmodule

module LIBC-BOOTSTRAP
     imports LIBC-BOOTSTRAP-SYNTAX

     imports C-BUILTIN-SYNTAX
     imports C-COMMON-EXPR-EVAL-SYNTAX
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-SETTINGS-SYNTAX
     imports C-SYMLOC-SYNTAX
     imports C-TYPING-SYNTAX

     imports C-CONFIGURATION

     //TODO(liyili): might not need this if we have hybrid label
     rule varg(K:KResult) => vargResult(K)

     rule incSymbolic(tv(Loc:SymLoc, T:Type))
          => checkUse(tv(loc(linc(base(Loc)), offset(Loc), SetItem(fromType(t(.Set, no-type)))), T))
          [structural]

     // TODO(chathhorn): This is pretty dumb. Should handle var args nicer. In
     // particular, I don't understand why we should do the consecutive
     // addresses thing.
     //TODO(liyi): context prepareBuiltin(_, _ ListItem(HOLE:KItem => reval(HOLE)) _)
     //use HeatList temporally
     rule <k> handleBuiltin => Return(prepareBuiltin(F, toHeatList(makeVarArgs(P)))) ...</k>
          <curr-scope> blockScope(F:CId, _) </curr-scope>
          <curr-function-params> P:List </curr-function-params>
          <types>... F |-> T:Type ...</types>
          requires variadic in getParams(T)
          [structural]
     rule <k> handleBuiltin => Return(prepareBuiltin(F, toHeatList(P))) ...</k>
          <curr-scope> blockScope(F:CId, _) </curr-scope>
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
