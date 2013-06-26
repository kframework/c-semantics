module LIBC-MATH
     imports COMMON-SEMANTIC-SYNTAX
     imports C-SETTINGS
     imports C-COMPAT-SYNTAX
     imports C-HELPERS
     imports URIS
     imports C-CONFIGURATION

     imports LIBC-SYNTAX
     rule [sqrt]:
          prepareBuiltin((Identifier("sqrt")), tv(F:Float, t(_, double)))
          => tv(sqrtFloat(F:Float), t(.Set, double))
          [structural]
  
     rule [log]:
          prepareBuiltin((Identifier("log")), tv(F:Float, t(_, double)))
          => tv(logFloat(F:Float), t(.Set, double))
          [structural]
  
     rule [exp]:
          prepareBuiltin((Identifier("exp")), tv(F:Float, t(_, double)))
          => tv(expFloat(F:Float), t(.Set, double))
          [structural]
  
     rule [atan]:
          prepareBuiltin((Identifier("atan")), tv(F:Float, t(_, double)))
          => tv(atanFloat(F:Float), t(.Set, double))
          [structural]
  
     rule [asin]:
          prepareBuiltin((Identifier("asin")), tv(F:Float, t(_, double)))
          => tv(asinFloat(F:Float), t(.Set, double))
          [structural]
  
     rule [atan2]:
          prepareBuiltin((Identifier("atan2")), (tv(F:Float, t(_, double)),, 
               tv(F':Float, t(_, double))))
          => tv(atan2Float(F:Float, F':Float), t(.Set, double))
          [structural]
  
     rule [tan]:
          prepareBuiltin((Identifier("tan")), tv(F:Float, t(_, double)))
          => tv(tanFloat(F:Float), t(.Set, double))
          [structural]
  
     rule [floor]:
          prepareBuiltin((Identifier("floor")), tv(F:Float, t(_, double)))
          => tv(floorFloat(F:Float), t(.Set, double))
          [structural]
  
     rule [cos]:
          prepareBuiltin((Identifier("cos")), tv(F:Float, t(_, double)))
          => tv(cosFloat(F:Float), t(.Set, double))
          [structural]

     rule [fmod]:
          prepareBuiltin((Identifier("fmod")), (tv(F:Float, t(_, double)),, 
               tv(F':Float, t(_, double))))
          => tv(F:Float %Float F':Float, t(.Set, double))
          [structural]

     rule [sin]:
          prepareBuiltin((Identifier("sin")), tv(F:Float, t(_, double)))
          => tv(sinFloat(F:Float), t(.Set, double))
          [structural]

endmodule

