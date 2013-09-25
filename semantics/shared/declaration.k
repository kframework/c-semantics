require "declaration/binding.k"
require "declaration/enum.k"
require "declaration/general.k"
require "declaration/initialization.k"
require "declaration/resolution.k"
require "declaration/zero.k"

module C-DECLARATION-SYNTAX
     syntax K ::= "initialize" "(" Id "," Type "," K ")"
     syntax K ::= "zero" "(" K ")"
          
     // id, type, initializer
     syntax K ::= "figureInit" "(" Id "," K "," K ")" [strict(2)] 

     // these are also used by compound literals
     syntax KResult ::= "initValue" "(" Id "," Type "," K ")"
     syntax K ::= "readFunction" "(" SymLoc ")"
     syntax Type ::= innerType(Type) [function]
     syntax K ::= "bind" "(" KList "," KList ")"
     syntax K ::= "addToEnv" "(" Id "," SymLoc ")"
     syntax K ::= "initFunction" "(" K "," K ")" [strict]
     syntax Id ::= "file-scope"

     // first map is for type, second map is for offset
     syntax K ::= "aggregateInfo" "(" KList "," Map "," Map ")"
endmodule

module C-DECLARATION
     imports C-DECLARATION-BINDING
     imports C-DECLARATION-ENUM
     imports C-DECLARATION-GENERAL
     imports C-DECLARATION-INITIALIZATION
     imports C-DECLARATION-RESOLUTION
     imports C-DECLARATION-ZERO
endmodule
