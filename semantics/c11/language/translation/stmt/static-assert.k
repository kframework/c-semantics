module C-STMT-STATIC-ASSERT
     imports INT
     imports STRING
     imports C-ABSTRACT-SYNTAX
     imports C-ERROR-SYNTAX
     imports C-DYNAMIC-SYNTAX

     context StaticAssert((HOLE:KItem => reval(HOLE)), _) [result(RValue)]
     rule StaticAssert(tv(N:Int, _), _) => .K
          requires N =/=Int 0
     rule StaticAssert(te(_, _), _)
          => CV("SSA1",
               "Non-constant expression in static assertion.")
     rule StaticAssert(tv(0, _), StringLiteral(Msg:String))
          => CV("SSA2",
               "Static assertion failed: " +String Msg +String ".")


endmodule
