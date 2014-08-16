module LIBC-MATH
     imports LIBC-BOOTSTRAP-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports COMPAT-SYNTAX

     //TODO: HeatList might be temporal
     rule [sqrt]:
          prepareBuiltin(Identifier("sqrt"),
               hrItem(tv(F:Float, t(_, double))))
          => tv(sqrtFloat(F:Float), t(.Set, double))
          [structural]

     rule [log]:
          prepareBuiltin(Identifier("log"),
               hrItem(tv(F:Float, t(_, double))))
          => tv(logFloat(F:Float), t(.Set, double))
          [structural]

     rule [exp]:
          prepareBuiltin(Identifier("exp"),
               hrItem(tv(F:Float, t(_, double))))
          => tv(expFloat(F:Float), t(.Set, double))
          [structural]

     rule [atan]:
          prepareBuiltin(Identifier("atan"),
               hrItem(tv(F:Float, t(_, double))))
          => tv(atanFloat(F:Float), t(.Set, double))
          [structural]

     rule [asin]:
          prepareBuiltin(Identifier("asin"),
               hrItem(tv(F:Float, t(_, double))))
          => tv(asinFloat(F:Float), t(.Set, double))
          [structural]

     rule [atan2]:
          prepareBuiltin(Identifier("atan2"),
               hrItem(tv(F:Float, t(_, double))) hs::
               hrItem(tv(F':Float, t(_, double))))
          => tv(atan2Float(F:Float, F':Float), t(.Set, double))
          [structural]

     rule [tan]:
          prepareBuiltin(Identifier("tan"),
               hrItem(tv(F:Float, t(_, double))))
          => tv(tanFloat(F:Float), t(.Set, double))
          [structural]

     rule [floor]:
          prepareBuiltin(Identifier("floor"),
               hrItem(tv(F:Float, t(_, double))))
          => tv(floorFloat(F:Float), t(.Set, double))
          [structural]

     rule [cos]:
          prepareBuiltin(Identifier("cos"),
               hrItem(tv(F:Float, t(_, double))))
          => tv(cosFloat(F:Float), t(.Set, double))
          [structural]

     rule [fmod]:
          prepareBuiltin(Identifier("fmod"),
               hrItem(tv(F:Float, t(_, double))) hs::
               hrItem(tv(F':Float, t(_, double))))
          => tv(F:Float %Float F':Float, t(.Set, double))
          [structural]

     rule [sin]:
          prepareBuiltin(Identifier("sin"),
               hrItem(tv(F:Float, t(_, double))))
          => tv(sinFloat(F:Float), t(.Set, double))
          [structural]

endmodule

