module LIBC-BOOTSTRAP-SYNTAX
     syntax K ::= varg(K) [strict(all(context('reval), result(RValue)))]
     syntax RValue ::= "varg'" "(" K ")"
     syntax K ::= prepareBuiltin(CId, List) 
     syntax K ::= incSymbolic(K) [strict(all(context('reval), result(RValue)))]
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

     rule varg(V:KResult) => varg'(V)
          [structural]

     rule incSymbolic(tv(Loc:SymLoc, T:Type))
          => tv(loc(linc(base(Loc)), offset(Loc)), T)
          [structural]

     // TODO(chathhorn): This is pretty dumb. Should handle var args nicer. In
     // particular, I don't understand why we should do the consecutive
     // addresses thing.
     context prepareBuiltin(_, _ ListItem(HOLE => reval'(HOLE)) _)
     rule <k> handleBuiltin => Return(prepareBuiltin(F, makeVarArgs(P))) ...</k>
          <curr-function> F:CId </curr-function>
          <curr-function-params> P:List </curr-function-params>
          <types>... F |-> T:Type ...</types>
          when variadic in getParams(T)
          [structural]
     rule <k> handleBuiltin => Return(prepareBuiltin(F, P)) ...</k>
          <curr-function> F:CId </curr-function>
          <curr-function-params> P:List </curr-function-params>
          <types>... F |-> T:Type ...</types>
          when notBool variadic in getParams(T)
          [structural]

     syntax List ::= makeVarArgs(List) [function]
     rule makeVarArgs(L:List ListItem(X:CId) ListItem(vararg(0)) _)
          => L ListItem(X) ListItem(varg(incSymbolic(&(X))))
     rule makeVarArgs(L:List ListItem(X:CId))
          => L ListItem(X) ListItem(varg(incSymbolic(&(X))))
          when notBool vararg(0) in (L ListItem(X))
endmodule
