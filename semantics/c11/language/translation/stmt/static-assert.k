module C-STMT-STATIC-ASSERT
     imports C-ABSTRACT-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-LITERAL-SYNTAX
     imports C-SYNTAX
     imports COMPAT-SYNTAX

     context StaticAssert((HOLE:KItem => reval(HOLE)), _) [result(RValue)]
     rule StaticAssert(tv(N:Int, _), _) => .K
          requires N =/=Int 0
     rule StaticAssert(te(_, _), _)
          => CV("SSA1",
               "Non-constant expression in static assertion.",
               "6.7.10:2")
     rule StaticAssert(tv(0, _), stringLiteral(Msg:String))
          => CV("SSA2",
               "Static assertion failed: " +String Msg +String ".",
               "6.7.10:2")


endmodule
