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

     rule [asinf]:
          prepareBuiltin(Identifier("asinf"),
               hrItem(tv(F:Float, t(_, float))))
          => tv(asinFloat(F:Float), t(.Set, float))
          [structural]

     rule [atan2]:
          prepareBuiltin(Identifier("atan2"),
               hrItem(tv(F:Float, t(_, double))) hs::
               hrItem(tv(F':Float, t(_, double))))
          => tv(atan2Float(F:Float, F':Float), t(.Set, double))
          [structural]

     rule [atan2f]:
          prepareBuiltin(Identifier("atan2f"),
               hrItem(tv(F:Float, t(_, float))) hs::
               hrItem(tv(F':Float, t(_, float))))
          => tv(atan2Float(F:Float, F':Float), t(.Set, float))
          [structural]

     rule [tan]:
          prepareBuiltin(Identifier("tan"),
               hrItem(tv(F:Float, t(_, double))))
          => tv(tanFloat(F:Float), t(.Set, double))
          [structural]

     rule [tanf]:
          prepareBuiltin(Identifier("tanf"),
               hrItem(tv(F:Float, t(_, float))))
          => tv(tanFloat(F:Float), t(.Set, float))
          [structural]

     rule [fabsf]:
          prepareBuiltin(Identifier("fabsf"),
               hrItem(tv(F:Float, t(_, float))))
          => tv(absFloat(F:Float), t(.Set, float))
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

     rule [cosf]:
          prepareBuiltin(Identifier("cosf"),
               hrItem(tv(F:Float, t(_, float))))
          => tv(cosFloat(F:Float), t(.Set, float))
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

     rule [sinf]:
          prepareBuiltin(Identifier("sinf"),
               hrItem(tv(F:Float, t(_, float))))
          => tv(sinFloat(F:Float), t(.Set, float))
          [structural]

endmodule

