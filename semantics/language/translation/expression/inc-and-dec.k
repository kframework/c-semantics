module C-EXPRESSION-INC-AND-DEC
     imports C-SYM-VAL-SYNTAX
     imports C-SYNTAX
     imports C-DYNAMIC-SYNTAX
     imports C-TYPING-SYNTAX

     rule [post-increment-start]:
          lval(_:SymLoc, T:Type) ++ => tv(symVal, T)
          [structural]
          
     rule [post-decrement-start]:
          lval(_:SymLoc, T:Type) -- => tv(symVal, T)
          [structural]
     
     context ++ (HOLE => peval(HOLE))
     rule ++ lval(_:SymLoc, T:Type) => tv(symVal, T)
     
     context -- (HOLE => peval(HOLE))
     rule -- lval(_:SymLoc, T:Type) => tv(symVal, T)

endmodule
