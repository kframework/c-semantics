// vim: set ts=2 sw=2:
module CIL-LIB
  imports CIL-SYNTAX
  imports CIL-COMMON
  imports CIL-COMMON-TYPED-VALUE

/*
 * *** stdlib.h ***
 */

  // Exit.
  rule 
    (<frame>... <k> 
      nclv(_, ExtFun("exit"))(V:TypedValue)
    ...</k> ...</frame>
    => <result-value> mival(V) </result-value>)
    <phase> _ => terminated </phase>
    [computational]

  // Abort.
  rule 
    (<frame> <k> 
      nclv(T:Type, ExtFun("abort"))( .Exps ) ~> K:K 
    </k> Cells:Bag </frame> 
    => <frame> Cells </frame>)
    (. => <result-value> 134 </result-value>)
    (. => <final-computation> 
      nclv(T, ExtFun("abort"))( .Exps ) ~> K 
    </final-computation>)
    (. => <error-cell> "Aborted." </error-cell>)
    <phase> _ => terminated </phase>
    [computational]

  /*
  * *** stdarg.h ***
  */

  rule 
    <k> nclv(_, ExtFun("__va_start"))( Ap:TypedValue ,  _) 
    => * Ap = tv(__builtin_va_list, va_list(VaArgs)) ;
    ~> tv(void, undef)
    ...</k>
    <frame-fun-va-args> VaArgs:TypedValues </frame-fun-va-args>
    [computational]

  rule nclv(_, ExtFun("__va_end"))( _ ) => tv(void, undef)
    [computational]

  rule nclv(_, ExtFun("__va_copy"))( DstAp:TypedValue ,  SrcAp:TypedValue ) 
    => *DstAp = SrcAp ;
    ~> tv(void, undef)
    [computational]

  rule nclv(_, ExtFun("__va_arg"))( Ap:TypedValue )
    => vaArgAux(Ap, *Ap)
    [computational]

  syntax Exp ::= vaArgAux(Exp, Exp) [strict]

  rule vaArgAux(Ap:TypedValue, 
      tv(__builtin_va_list, va_list(TV:TypedValue, TVs:TypedValues)))
    => *Ap = tv(__builtin_va_list, va_list(TVs)) ;
    ~> tv(normType(void*), va_list(TV))
    [computational]

endmodule
