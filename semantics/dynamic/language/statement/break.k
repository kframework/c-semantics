module C-STATEMENT-BREAK
     imports C-SYNTAX
     imports C-COMMON-STATEMENT-SYNTAX
     /*@ \fromStandard{\source[n1570]{\para{6.8.6.3}{2}}}{
     A break statement terminates execution of the smallest enclosing switch or
     iteration statement.
     }*/
     rule [break]:
          Break => popLoop
          [structural] 
endmodule
