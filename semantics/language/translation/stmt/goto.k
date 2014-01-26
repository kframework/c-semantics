module C-STMT-GOTO
     imports C-SYNTAX
     imports COMPAT-SYNTAX

     rule <k> Goto(Lbl:Id) => . ...</k>
          <currentFunction> F:Id </currentFunction>
          <currTU> Tu:String </currTU>
          <tu-id> Tu </tu-id>
          <goto-map>... 
               F |-> map((_ (Lbl |-> _))) 
          ...</goto-map>
          [structural]
          
endmodule
