module LIBC-MATH
     imports LIBC-BOOTSTRAP-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports COMPAT-SYNTAX

     //TODO(liyili2): HeatList might be temporal
     rule [sqrt]:
          prepareBuiltin(Identifier("sqrt"),
               hrItem(tv(F:Float, t(_, double))))
          => arithInterpret(t(.Set, double), sqrtFloat(F:Float))
          [structural]

     rule [log]:
          prepareBuiltin(Identifier("log"),
               hrItem(tv(F:Float, t(_, double))))
          => arithInterpret(t(.Set, double), logFloat(F:Float))
          [structural]

     rule [exp]:
          prepareBuiltin(Identifier("exp"),
               hrItem(tv(F:Float, t(_, double))))
          => arithInterpret(t(.Set, double), expFloat(F:Float))
          [structural]

     rule [atan]:
          prepareBuiltin(Identifier("atan"),
               hrItem(tv(F:Float, t(_, double))))
          => arithInterpret(t(.Set, double), atanFloat(F:Float))
          [structural]

     rule [asin]:
          prepareBuiltin(Identifier("asin"),
               hrItem(tv(F:Float, t(_, double))))
          => arithInterpret(t(.Set, double), asinFloat(F:Float))
          [structural]

     rule [atan2]:
          prepareBuiltin(Identifier("atan2"),
               hrItem(tv(F:Float, t(_, double))) hs::
               hrItem(tv(F':Float, t(_, double))))
          => arithInterpret(t(.Set, double), atan2Float(F:Float, F':Float))
          [structural]

     rule [tan]:
          prepareBuiltin(Identifier("tan"),
               hrItem(tv(F:Float, t(_, double))))
          => arithInterpret(t(.Set, double), tanFloat(F:Float))
          [structural]

     rule [floor]:
          prepareBuiltin(Identifier("floor"),
               hrItem(tv(F:Float, t(_, double))))
          => arithInterpret(t(.Set, double), floorFloat(F:Float))
          [structural]

     rule [cos]:
          prepareBuiltin(Identifier("cos"),
               hrItem(tv(F:Float, t(_, double))))
          => arithInterpret(t(.Set, double), cosFloat(F:Float))
          [structural]

     rule [fmod]:
          prepareBuiltin(Identifier("fmod"),
               hrItem(tv(F:Float, t(_, double))) hs::
               hrItem(tv(F':Float, t(_, double))))
          => arithInterpret(t(.Set, double), F:Float %Float F':Float)
          [structural]

     rule [sin]:
          prepareBuiltin(Identifier("sin"),
               hrItem(tv(F:Float, t(_, double))))
          => arithInterpret(t(.Set, double), sinFloat(F:Float))
          [structural]

endmodule

