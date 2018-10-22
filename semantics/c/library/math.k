module LIBC-MATH
     imports C-CONVERSION-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports FLOAT
     imports LIBC-BUILTIN-SYNTAX

     rule [sqrt]:
          builtin("sqrt", tv(F:Float, ut(_, double)))
          => floatArithInterpret(ut(.Set, double), sqrtFloat(F))
          [structural]

     rule [log]:
          builtin("log", tv(F:Float, ut(_, double)))
          => floatArithInterpret(ut(.Set, double), logFloat(F))
          [structural]

     rule [exp]:
          builtin("exp", tv(F:Float, ut(_, double)))
          => floatArithInterpret(ut(.Set, double), expFloat(F))
          [structural]

     rule [atan]:
          builtin("atan", tv(F:Float, ut(_, double)))
          => floatArithInterpret(ut(.Set, double), atanFloat(F))
          [structural]

     rule [asin]:
          builtin("asin", tv(F:Float, ut(_, double)))
          => floatArithInterpret(ut(.Set, double), asinFloat(F))
          [structural]

     rule [atan2]:
          builtin("atan2", tv(F:Float, ut(_, double)), tv(F':Float, ut(_, double)))
          => floatArithInterpret(ut(.Set, double), atan2Float(F, F'))
          [structural]

     rule [tan]:
          builtin("tan", tv(F:Float, ut(_, double)))
          => floatArithInterpret(ut(.Set, double), tanFloat(F))
          [structural]

     rule [floor]:
          builtin("floor", tv(F:Float, ut(_, double)))
          => floatArithInterpret(ut(.Set, double), floorFloat(F))
          [structural]

     rule [cos]:
          builtin("cos", tv(F:Float, ut(_, double)))
          => floatArithInterpret(ut(.Set, double), cosFloat(F))
          [structural]

     rule [fmod]:
          builtin("fmod", tv(F:Float, ut(_, double)), tv(F':Float, ut(_, double)))
          => floatArithInterpret(ut(.Set, double), F %Float F')
          [structural]

     rule [sin]:
          builtin("sin", tv(F:Float, ut(_, double)))
          => floatArithInterpret(ut(.Set, double), sinFloat(F))
          [structural]

endmodule

