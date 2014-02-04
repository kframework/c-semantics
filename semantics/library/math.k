module LIBC-MATH
     imports LIBC-BOOTSTRAP-SYNTAX

     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX
     imports COMPAT-SYNTAX

     rule [sqrt]:
          prepareBuiltin(Identifier("sqrt"), 
               ListItem(tv(F:Float, t(_, double))))
          => tv(sqrtFloat(F:Float), t(.Set, double))
          [structural]
  
     rule [log]:
          prepareBuiltin(Identifier("log"), 
               ListItem(tv(F:Float, t(_, double))))
          => tv(logFloat(F:Float), t(.Set, double))
          [structural]
  
     rule [exp]:
          prepareBuiltin(Identifier("exp"), 
               ListItem(tv(F:Float, t(_, double))))
          => tv(expFloat(F:Float), t(.Set, double))
          [structural]
  
     rule [atan]:
          prepareBuiltin(Identifier("atan"),
               ListItem(tv(F:Float, t(_, double))))
          => tv(atanFloat(F:Float), t(.Set, double))
          [structural]
  
     rule [asin]:
          prepareBuiltin(Identifier("asin"), 
               ListItem(tv(F:Float, t(_, double))))
          => tv(asinFloat(F:Float), t(.Set, double))
          [structural]
  
     rule [atan2]:
          prepareBuiltin(Identifier("atan2"), 
               ListItem(tv(F:Float, t(_, double)))
               ListItem(tv(F':Float, t(_, double))))
          => tv(atan2Float(F:Float, F':Float), t(.Set, double))
          [structural]
  
     rule [tan]:
          prepareBuiltin(Identifier("tan"),
               ListItem(tv(F:Float, t(_, double))))
          => tv(tanFloat(F:Float), t(.Set, double))
          [structural]
  
     rule [floor]:
          prepareBuiltin(Identifier("floor"),
               ListItem(tv(F:Float, t(_, double))))
          => tv(floorFloat(F:Float), t(.Set, double))
          [structural]
  
     rule [cos]:
          prepareBuiltin(Identifier("cos"),
               ListItem(tv(F:Float, t(_, double))))
          => tv(cosFloat(F:Float), t(.Set, double))
          [structural]

     rule [fmod]:
          prepareBuiltin(Identifier("fmod"), 
               ListItem(tv(F:Float, t(_, double)))
               ListItem(tv(F':Float, t(_, double))))
          => tv(F:Float %Float F':Float, t(.Set, double))
          [structural]

     rule [sin]:
          prepareBuiltin(Identifier("sin"),
               ListItem(tv(F:Float, t(_, double))))
          => tv(sinFloat(F:Float), t(.Set, double))
          [structural]

endmodule

