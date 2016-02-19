module LIBC-MATH
     imports LIBC-BOOTSTRAP-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports COMPAT-SYNTAX

     rule [sqrt]:
          builtin("sqrt", tv(F:Float, t(_, double)))
          => arithInterpret(t(.Set, double), sqrtFloat(F:Float))
          [structural]

     rule [log]:
          builtin("log", tv(F:Float, t(_, double)))
          => arithInterpret(t(.Set, double), logFloat(F:Float))
          [structural]

     rule [exp]:
          builtin("exp", tv(F:Float, t(_, double)))
          => arithInterpret(t(.Set, double), expFloat(F:Float))
          [structural]

     rule [atan]:
          builtin("atan", tv(F:Float, t(_, double)))
          => arithInterpret(t(.Set, double), atanFloat(F:Float))
          [structural]

     rule [asin]:
          builtin("asin", tv(F:Float, t(_, double)))
          => arithInterpret(t(.Set, double), asinFloat(F:Float))
          [structural]

     rule [atan2]:
          builtin("atan2", tv(F:Float, t(_, double)), tv(F':Float, t(_, double)))
          => arithInterpret(t(.Set, double), atan2Float(F:Float, F':Float))
          [structural]

     rule [tan]:
          builtin("tan", tv(F:Float, t(_, double)))
          => arithInterpret(t(.Set, double), tanFloat(F:Float))
          [structural]

     rule [floor]:
          builtin("floor", tv(F:Float, t(_, double)))
          => arithInterpret(t(.Set, double), floorFloat(F:Float))
          [structural]

     rule [cos]:
          builtin("cos", tv(F:Float, t(_, double)))
          => arithInterpret(t(.Set, double), cosFloat(F:Float))
          [structural]

     rule [fmod]:
          builtin("fmod", tv(F:Float, t(_, double)), tv(F':Float, t(_, double)))
          => arithInterpret(t(.Set, double), F:Float %Float F':Float)
          [structural]

     rule [sin]:
          builtin("sin", tv(F:Float, t(_, double)))
          => arithInterpret(t(.Set, double), sinFloat(F:Float))
          [structural]

endmodule

