module C-DECLARATIONS-SYNTAX
     // id, type, initializer
     syntax K ::= "figureInit-aux" "(" Id "," Type "," K ")" [strict(3)]
     // type, translation unit it was defined in, definition
     syntax K ::= "declarationObject" "(" Type "," K "," K ")"
          [latex(\terminal{declObj(}{#1}, {#2}, {#3}\terminal{)})]
     
     syntax K ::= "external"
     syntax K ::= "internal"
     syntax K ::= "noLinkage"
     
     syntax KResult ::= "initializer" "(" K ")"
     syntax K ::= "startInit" "(" Type "," Id "," K ")"
      
     syntax K ::= "doDeclare" "(" K "," K ")" [strict(1)] 
               
     syntax K ::= "processFunctionBody" "(" K ")"
endmodule

module C-DECLARATIONS
     imports C-DECLARATIONS-GENERAL 
     imports C-DECLARATIONS-INITIALIZATIONS 
     imports C-DECLARATIONS-ENUMS 
     imports C-DECLARATIONS-RESOLUTION 
endmodule
