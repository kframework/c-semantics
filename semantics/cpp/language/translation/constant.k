module CPP-TRANSLATION-CONSTANT-SYNTAX
     imports BASIC-K
     imports CPP-SORTS
     imports CPP-DYNAMIC-OTHER-SORTS
     imports COMPAT-SORTS

     syntax Expr ::= compileTimeEval(K)

     syntax Expr ::= revalCoreConstantExpression(Expr)

     syntax Expr ::= evalCoreConstantExpressionInContext(expr: Expr, ctx: K)

     syntax Expr ::= evalCoreConstantExpressionUntil(expr: Expr, condition: Predicate)


     syntax Expr ::= evalConstantExpression(Expr)

endmodule

module CPP-TRANSLATION-CONSTANT
     imports K-REFLECTION
     imports CPP-TRANSLATION-CONSTANT-SYNTAX
     imports CPP-SYNTAX
     imports CPP-DYNAMIC-SYNTAX
     imports C-CONFIGURATION

     rule <k> compileTimeEval(K::K) => K ~> compileTimeEvalDone ...</k>
          <compile-time-evaluation> false => true </compile-time-evaluation>
          <duration> _ => constexpr(TU) </duration>
          <curr-tr-tu> TU::String </curr-tr-tu>

     syntax KItem ::= "compileTimeEvalDone"

     rule <k> compileTimeEvalDone => .K ...</k>
     <compile-time-evaluation> true => false </compile-time-evaluation>

     rule <k> V:Val ~> compileTimeEvalDone => V ...</k>
     <compile-time-evaluation> true => false </compile-time-evaluation>
     requires isEvalVal(V)

     syntax KItem ::= evalCoreConstantExpressionHole(ctx: K)

     rule <k> evalCoreConstantExpressionInContext(E::Expr, #klabel(Ctx::KLabel)) => Ctx(E) ~> evalCoreConstantExpressionHole(#klabel(Ctx)) ...</k>
          <compile-time-evaluation> false => true </compile-time-evaluation>
          <duration> _ => constexpr(TU) </duration>
          <curr-tr-tu> TU::String </curr-tr-tu>
          requires notBool isEvalVal(E)

     rule <k> Lbl::KLabel(V:Val) ~> evalCoreConstantExpressionHole(#klabel(Ctx::KLabel)) => evalCoreConstantExpressionInContext(V, #klabel(Ctx)) ...</k>
          <compile-time-evaluation> true => false </compile-time-evaluation>
          requires isEvalVal(V) andBool #klabel(Lbl) ==K #klabel(Ctx)

     rule <k> evalCoreConstantExpressionUntil(E::Expr, Condition::Predicate) => E ~> evalCoreConstantExpressionHole(Condition) ...</k>
          <compile-time-evaluation> false => true </compile-time-evaluation>
          <duration> _ => constexpr(TU) </duration>
          <curr-tr-tu> TU::String </curr-tr-tu>
          requires notBool Condition(E)

     rule <k> E:Expr ~> evalCoreConstantExpressionHole(Condition:Predicate) => evalCoreConstantExpressionUntil(E, Condition) ...</k>
          <compile-time-evaluation> true => false </compile-time-evaluation>
          requires Condition(E)


     syntax KItem ::= "evalConstantExpressionHole"

     rule evalConstantExpression(E::Expr) => evalCoreConstantExpression(E) ~> evalConstantExpressionHole
          requires notBool isEvalVal(E)

     rule evalCoreConstantExpression(V:Val) ~> evalConstantExpressionHole => checkEvaluatedConstantExpression(V)
          requires isEvalVal(V)

     syntax KItem ::= checkEvaluatedConstantExpression(Val)

     rule checkEvaluatedConstantExpression(V::Val) => evalConstantExpression(V)

     rule revalCoreConstantExpression(E::Expr) => evalCoreConstantExpressionInContext(E, #klabel(`revalCpp`))

     syntax KItem ::= identityContext(Expr) [strict]

     syntax Expr ::= evalCoreConstantExpression(Expr)

     rule evalCoreConstantExpression(E::Expr) => evalCoreConstantExpressionUntil(E, isEvalVal)

endmodule

