module C-EXPR-INC-AND-DEC
     imports C-SYMBOLIC-VALUE-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     rule lval(_:SymLoc, T:Type) ++ => tv(symVal, stripQualifiers(T))
          [structural]
          
     rule lval(_:SymLoc, T:Type) -- => tv(symVal, stripQualifiers(T))
          [structural]
     
     context ++ (HOLE => peval(HOLE))
     rule ++ lval(_:SymLoc, T:Type) => tv(symVal, stripQualifiers(T))
          [structural]
     
     context -- (HOLE => peval(HOLE))
     rule -- lval(_:SymLoc, T:Type) => tv(symVal, stripQualifiers(T))
          [structural]

endmodule
