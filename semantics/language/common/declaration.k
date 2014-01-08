require "declaration/enum.k"
require "declaration/general.k"
require "declaration/initialization.k"
require "declaration/zero.k"

module C-DECLARATION-SYNTAX
     syntax Value ::= "functionObject" "(" Id "," Type "," K ")"

     // Used for builtins.
     syntax Value ::= "functionPrototype" "(" Id "," Type ")"

     syntax K ::= "initialize" "(" Id "," Type "," K ")"
          
     // id, type, initializer
     syntax K ::= "figureInit" "(" Id "," K "," K ")" [strict(2)] 

     syntax K ::= "zero" "(" K ")"

     // these are also used by compound literals
     syntax KResult ::= "initValue" "(" Id "," Type "," K ")"
     syntax Type ::= innerType(Type) [function]
     syntax K ::= "addToEnv" "(" Id "," SymLoc ")"
     syntax K ::= "initFunction" "(" K "," K ")" [strict]
     syntax Id ::= "file-scope"

     // first map is for type, second map is for offset
     syntax K ::= "aggregateInfo" "(" KList "," Map "," Map ")"

     // type, translation unit it was defined in, definition
     syntax K ::= "declarationObject" "(" Type "," K "," K ")"
          [latex(\terminal{declObj(}{#1}, {#2}, {#3}\terminal{)})]

     syntax K ::= verifyDecl(K) [strict]
     syntax K ::= declareFunction(Id, Type, K)

     syntax K ::= "external"
     syntax K ::= "internal"
     syntax K ::= "noLinkage"
     
     syntax KResult ::= "initializer" "(" K ")"
endmodule

module C-DECLARATION
     imports C-DECLARATION-ENUM
     imports C-DECLARATION-GENERAL
     imports C-DECLARATION-INITIALIZATION
     imports C-DECLARATION-ZERO
endmodule
