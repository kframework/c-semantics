module C-STATEMENT-GOTO
     imports C-SYNTAX
     imports COMPAT-SYNTAX

     rule <k> Goto(Lbl:K) => . </k>
          <currentFunction> F:Id </currentFunction>
          <currTU> Tu:K </currTU>
          <gotoMap>... 
               kpair(Tu, F) |-> map((_ (Lbl |-> _))) 
          ...</gotoMap>
          [structural]
          
endmodule
