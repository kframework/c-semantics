module LIBC-BOOTSTRAP-SYNTAX
     imports C-SYNTAX

     syntax KItem ::= varg(K) [strict]
     context varg(HOLE:KItem => reval(HOLE)) [result(RValue)]
     //TODO(liyili): might not need this if we have hybrid label
     syntax RValue ::= vargResult(K)
     syntax KItem ::= incSymbolic(K)
     context incSymbolic(HOLE:KItem => reval(HOLE)) [result(RValue)]

     syntax KItem ::= builtin(String) [klabel(builtin0)]
                    | builtin(String, RValue) [klabel(builtin1)]
                    | builtin(String, RValue, RValue) [klabel(builtin2)]
                    | builtin(String, RValue, RValue, RValue) [klabel(builtin3)]
                    | builtin(String, RValue, RValue, RValue, RValue) [klabel(builtin4)]
                    | builtin(String, RValue, RValue, RValue, RValue, RValue) [klabel(builtin5)]
                    | builtin(String, RValue, RValue, RValue, RValue, RValue, RValue) [klabel(builtin6)]
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

     rule varg(K:RValue) => vargResult(K)

     // Need a checkUse everywhere we create an rvalue (somehow based on
     // memory) without going through lvalue conversion (i.e., reval()).
     rule incSymbolic(tv(Loc:SymLoc, T:Type))
          => checkUse(tv(loc(linc(base(Loc)), offset(Loc), SetItem(fromType(t(.Set, no-type)))), T))
          [structural]

     // TODO(chathhorn): This is pretty dumb. Should handle var args nicer. In
     // particular, I don't understand why we should do the consecutive
     // addresses thing.
     syntax KItem ::= prepareBuiltin(CId, HeatList) [strict(2)]
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

     rule makeVarArgs(L:List) => makeVarArgsAux(L)
          requires vararg(0) in L
     rule makeVarArgs(L:List ListItem(X:CId))
          => L ListItem(X) ListItem(varg(incSymbolic(&(X))))
          requires notBool vararg(0) in (L ListItem(X))

     rule makeVarArgsAux(L:List ListItem(X:CId) ListItem(vararg(0)))
          => L ListItem(X) ListItem(varg(incSymbolic(&(X))))
     rule makeVarArgsAux(L:List ListItem(X:CId))
          => makeVarArgsAux(L)
          requires X =/=K vararg(0)

     rule prepareBuiltin(Identifier(F:String), .HeatList)
          => builtin(F)
          [structural]
     rule prepareBuiltin(Identifier(F:String),
               hrItem(A1:RValue))
          => builtin(F, A1)
          [structural]
     rule prepareBuiltin(Identifier(F:String),
               hrItem(A1:RValue) hs:: hrItem(A2:RValue))
          => builtin(F, A1, A2)
          [structural]
     rule prepareBuiltin(Identifier(F:String),
               hrItem(A1:RValue) hs:: hrItem(A2:RValue) hs:: hrItem(A3:RValue))
          => builtin(F, A1, A2, A3)
          [structural]
     rule prepareBuiltin(Identifier(F:String),
               hrItem(A1:RValue) hs:: hrItem(A2:RValue) hs:: hrItem(A3:RValue) hs:: hrItem(A4:RValue))
          => builtin(F, A1, A2, A3, A4)
          [structural]
     rule prepareBuiltin(Identifier(F:String),
               hrItem(A1:RValue) hs:: hrItem(A2:RValue) hs:: hrItem(A3:RValue) hs:: hrItem(A4:RValue) hs:: hrItem(A5:RValue))
          => builtin(F, A1, A2, A3, A4, A5)
          [structural]
     rule prepareBuiltin(Identifier(F:String),
               hrItem(A1:RValue) hs:: hrItem(A2:RValue) hs:: hrItem(A3:RValue)
               hs:: hrItem(A4:RValue) hs:: hrItem(A5:RValue) hs:: hrItem(A6:RValue))
          => builtin(F, A1, A2, A3, A4, A5, A6)
          [structural]
endmodule
